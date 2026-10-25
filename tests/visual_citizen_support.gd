extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(150).timeout.connect(func(): push_error("CITIZEN_SUPPORT timeout"); quit(1))
    root.size = Vector2i(1280, 720)
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -30, 0)
    sun.light_energy = 1.5
    world.add_child(sun)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.23, 0.29, 0.34)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = 0.6
    world.add_child(environment)
    var floor_body := _box(Vector3(8, 1, 8), Color(0.25,0.29,0.24))
    floor_body.position = Vector3(60, -0.5, 0)
    world.add_child(floor_body)
    var step := _box(Vector3(1.2,0.22,4),Color(0.35,0.36,0.31))
    step.position = Vector3(60.6,0.11,0)
    world.add_child(step)
    var player: CharacterBody3D = load("res://scripts/settlement_npc.gd").new()
    player.name = "SupportCitizen"
    player.position = Vector3(60, .9, 0)
    world.add_child(player)
    player.set_physics_process(false)
    player.ground_ready = true
    var visual := player.get_node("Visual") as Node3D
    visual.set_process(false)
    var camera := Camera3D.new()
    camera.fov = 42
    world.add_child(camera)
    camera.make_current()
    var probe := preload("res://tests/humanoid_skin_probe.gd").new()
    var plane: RefCounted = load("res://tests/humanoid_support_cases.gd").new()
    var rows := []
    var errors: Array[String] = []
    var gpu_samples: Array = []
    for profile: Dictionary in [{"sex":"male","height_cm":160.0},{"sex":"male","height_cm":200.0},{"sex":"female","height_cm":160.0},{"sex":"female","height_cm":200.0}]:
        var sex: String = profile.sex
        visual.call("apply_appearance", profile)
        var animator: AnimationPlayer = visual.get("animation_player")
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var data := {"capture":false}
        skeleton.get_node("ClothingClearance").modification_processed.connect(func():
            if data.capture:
                data.capture=false
                data.points=probe.points(visual,skeleton)
        )
        for terrain: String in ["flat","cross_slope","ramp","step"]:
            floor_body.rotation = Vector3.ZERO
            if terrain=="cross_slope":floor_body.rotation.z=deg_to_rad(12.0)
            if terrain=="ramp":floor_body.rotation.x=deg_to_rad(20.0)
            step.collision_layer=1 if terrain=="step" else 0
            step.visible=terrain=="step"
            player.position=Vector3(60,0.9,0)
            for frame in range(18):
                await physics_frame
                player.velocity=Vector3.DOWN*5
                player.move_and_slide()
            assert(player.is_on_floor())
            player.velocity=Vector3.ZERO
            camera.position=player.position+Vector3(-2.7 if terrain=="step" else 2.7,1.3,-2.7)
            camera.look_at(player.position+Vector3.UP*0.95)
            for clip: String in ["Idle","Walk","Run","WorkStanding"]:
                for phase: float in [.25, .65]:
                    var before_body := player.transform
                    animator.play(clip,0.0)
                    animator.seek(animator.get_animation(clip).length*phase,true)
                    animator.pause()
                    for frame in range(5):
                        skeleton.advance(1.0/60.0)
                        await process_frame
                    data.erase("points")
                    data.capture=true
                    skeleton.advance(1.0/60.0)
                    await process_frame
                    await RenderingServer.frame_post_draw
                    var low:=INF
                    var points:Dictionary=data.get("points",{})
                    assert(not points.is_empty())
                    for side:String in ["Left","Right"]:
                        for point:Vector3 in points[side]:
                            low=minf(low,point.y-float(plane.call("_height",point,terrain)))
                    if low < -.015 or low > .020:
                        errors.append("%s/%s/%s/%s gap=%s" % [sex, profile.height_cm, terrain, clip, low])
                    var path:="user://npc-support-%s-%s-%s-%s.png"%[sex,profile.height_cm,terrain,clip]
                    if phase == .25 and clip in ["Idle", "WorkStanding"]:
                        root.get_texture().get_image().save_png(path)
                    var helper: Variant = skeleton.get_node("ClothingClearance").get("seated_support")
                    var cost := int(helper.get("last_cost_usec")) if helper != null else 0
                    rows.append({"sex":sex,"height_cm":profile.height_cm,"support_usec":cost,"phase":phase,"surface":terrain,"clip":clip,"skinned_sole_gap":low,"capture":path})
                    assert(player.transform.is_equal_approx(before_body), "Sole correction moved the physics body")
                    if clip == "Walk" and phase == .25 and profile.height_cm == 200.0 and terrain in ["ramp", "step"]:
                        var boots := visual.find_child("Boots", true, false) as MeshInstance3D
                        var gpu: RefCounted = load("res://tests/gpu_skinned_vertex_probe.gd").new()
                        gpu.setup(root, boots, 0)
                        await gpu.calibrate()
                        gpu.begin_capture()
                        await process_frame
                        await RenderingServer.frame_post_draw
                        var vertices: PackedVector3Array = gpu.finish_capture()
                        assert(vertices.size() == 3530, "Incomplete GPU boot capture")
                        var gpu_gap := INF
                        for vertex: Vector3 in vertices:
                            var point := boots.to_global(vertex)
                            gpu_gap = minf(gpu_gap, point.y-float(plane.call("_height",point,terrain)))
                        gpu_samples.append({"sex":sex,"terrain":terrain,"height_cm":profile.height_cm,"vertices":vertices.size(),"gap":gpu_gap,"cpu_gap":low})
                        if gpu_gap < -.015 or gpu_gap > .020 or absf(gpu_gap-low) > .006:
                            errors.append("GPU sole differs from the physical surface or independent CPU oracle: %s/%s/%s" % [sex,terrain,gpu_gap])
                        gpu.dispose()
    var file:=FileAccess.open("user://npc-support-surfaces.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"rows": rows,"gpu":gpu_samples,"errors":errors,"fixture_positions_assigned":true,"independent_all_boot_vertices":true}, "  "))
    file.close()
    print("CITIZEN_SUPPORT rows=",rows.size()," gpu=",gpu_samples.size()," failures=",errors.size())
    world.queue_free()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image()
    for error: String in errors: push_error(error)
    quit(1 if not errors.is_empty() else 0)

func _box(size: Vector3,color:Color)->StaticBody3D:
    var body:=StaticBody3D.new()
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new()
    shape.size=size
    collision.shape=shape
    body.add_child(collision)
    var mesh:=MeshInstance3D.new()
    var box:=BoxMesh.new()
    box.size=size
    mesh.mesh=box
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    mesh.material_override=material
    body.add_child(mesh)
    return body
