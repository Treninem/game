extends SceneTree

# Uses the real controller, human assets, garment modifiers and physics input.
# Inclined QA geometry isolates gait/support defects; it is not a world/art claim.
var actor: CharacterBody3D
var visual: Node3D
var skeleton: Skeleton3D
var plane: StaticBody3D
var camera: Camera3D
var latest := {}
var rows := []
var requested := false
var native := false
var use_gpu := false
var boot_cpu: RefCounted
var cloth_cpu: RefCounted
var boot_gpu: RefCounted
var cloth_gpu: RefCounted
var walked := 0.0
var costs := []
var leg_lengths := {}

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int) -> void:
    for i in range(count):
        var before := actor.global_position
        await physics_frame
        walked += Vector2(actor.global_position.x-before.x, actor.global_position.z-before.z).length()
        _follow()

func _follow() -> void:
    camera.global_position = actor.global_position + Vector3(3, 2.1, -4.7)
    var normal := plane.global_basis.y.normalized()
    var center := plane.to_global(Vector3(0, 0.5, 0))
    var ground_y := center.y - (normal.x * (camera.global_position.x-center.x) + normal.z * (camera.global_position.z-center.z)) / normal.y
    camera.global_position.y = maxf(camera.global_position.y, ground_y+0.9)
    camera.look_at(actor.global_position + Vector3.UP * 1.0)
    camera.force_update_transform()

func _watch() -> void:
    boot_cpu = preload("res://tests/humanoid_clothed_skin_probe.gd").new()
    boot_cpu.cache(visual, skeleton, "Boots")
    cloth_cpu = preload("res://tests/humanoid_clothed_skin_probe.gd").new()
    cloth_cpu.cache(visual, skeleton, "Clothing", "VikingTunic")
    var sole := preload("res://tests/humanoid_skin_probe.gd").new()
    var modifier: Node = visual.get("grip_modifier")
    modifier.modification_processed.connect(func():
        costs.append(int(modifier.get("support").get("last_cost_usec")))
        if not requested:
            return
        var normal := plane.global_basis.y.normalized()
        var center := plane.to_global(Vector3(0, 0.5, 0))
        var points: Dictionary = sole.points(visual, skeleton)
        var gaps := {}
        for side: String in ["Left", "Right"]:
            var low := INF
            for point: Vector3 in points[side]:
                low = minf(low, (point-center).dot(normal) / normal.y)
            gaps[side] = low
            for pair: Array in [["UpLeg", "Leg"], ["Leg", "Foot"]]:
                var start := skeleton.get_bone_global_pose(skeleton.find_bone(side+pair[0])).origin
                var end := skeleton.get_bone_global_pose(skeleton.find_bone(side+pair[1])).origin
                var key: String = side+String(pair[0])
                var length := start.distance_to(end)
                if not leg_lengths.has(key):
                    leg_lengths[key] = length
                assert(absf(length-float(leg_lengths[key]))<0.0005, "Terrain support stretched an anatomical leg")
        latest = {"gaps":gaps, "grounded":actor.is_on_floor(), "clip":visual.get("animation_player").assigned_animation, "phase":visual.get("animation_player").current_animation_position, "frame":Engine.get_process_frames(), "position":str(actor.global_position), "contacts":modifier.get("support").get("contacts").duplicate(true), "landing_compression":modifier.get("support").get("landing_compression"), "velocity_y":actor.velocity.y, "landing_elapsed":actor.get("landing_elapsed")}
        if use_gpu:
            boot_cpu.snapshot(skeleton)
            cloth_cpu.snapshot(skeleton)
            boot_gpu.sync_source()
            cloth_gpu.sync_source()
    )

func _sample(label: String, airborne := false, phase_filter := "") -> void:
    requested = true
    var accepted := false
    var deadline := Time.get_ticks_msec()+15000
    for attempt in range(30):
        if use_gpu:
            boot_gpu.begin_capture()
            cloth_gpu.begin_capture()
        if native:
            await process_frame
            await RenderingServer.frame_post_draw
        else:
            # Observe the completed modifier directly. Waiting two process
            # frames can consume sixteen physics ticks and miss the landing.
            await visual.get("grip_modifier").modification_processed
        assert(not latest.is_empty(), "Missing actual final-modifier slope pose")
        assert(int(latest.frame)==Engine.get_process_frames(), "Slope snapshot and observer are different frames")
        var flying := not bool(latest.grounded)
        accepted = phase_filter.is_empty()
        if phase_filter=="rise":accepted=flying and float(latest.velocity_y)>0.5
        if phase_filter=="apex":accepted=flying and absf(float(latest.velocity_y))<1.5
        if phase_filter=="fall":accepted=flying and float(latest.velocity_y)<-0.5
        if phase_filter=="landing":accepted=bool(latest.grounded) and float(latest.landing_elapsed)>0 and float(latest.landing_compression)>0.001
        if accepted or Time.get_ticks_msec()>deadline:break
    requested = false
    assert(accepted, "Actual slope jump phase was missed: "+label+" "+JSON.stringify(latest))
    if airborne:
        assert(not bool(latest.grounded), "An airborne label captured a grounded pose")
    var row := latest.duplicate(true)
    row["label"] = label
    if not airborne:
        assert(bool(row.grounded), "Inclined physical floor was lost: "+label)
        assert(minf(float(row.gaps.Left),float(row.gaps.Right))<=0.025, "Neither final sole supports the body: "+label)
        for side: String in ["Left", "Right"]:
            assert(float(row.gaps[side])>=-0.015, "Final swing sole penetrates physical terrain: "+label+" "+JSON.stringify(row))
    if use_gpu:
        var measured: PackedVector3Array = boot_gpu.finish_capture()
        var cloth_measured: PackedVector3Array = cloth_gpu.finish_capture()
        assert(measured.size()==3530 and cloth_measured.size()==3776, "GPU terrain test lost complete boot/tunic coverage")
        var error := 0.0
        var low := INF
        var normal := plane.global_basis.y.normalized()
        var center := plane.to_global(Vector3(0, 0.5, 0))
        for i in range(measured.size()):
            var point: Vector3 = boot_cpu.body.to_global(measured[i])
            error = maxf(error, point.distance_to(boot_cpu.last_points[i]))
            low = minf(low, (point-center).dot(normal)/normal.y)
        var cloth_error := 0.0
        for i in range(cloth_measured.size()):
            cloth_error = maxf(cloth_error, cloth_cpu.body.to_global(cloth_measured[i]).distance_to(cloth_cpu.last_points[i]))
        assert(error<0.0001 and cloth_error<0.0001, "Final terrain pose and GPU garment/boot skin disagree")
        if not airborne:
            assert(low>=-0.015 and low<=0.025, "GPU sole lost inclined floor contact")
        row["gpu"] = {"boot_vertices":measured.size(), "tunic_vertices":cloth_measured.size(), "boot_error_m":error, "tunic_error_m":cloth_error, "minimum_gap_m":low}
    if native:
        assert(root.get_texture().get_image().save_png("user://slope-motion-"+label+".png")==OK)
    rows.append(row)
    print("SLOPE_MOTION_SAMPLE ", JSON.stringify(row))

func _press(action: String) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    await physics_frame
    event = InputEventAction.new()
    event.action = action
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _actions(label: String) -> void:
    await _frames(50)
    await _press("jump")
    await _sample(label+"-rise", true, "rise")
    await _sample(label+"-apex", true, "apex")
    await _sample(label+"-fall", true, "fall")
    await _sample(label+"-landing", false, "landing")
    await _frames(35)
    await _sample(label+"-recovered")
    var inventory := root.get_node("InventorySystem")
    var state := root.get_node("GameState")
    for item: String in ["short_bow", "starter_axe"]:
        state.call("add_item", item, 1)
        if item=="short_bow":
            state.call("add_item", "arrow", 8)
        assert(inventory.call("equip", item))
        await _frames(12)
        Input.action_press("move_forward")
        await _frames(5)
        await _press("attack")
        await _frames(2)
        await _sample(label+"-"+item+"-action")
        await _frames(22)
        await _sample(label+"-"+item+"-recovery")
        Input.action_release("move_forward")
        await _frames(45)
        inventory.call("unequip", "weapon")
    var magic := root.get_node("MagicSystem")
    for i in range(10):
        if magic.call("selected_spell_id")=="heal":break
        magic.call("select_next")
    assert(magic.call("selected_spell_id")=="heal")
    state.set("health", 45.0)
    state.set("mana", 100.0)
    await _press("cast_magic")
    await _frames(3)
    assert(float(actor.get("cast_elapsed"))>0, "Slope magic input failed")
    await _sample(label+"-cast")

func _run() -> void:
    create_timer(240).timeout.connect(func():push_error("SLOPE_MOTION timeout");quit(1))
    native = DisplayServer.get_name()!="headless"
    if OS.get_environment("GODOT_SMOKE_GRAPHICAL")=="1":
        assert(native, "Required slope gate needs a real renderer")
    root.size = Vector2i(1280,720)
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45,-30,0)
    light.light_energy = 1.5
    world.add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.28,0.34,0.42)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.85,0.9,1.0)
    environment.environment.ambient_light_energy = 0.65
    world.add_child(environment)
    camera = Camera3D.new()
    camera.fov = 38
    world.add_child(camera)
    plane = StaticBody3D.new()
    world.add_child(plane)
    var shape := BoxShape3D.new()
    shape.size = Vector3(80,1,80)
    var collider := CollisionShape3D.new()
    collider.shape = shape
    plane.add_child(collider)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = shape.size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22,0.3,0.23)
    material.roughness = 0.95
    mesh.material_override = material
    plane.add_child(mesh)
    var tilts := [Vector3.ZERO,Vector3(0,0,30),Vector3(25,0,0),Vector3(-25,0,-20)]
    for sex: String in ["male","female"]:
        var state := root.get_node("GameState")
        state.call("reset_new_game")
        state.set("stamina",1000.0)
        state.call("set_world_value","player_appearance",preload("res://scripts/character_appearance.gd").normalized({"sex":sex,"height_cm":160.0 if sex=="male" else 195.0,"Build":-0.5 if sex=="male" else 0.5}))
        for course in range(tilts.size()):
            plane.rotation_degrees = tilts[course]
            plane.position.y = -0.5 / plane.global_basis.y.y
            actor = preload("res://tests/physical_human_fixture.gd").player(world,Vector3(0,0.25,0))
            actor.set("walk_speed",1.8)
            visual = actor.get_node("Avatar")
            skeleton = visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
            latest.clear()
            leg_lengths.clear()
            use_gpu = native and course==3
            _watch()
            camera.make_current()
            await _frames(35)
            if use_gpu:
                boot_gpu = preload("res://tests/gpu_skinned_vertex_probe.gd").new()
                boot_gpu.setup(root,boot_cpu.body,0)
                await boot_gpu.calibrate()
                cloth_gpu = preload("res://tests/gpu_skinned_vertex_probe.gd").new()
                var surface := -1
                for i in range(cloth_cpu.body.mesh.get_surface_count()):
                    if cloth_cpu.body.mesh.surface_get_material(i).resource_name=="VikingTunic":surface=i
                assert(surface>=0)
                cloth_gpu.setup(root,cloth_cpu.body,surface)
                await cloth_gpu.calibrate()
            var label := sex+"-course"+str(course)
            for phase: String in ["idle","walk-start","walk-mid","walk-late","run-start","run-mid","stop"]:
                if phase=="walk-start":Input.action_press("move_forward")
                if phase=="run-start":Input.action_press("sprint")
                if phase=="stop":
                    Input.action_release("move_forward")
                    Input.action_release("sprint")
                await _frames(7)
                await _sample(label+"-"+phase)
            if course==3:
                await _actions(label)
            if use_gpu:
                boot_gpu.dispose()
                cloth_gpu.dispose()
                boot_gpu=null
                cloth_gpu=null
            actor.queue_free()
            await process_frame
    assert(rows.size()==76 and walked>15.0, "Slope scenario lost phase/movement coverage")
    costs.sort()
    var file := FileAccess.open("user://slope-motion.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"samples":rows,"walked_m":walked,"player_position_writes_after_setup":0,"native":native,"support_cost_usec":{"samples":costs.size(),"median":costs[costs.size()/2],"p95":costs[int(costs.size()*0.95)]}},"  "))
    file.close()
    print("SLOPE_MOTION_OK samples=",rows.size()," bodies=2 courses=4 walked_m=",walked," teleport_writes=0")
    if native:
        assert(rows.filter(func(row: Dictionary) -> bool:return row.has("gpu")).size()==34, "Missing native slope GPU phases")
        print("SLOPE_MOTION_GPU_OK poses=34 boots=3530 tunic=3776 live_physics=true")
    quit(0)
