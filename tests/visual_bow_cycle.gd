extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(90).timeout.connect(func(): push_error("BOW_VIEWS timeout"); quit(1))
    root.size = Vector2i(1280, 720)
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-35, -25, 0)
    world.add_child(sun)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.23, 0.27, 0.3)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color.WHITE
    env.environment.ambient_light_energy = 0.65
    world.add_child(env)
    var camera := Camera3D.new()
    camera.fov = 38
    world.add_child(camera)
    camera.make_current()
    var captures := 0
    for sex: String in ["male", "female"]:
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation", "Idle")
        actor.set_meta("preview_item", "short_bow")
        world.add_child(actor)
        var visual := load("res://scripts/humanoid_visual.gd").new() as Node3D
        visual.set("appearance_profile", {"sex": sex})
        actor.add_child(visual)
        visual.set_process(false)
        var animation: AnimationPlayer = visual.get("animation_player")
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        for clip: String in ["Bow_Attack_Draw", "Bow_Attack_Shoot"]:
            for time: float in ([0.15, 0.396, 0.65] if clip == "Bow_Attack_Draw" else [0.12, 0.32, 0.48]):
                animation.play(clip, 0)
                animation.seek(time, true)
                animation.pause()
                skeleton.advance(0)
                await process_frame
                for view: int in range(3):
                    camera.position = [Vector3(1.1, 1.5, -2.7), Vector3(2.7, 1.5, 0.1), Vector3(1.1, 1.5, 2.7)][view]
                    camera.look_at(Vector3(0, 1.35, 0))
                    await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png("user://bow-%s-%s-%03d-%d.png" % [sex, clip, roundi(time * 1000), view])
                    captures += 1
        actor.free()
    print("BOW_VIEWS_OK frames=", captures, " views=3 bodies=2")
    quit(0)
