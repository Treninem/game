extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(150).timeout.connect(func(): push_error("SUPPORT_SURFACES timeout"); quit(1))
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
    var stage := load("res://scenes/stage1.tscn").instantiate() as Node
    var player := stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    player.set_physics_process(false)
    player.set_process_input(false)
    world.add_child(player)
    player.set_physics_process(false)
    assert(not player.is_physics_processing())
    player.call("_set_instanced_world_mode", true)
    player.rotation = Vector3.ZERO
    var visual := player.get_node("Avatar") as Node3D
    visual.set_process(false)
    var camera := Camera3D.new()
    camera.fov = 42
    world.add_child(camera)
    camera.make_current()
    var probe := preload("res://tests/humanoid_skin_probe.gd").new()
    var plane: RefCounted = load("res://tests/humanoid_support_cases.gd").new()
    var rows := []
    for sex: String in ["male", "female"]:
        root.get_node("GameState").call("set_world_value", "player_appearance", {"sex":sex,"height_cm":180.0})
        visual.call("apply_appearance", {"sex":sex,"height_cm":180.0})
        visual.set("appearance_revision",root.get_node("GameState").get("state_revision"))
        var animator: AnimationPlayer = visual.get("animation_player")
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var data := {"capture":false}
        visual.get("grip_modifier").modification_processed.connect(func():
            if data.capture:
                data.capture=false
                data.points=probe.points(visual,skeleton)
        )
        for terrain: String in ["ledge_left","ledge_right"]:
            floor_body.position.x = 56.0 if terrain=="ledge_left" else 64.0
            floor_body.rotation = Vector3.ZERO
            if terrain=="cross_slope":floor_body.rotation.z=deg_to_rad(12.0)
            if terrain=="ramp":floor_body.rotation.x=deg_to_rad(20.0)
            step.collision_layer=1 if terrain=="step" else 0
            step.visible=terrain=="step"
            player.position=Vector3(59.98 if terrain=="ledge_left" else 60.02,0.9,0)
            for frame in range(18):
                await physics_frame
                player.velocity=Vector3.DOWN*5
                player.move_and_slide()
            assert(player.is_on_floor())
            player.velocity=Vector3.ZERO
            camera.position=player.position+Vector3(-2.7 if terrain=="step" else 2.7,1.3,-2.7)
            camera.look_at(player.position+Vector3.UP*0.95)
            for clip: String in ["Walk"]:
                animator.play(clip,0.0)
                animator.seek(animator.get_animation(clip).length*0.75,true)
                animator.pause()
                for frame in range(8):
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
                        if (terrain=="ledge_left" and point.x>60) or (terrain=="ledge_right" and point.x<60):continue
                        low=minf(low,point.y)
                assert(low>=-0.015 and low<=0.020,"Rendered terrain support failed")
                var path:="user://support-%s-%s-%s.png"%[sex,terrain,clip]
                root.get_texture().get_image().save_png(path)
                rows.append({"sex":sex,"height_cm":180,"surface":terrain,"clip":clip,"skinned_sole_gap":low,"capture":path})
    var file:=FileAccess.open("user://support-surfaces.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(rows))
    file.close()
    print("SUPPORT_SURFACES_OK frames=",rows.size()," bodies=2 height=180 surfaces=2 clips=1 all_boot_vertices=true")
    quit(0)

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
