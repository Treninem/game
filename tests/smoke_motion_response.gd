extends SceneTree

class NoResponse extends RefCounted:
    var last_cost_usec := 0
    func apply(_visual: Node3D, _skeleton: Skeleton3D, _delta: float) -> void:
        pass

var actors: Array[CharacterBody3D] = []
var latest: Array[Dictionary] = []
var probes := []
var capture_requested := false
var observations := []
var camera: Camera3D
var world: Node3D
var native := false
var walked := 0.0
var resume_pending := false
var resume_delta := 0.0
var response_costs := []
var gpu: RefCounted
var gpu_boots: RefCounted
var boot_probes := []
var gpu_errors := []
var measure_gpu := true

func _initialize() -> void:call_deferred("_run")

func _arm_triangles(probe: RefCounted, skeleton: Skeleton3D, arms: bool) -> PackedInt32Array:
    var selected := []
    var result := PackedInt32Array()
    for row: Array in probe.weights:
        var weight := 0.0
        for influence: Array in row:
            var name: String = skeleton.get_bone_name(probe.bindings[influence[0]][0])
            if "ForeArm" in name or "Hand" in name:weight += float(influence[1])
        selected.append(weight > 0.45 if arms else weight < 0.01)
    for i in range(0, probe.complete.size(), 3):
        if selected[probe.complete[i]] and selected[probe.complete[i+1]] and selected[probe.complete[i+2]]:
            for j in range(3):result.append(probe.complete[i+j])
    return result

func _watch(index: int) -> void:
    var actor := actors[index]
    var visual := actor.get_node("Avatar") as Node3D
    var modifier: Node = visual.get("grip_modifier")
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var sole := preload("res://tests/humanoid_skin_probe.gd").new()
    var pants := preload("res://tests/humanoid_layer_intersection_probe.gd").new()
    pants.setup(visual, skeleton)
    pants.outer.complete = _arm_triangles(pants.outer, skeleton, true)
    var torso := preload("res://tests/humanoid_layer_intersection_probe.gd").new()
    torso.setup(visual, skeleton, "VikingTunic")
    torso.inner.complete = _arm_triangles(torso.inner, skeleton, false)
    torso.outer = pants.outer
    probes.append([pants, torso])
    var boot_probe := preload("res://tests/humanoid_clothed_skin_probe.gd").new()
    boot_probe.cache(visual,skeleton,"Boots")
    boot_probes.append(boot_probe)
    modifier.modification_processed.connect(func():
        var base := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Spine1")).origin)
        var neck := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Neck")).origin)
        var up := (neck - base).normalized()
        var forward := -visual.global_basis.z.normalized()
        latest[index] = {"forward":up.dot(forward), "side":up.dot(visual.global_basis.x.normalized()), "grounded":actor.is_on_floor(), "clip":visual.get("animation_player").assigned_animation}
        if index == 1:
            var response: RefCounted = modifier.get("motion_response")
            latest[index].balance = {"pitch":response.get("pitch"),"acceleration":str(response.get("acceleration")),"velocity":str(actor.get_real_velocity()),"delta":response.get("last_delta"),"last_physics_frame":response.get("last_physics_frame"),"current_physics_frame":Engine.get_physics_frames(),"guard":actor.get("ground_guard_active")}
            response_costs.append(int(modifier.get("motion_response").get("last_cost_usec")))
            if resume_pending:
                resume_delta = float(latest[1].forward) - float(latest[0].forward)
                resume_pending = false
        if capture_requested:
            var points: Dictionary = sole.points(visual, skeleton)
            var low := INF
            for side: String in ["Left", "Right"]:
                for point: Vector3 in points[side]:low = minf(low, point.y)
            latest[index].sole_gap = low
            pants.snapshot(skeleton)
            torso.inner.snapshot(skeleton)
            torso.snapshots += 1
            boot_probe.snapshot(skeleton)
            if index == 1 and native and measure_gpu and gpu != null:
                # Physics and modifiers have now produced this frame's actual
                # pose. Match the proxy transform/morphs before GPU rendering.
                gpu.sync_source()
                gpu_boots.sync_source()
    )

func _frames(count: int) -> void:
    for i in range(count):
        var position := actors[1].global_position
        await physics_frame
        walked += Vector2(actors[1].global_position.x-position.x, actors[1].global_position.z-position.z).length()
        var center := (actors[0].global_position + actors[1].global_position) * 0.5
        camera.global_position = center + Vector3(4.3, 2.0, -5.8)
        camera.look_at(center + Vector3.UP)

func _sample(label: String, check_ground := true) -> Dictionary:
    var measured := PackedVector3Array()
    var measured_boots := PackedVector3Array()
    var cloth: MeshInstance3D
    var boots: MeshInstance3D
    if native and measure_gpu:
        var visual := actors[1].get_node("Avatar") as Node3D
        cloth = visual.find_child("Clothing",true,false) as MeshInstance3D
        boots = visual.find_child("Boots",true,false) as MeshInstance3D
        if gpu == null:
            var surface := -1
            for index in range(cloth.mesh.get_surface_count()):
                if cloth.mesh.surface_get_material(index).resource_name == "VikingTunic":surface = index
            assert(surface>=0,"Missing actual tunic surface")
            gpu = preload("res://tests/gpu_skinned_vertex_probe.gd").new()
            gpu.setup(root,cloth,surface)
            await gpu.calibrate()
            assert(boots.mesh.get_surface_count()==1,"Boot probe must include the entire shoe mesh")
            gpu_boots=preload("res://tests/gpu_skinned_vertex_probe.gd").new()
            gpu_boots.setup(root,boots,0)
            await gpu_boots.calibrate()
    capture_requested = true
    if native and measure_gpu:
        gpu.begin_capture()
        gpu_boots.begin_capture()
        await process_frame
        await RenderingServer.frame_post_draw
        measured = gpu.finish_capture()
        measured_boots = gpu_boots.finish_capture()
    elif native:
        await RenderingServer.frame_post_draw
    else:
        await process_frame
        await process_frame
    capture_requested = false
    assert(latest[0].has("sole_gap") and latest[1].has("sole_gap"), "Missing post-modifier skin observation")
    assert(actors[0].get_real_velocity().distance_to(actors[1].get_real_velocity()) < 0.002, "Comparison actors received different resolved motion")
    for index in range(2):
        if check_ground and bool(latest[index].grounded):
            assert(float(latest[index].sole_gap) >= -0.015 and float(latest[index].sole_gap) <= 0.020, "Final skinned sole lost physical support")
        var crossings := 0
        for probe in probes[index]:crossings += int(probe.scan().crossings_over_half_mm)
        latest[index].arm_crossings = crossings
        assert(crossings == 0, "Motion balance introduced final sleeve/torso/trouser intersections")
    var row := {"label":label, "control":latest[0].duplicate(true), "response":latest[1].duplicate(true)}
    observations.append(row)
    if native and measure_gpu:
        # Both actors keep simulating. CPU data and the packed GPU skin oracle
        # are sampled on the same completed frame, without an observer pause.
        var expected: PackedVector3Array = probes[1][0].outer.last_points
        assert(measured.size()==expected.size())
        var error := 0.0
        for index in range(measured.size()):error = maxf(error,cloth.to_global(measured[index]).distance_to(expected[index]))
        assert(error<0.0001,"GPU tunic vertices disagree with final inertial pose")
        var expected_boots: PackedVector3Array=boot_probes[1].last_points
        assert(expected_boots.size()==measured_boots.size())
        var boot_error:=0.0
        var boot_low:=INF
        for index in range(measured_boots.size()):
            var point:=boots.to_global(measured_boots[index])
            boot_error=maxf(boot_error,point.distance_to(expected_boots[index]))
            boot_low=minf(boot_low,point.y)
        assert(boot_error<0.0001,"GPU footwear disagrees with final CPU skin")
        if check_ground and bool(latest[1].grounded):assert(boot_low>=-0.015 and boot_low<=0.020,"GPU-skinned footwear lost physical support")
        gpu_errors.append({"label":label,"vertices":measured.size(),"maximum_error_m":error,"boot_vertices":measured_boots.size(),"maximum_boot_error_m":boot_error,"gpu_boot_min_y":boot_low})
        row.gpu_error_m = error
        row.gpu_boot_error_m = boot_error
        row.gpu_boot_min_y = boot_low
    if native:
        root.get_texture().get_image().save_png("user://motion-response-" + label + ".png")
    print("MOTION_RESPONSE_SAMPLE ", JSON.stringify(row))
    return row

func _run() -> void:
    create_timer(240).timeout.connect(func():push_error("Motion response fixture timed out");quit(1))
    native = DisplayServer.get_name() != "headless"
    if OS.get_environment("GODOT_SMOKE_GRAPHICAL") == "1":
        assert(native and not OS.get_cmdline_user_args().has("no_gpu"), "Required graphical gate needs live GPU skinning")
    measure_gpu = not OS.get_cmdline_user_args().has("no_gpu")
    root.size = Vector2i(1280, 720)
    world = Node3D.new()
    root.add_child(world)
    current_scene = world
    preload("res://tests/physical_human_fixture.gd").add_floor(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    light.light_energy = 1.5
    world.add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.28, 0.34, 0.42)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.85, 0.9, 1)
    environment.environment.ambient_light_energy = 0.65
    world.add_child(environment)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 4.6
    world.add_child(camera)
    for sex: String in ["male", "female"]:
        var state := root.get_node("GameState")
        state.call("reset_new_game")
        state.set("stamina", 1000.0) # Fixture sustains identical paired inputs; economy is tested separately.
        state.call("set_world_value", "player_appearance", preload("res://scripts/character_appearance.gd").normalized({"sex":sex,"height_cm":160.0 if sex=="male" else 195.0,"Build":-0.5 if sex=="male" else 0.5}))
        actors.clear();latest.clear();probes.clear();boot_probes.clear()
        var roots := []
        for index in range(2):
            var branch := Node3D.new();world.add_child(branch);roots.append(branch)
            actors.append(preload("res://tests/physical_human_fixture.gd").player(branch, Vector3(-1.6 if index==0 else 1.6, 0.08, 0)))
            latest.append({})
        actors[0].get_node("Avatar").get("grip_modifier").set("motion_response", NoResponse.new())
        for index in range(2):_watch(index)
        camera.make_current()
        await _frames(24)
        assert(actors[0].is_on_floor() and actors[1].is_on_floor(), "Comparison floor was not established before movement")
        var rest := await _sample(sex+"-rest")
        assert(absf(float(rest.response.forward)-float(rest.control.forward))<0.002, "Idle balance did not start neutral")
        Input.action_press("move_forward")
        await _frames(6)
        var start := await _sample(sex+"-start")
        assert(float(start.response.forward)-float(start.control.forward)>0.02, "Torso did not respond to actual acceleration")
        paused = true
        await create_timer(0.3,true).timeout
        resume_pending = true
        paused = false
        var resume_deadline := Time.get_ticks_msec()+5000
        while resume_pending and Time.get_ticks_msec()<resume_deadline:await process_frame
        assert(not resume_pending and resume_delta>0.002,"Resuming a pause snapped the visible balance to neutral")
        print("MOTION_RESUME_OK body=",sex," first_pose_delta=",resume_delta)
        await _frames(24)
        Input.action_press("sprint")
        await _frames(32)
        var run := await _sample(sex+"-run")
        assert(absf(float(run.response.forward)-float(run.control.forward))<0.006, "Transient balance over-bent the authored steady run")
        Input.action_press("move_left")
        await _frames(12)
        var turn := await _sample(sex+"-turn")
        assert(absf(float(turn.response.side)-float(turn.control.side))>0.005, "Turn has no lateral torso response")
        Input.action_release("move_left")
        Input.action_release("move_forward")
        Input.action_release("sprint")
        await _frames(8)
        var stop := await _sample(sex+"-brake")
        assert(float(stop.response.forward)-float(stop.control.forward)<-0.01, "Braking did not oppose forward lean")
        await _frames(70)
        var settled := await _sample(sex+"-settled")
        assert(absf(float(settled.response.forward)-float(settled.control.forward))<0.002, "Balance accumulated or failed to settle")
        var event := InputEventAction.new();event.action="jump";event.pressed=true
        Input.parse_input_event(event);Input.flush_buffered_events()
        await physics_frame
        event = InputEventAction.new();event.action="jump";Input.parse_input_event(event);Input.flush_buffered_events()
        await _frames(8)
        await _sample(sex+"-rise")
        var deadline := Time.get_ticks_msec()+5000
        while float(actors[1].get("landing_elapsed"))<=0.0 and Time.get_ticks_msec()<deadline:await _frames(1)
        assert(float(actors[1].get("landing_elapsed"))>0.0,"Physical jump never landed")
        await _frames(5)
        var land := await _sample(sex+"-landing")
        assert(float(land.response.forward)-float(land.control.forward)>0.015, "Landing only compressed the legs")
        await _frames(45)
        await _sample(sex+"-recovered")
        var inventory := root.get_node("InventorySystem")
        for item: String in ["short_bow","starter_axe"]:
            state.call("add_item",item,1)
            if item=="short_bow":state.call("add_item","arrow",8)
            assert(inventory.call("equip",item))
            await _frames(20)
            Input.action_press("move_forward")
            await _frames(4)
            var attack := InputEventAction.new();attack.action="attack";attack.pressed=true
            Input.parse_input_event(attack);Input.flush_buffered_events()
            await physics_frame
            attack=InputEventAction.new();attack.action="attack";Input.parse_input_event(attack);Input.flush_buffered_events()
            await _frames(2)
            await _sample(sex+"-"+item+"-prepare")
            await _frames(20)
            await _sample(sex+"-"+item+"-recover")
            Input.action_release("move_forward")
            await _frames(35)
            inventory.call("unequip","weapon")
        var magic := root.get_node("MagicSystem")
        for i in range(10):
            if magic.call("selected_spell_id")=="heal":break
            magic.call("select_next")
        assert(magic.call("selected_spell_id")=="heal")
        state.set("health",45.0);state.set("mana",100.0)
        Input.action_press("move_forward")
        await _frames(4)
        var cast := InputEventAction.new();cast.action="cast_magic";cast.pressed=true
        Input.parse_input_event(cast);Input.flush_buffered_events()
        await physics_frame
        cast=InputEventAction.new();cast.action="cast_magic";Input.parse_input_event(cast);Input.flush_buffered_events()
        await _frames(3)
        assert(float(actors[1].get("cast_elapsed"))>0.0,"Actual magic input did not reach the paired actors")
        await _sample(sex+"-cast")
        Input.action_release("move_forward")
        await _frames(40)
        for actor in actors:actor.set_meta("activity","sit")
        await _frames(30)
        var sitting := await _sample(sex+"-sitting",false)
        assert(absf(float(sitting.response.forward)-float(sitting.control.forward))<0.002,"Furniture pose inherited locomotion balance")
        if gpu != null:gpu.dispose();gpu=null;gpu_boots.dispose();gpu_boots=null
        for branch in roots:branch.queue_free()
        await process_frame
    assert(walked>10.0,"Fixture did not exercise actual physical movement")
    var file:=FileAccess.open("user://motion-response.json",FileAccess.WRITE)
    response_costs.sort()
    file.store_string(JSON.stringify({"samples":observations,"walked_m":walked,"player_position_writes_after_setup":0,"control":"same physical controller and rig with additive response replaced by no-op","native":native,"gpu":gpu_errors,"response_self_timing_usec":{"samples":response_costs.size(),"median":response_costs[response_costs.size()/2],"p95":response_costs[mini(response_costs.size()-1,int(response_costs.size()*.95))]}},"  "));file.close()
    print("MOTION_RESPONSE_OK samples=",observations.size()," bodies=2 paired_physics=true walked_m=",walked)
    if native and measure_gpu:
        assert(gpu_errors.size() == 30)
        print("MOTION_RESPONSE_GPU_OK poses=30 tunic_vertices=3776 boot_vertices=3530 live_physics=true")
    quit()
