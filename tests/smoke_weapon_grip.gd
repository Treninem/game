extends Node
var failures: Array[String] = []
var checked := 0
var minimum_draw_alignment := 1.0
func _ready() -> void:
    call_deferred("_run")
func _run() -> void:
    var inventory_before := GameState.snapshot()
    for sex in [0, 5]:
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation", "Idle")
        actor.rotation.y = 0.65
        add_child(actor)
        var pivot := Node3D.new()
        pivot.name = "CameraPivot"
        actor.add_child(pivot)
        var visual := preload("res://scripts/humanoid_visual.gd").new()
        visual.appearance_profile = preload("res://scripts/character_appearance.gd").preset(sex)
        actor.add_child(visual)
        visual.set_process(false)
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var data := {}
        visual.grip_modifier.modification_processed.connect(func():
            if not is_instance_valid(visual.held_weapon):
                return
            var side := "Left" if visual.held_item == "short_bow" else "Right"
            var a := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex1")).origin
            var b := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex2")).origin
            var c := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex3")).origin
            data.bend = rad_to_deg((b - a).angle_to(c - b))
            var first_direction := (skeleton.global_basis * (b - a)).normalized()
            var second_direction := (skeleton.global_basis * (c - b)).normalized()
            data.fold_side = first_direction.cross(second_direction).dot(visual.grip_modifier.last_grip.basis.y) * (1.0 if side == "Right" else -1.0)
            var mesh := visual.held_weapon.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
            # Independent markers measured on the actual normalized source mesh.
            var marker := Vector3(0, 0, 0.30429) if visual.held_item == "starter_axe" else Vector3.ZERO
            data.gap = mesh.to_global(marker).distance_to(visual.grip_modifier.last_grip.origin)
            var shoulder := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("LeftArm")).origin)
            var wrist := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("LeftHand")).origin)
            var aimed := -(actor.global_basis * Basis(Vector3.RIGHT, pivot.rotation.x)).z
            data.arm_alignment = (wrist - shoulder).normalized().dot(aimed)
            data.cord_gap = 0.0
            if visual.held_item == "short_bow" and visual.animation_player.assigned_animation == "Bow_Attack_Draw":
                var hand := skeleton.to_global((skeleton.get_bone_global_pose(skeleton.find_bone("RightHandIndex2")).origin + skeleton.get_bone_global_pose(skeleton.find_bone("RightHandMiddle2")).origin) * 0.5)
                data.cord_gap = hand.distance_to(visual.last_draw_point)
        )
        for item in ["starter_axe", "short_bow"]:
            actor.set_meta("preview_item", item)
            visual.call("_refresh_weapon")
            pivot.rotation.x = 0.35 if sex == 0 else -0.35
            for clip: String in (["Idle", "Walk", "Axe_Chop"] if item == "starter_axe" else ["Idle", "Bow_Attack_Draw", "Bow_Attack_Shoot"]):
                visual.animation_player.play(clip)
                for time in [0.0, 0.12, 0.396, 0.6, 0.75]:
                    visual.animation_player.seek(minf(time, visual.animation_player.get_animation(clip).length), true)
                    visual.animation_player.pause()
                    skeleton.advance(1.0 / 60.0)
                    await get_tree().process_frame
                    if data.is_empty():
                        failures.append("Grip modifier never processed the actual skeleton")
                        continue
                    if float(data.fold_side) < 0.1:
                        failures.append("Finger curls away from its palm")
                    if float(data.bend) < 30 or float(data.bend) > 120:
                        failures.append("Finger folds backwards or fails to close: %s/%s/%s %.2f" % [sex, item, clip, data.bend])
                    if item == "starter_axe" and clip == "Axe_Chop" and is_equal_approx(time, 0.396):
                        var axe_mesh := visual.held_weapon.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
                        var edge := actor.to_local(axe_mesh.to_global(Vector3(0.5, 0, -0.6)))
                        if edge.z > -0.9 or edge.y < 0.8 or edge.y > 1.7:
                            failures.append("Axe damage frame leaves the blade overhead or behind the player: %s" % edge)
                    if float(data.gap) > 0.005:
                        failures.append("Physical handle floats outside palm: %s/%s %.4f m" % [sex, item, data.gap])
                    if clip == "Bow_Attack_Draw":
                        # Cover release and late held poses, including the
                        # female body's previously failing 0.75 s sample.
                        if time >= 0.396:
                            minimum_draw_alignment = minf(minimum_draw_alignment, float(data.arm_alignment))
                            if float(data.arm_alignment) < 0.9:
                                failures.append("Bow arm leaves the aim line during release/hold: sex=%s time=%s dot=%s" % [sex, time, data.arm_alignment])
                        var arrow_mesh := visual.nocked_arrow.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
                        var size := arrow_mesh.get_aabb().size
                        var shaft := arrow_mesh.global_basis * Vector3(0, 0, size.z)
                        var aim := -(actor.global_basis * Basis(Vector3.RIGHT, pivot.rotation.x)).z
                        if absf(shaft.normalized().dot(aim)) < 0.99 or shaft.length() < 0.68 or shaft.length() > 0.72:
                            failures.append("Nocked arrow loses normalized size or pitched aim")
                    if clip == "Bow_Attack_Draw" and not visual.nocked_arrow.visible:
                        failures.append("Draw preview drops the nocked arrow when animation is paused or inspected")
                    if float(data.cord_gap) > 0.005:
                        failures.append("String misses drawing fingers")
                    checked += 1
            actor.set_meta("preview_item", "")
            visual.call("_refresh_weapon")
            skeleton.advance(1.0 / 60.0)
            await get_tree().process_frame
            if is_instance_valid(visual.held_weapon) or visual.grip_modifier.closed_fingers != 0:
                failures.append("Removing equipment retains its mesh or closed-hand constraint")
        get_tree().paused = true
        actor.set_meta("preview_item", "starter_axe")
        visual.call("_refresh_weapon")
        var expected := skeleton.global_transform * preload("res://scripts/weapon_grip_modifier.gd").palm_frame(skeleton, "Right")
        if visual.held_weapon.global_position.distance_to(expected.origin) > 0.005:
            failures.append("Paused inventory equip places weapon at wrist or origin instead of palm")
        actor.set_meta("preview_item", "")
        visual.call("_refresh_weapon")
        if is_instance_valid(visual.held_weapon):
            failures.append("Paused inventory unequip keeps its weapon")
        get_tree().paused = false
        actor.queue_free()
        await get_tree().process_frame
    if GameState.snapshot() != inventory_before:
        failures.append("Visual grip inspection changes real game state")
    for message in failures:
        push_error(message)
    print("BOW_HOLD_ALIGNMENT_MIN ", minimum_draw_alignment)
    if failures.is_empty():
        print("WEAPON_GRIP_OK poses=",checked," bodies=2 shaft_contact=measured fingers=closed string=contact unequip=released inventory=unchanged")
    get_tree().quit(0 if failures.is_empty() else 1)
