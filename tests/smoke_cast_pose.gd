extends Node3D

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var snapshot := GameState.snapshot()
    for preset in [0, 5]:
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation", "Idle")
        add_child(actor)
        var visual := preload("res://scripts/humanoid_visual.gd").new()
        visual.appearance_profile = preload("res://scripts/character_appearance.gd").preset(preset)
        actor.add_child(visual)
        visual.set_process(false)
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        for side: String in ["Left", "Right"]:
            var key := "Cast_" + side
            if not visual.animation_player.has_animation(key):
                failures.append("Missing free-hand cast clip: %s body=%s" % [key, preset])
                continue
            var clip: Animation = visual.animation_player.get_animation(key)
            if clip.loop_mode != Animation.LOOP_NONE or not is_equal_approx(clip.length, 0.45):
                failures.append("Cast clip does not match actual cast window")
            visual.animation_player.play(key)
            visual.animation_player.seek(0.18, true)
            visual.animation_player.pause()
            skeleton.force_update_all_bone_transforms()
            var shoulder := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(side + "Arm")).origin)
            var wrist := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand")).origin)
            var forward_distance := (wrist - shoulder).dot(-visual.global_basis.z.normalized())
            if forward_distance < 0.35:
                failures.append("Casting palm does not reach forward: %s %s" % [key, forward_distance])
            var other := "Right" if side == "Left" else "Left"
            for suffix in ["Arm", "ForeArm", "Hand"]:
                var path := NodePath("%s:%s%s" % [visual.animation_player.get_node(visual.animation_player.root_node).get_path_to(skeleton), other, suffix])
                var original: Animation = visual.animation_player.get_animation("Idle")
                var track := original.find_track(path, Animation.TYPE_ROTATION_3D)
                var cast_track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
                if track < 0 or cast_track < 0:
                    failures.append("Missing occupied arm track")
                elif absf(original.rotation_track_interpolate(track, 0.0).normalized().dot(clip.rotation_track_interpolate(cast_track, 0.18).normalized())) < 0.99999:
                    failures.append("Cast moves occupied weapon arm")
        actor.queue_free()
        await get_tree().process_frame
    GameState.load_snapshot(snapshot)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("CAST_POSE_OK bodies=2 hands=2 palm=forward occupied_arm=unchanged duration=0.45")
    get_tree().quit(0 if failures.is_empty() else 1)
