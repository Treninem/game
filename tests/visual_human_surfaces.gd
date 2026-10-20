extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(80).timeout.connect(func(): push_error("HUMAN_SURFACE_REVIEW timeout"); quit(1))
    root.size = Vector2i(1280, 720)
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -25, 0)
    light.light_energy = 1.2
    world.add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.22, 0.26, 0.3)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = 0.6
    world.add_child(environment)
    var camera := Camera3D.new()
    camera.fov = 38
    world.add_child(camera)
    camera.make_current()
    var count := 0
    for sex: String in ["male", "female"]:
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation", "Idle")
        world.add_child(actor)
        var visual := load("res://scripts/humanoid_visual.gd").new() as Node3D
        visual.set("appearance_profile", {"sex": sex})
        actor.add_child(visual)
        visual.set_process(false)
        var animation: AnimationPlayer = visual.get("animation_player")
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        for clip: String in ["Idle", "Walk", "Run", "Bow_Attack_Draw", "Axe_Chop"]:
            actor.set_meta("preview_item", "short_bow" if clip == "Bow_Attack_Draw" else ("starter_axe" if clip == "Axe_Chop" else ""))
            visual.call("_refresh_weapon")
            animation.play(clip, 0)
            animation.seek(animation.get_animation(clip).length * 0.4, true)
            animation.pause()
            skeleton.advance(0)
            await process_frame
            camera.position = Vector3(1.3, 1.35, -2.5)
            camera.look_at(Vector3(0, 1.25, 0))
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("user://surface-" + sex + "-" + clip + ".png")
            count += 1
            if clip == "Walk":
                var hand := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin)
                camera.position = hand + Vector3(0.24, 0.08, -0.5)
                camera.look_at(hand + Vector3.DOWN * 0.07)
                await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png("user://surface-" + sex + "-hand.png")
                count += 1
        actor.free()
    print("HUMAN_SURFACE_REVIEW_OK frames=", count)
    quit(0)
