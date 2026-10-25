extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(150).timeout.connect(func(): push_error("MOTION_PHASES timeout"); quit(1))
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
    var rows := []
    for sex: String in ["male", "female"]:
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation", "Idle")
        actor.set_meta("preview_item", "")
        world.add_child(actor)
        var visual := load("res://scripts/humanoid_visual.gd").new() as Node3D
        visual.set("appearance_profile", {"sex": sex})
        actor.add_child(visual)
        visual.set_process(false)
        var animation: AnimationPlayer = visual.get("animation_player")
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var final_points := {}
        visual.get("grip_modifier").modification_processed.connect(func():
            final_points.clear()
            for side: String in ["Left", "Right"]:
                for part: String in ["Arm", "ForeArm", "Hand", "UpLeg", "Leg", "Foot", "ToeBase"]:
                    var point := actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(side + part)).origin))
                    final_points[side + part] = [point.x, point.y, point.z]
        )
        for clip: String in ["Walk", "Run", "Airborne", "Axe_Chop", "Punch"]:
            actor.set_meta("preview_item", "starter_axe" if clip == "Axe_Chop" else "")
            visual.call("_refresh_weapon")
            for phase in range(12):
                animation.play(clip, 0)
                animation.seek(animation.get_animation(clip).length * phase / 12.0, true)
                animation.pause()
                skeleton.advance(0)
                await process_frame
                assert(not final_points.is_empty())
                rows.append({"sex":sex,"clip":clip,"phase":phase,"length":animation.get_animation(clip).length,"points":final_points.duplicate(true),"pose_space":"modifier_completed"})
                if phase % 3 == 0:
                    camera.position = Vector3(3, 1.15, 0.1)
                    camera.look_at(Vector3(0, 0.95, 0))
                    await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png("user://motion-%s-%s-%02d.png" % [sex, clip, phase])
                    captures += 1
        actor.free()
    var file := FileAccess.open("user://motion-points.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(rows))
    file.close()
    print("MOTION_PHASES_OK frames=", captures, " samples=", rows.size())
    quit(0)
