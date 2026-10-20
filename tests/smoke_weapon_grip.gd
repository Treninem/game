extends Node
var failures: Array[String] = []
var checked := 0
var minimum_draw_alignment := 1.0
var bow_sweep_checked := 0
var axe_sweep_checked := 0
func _ready() -> void:
    call_deferred("_run")
func _run() -> void:
    var inventory_before := GameState.snapshot()
    for variant in range(6):
        var sex := 0 if variant < 3 else 5
        var height_cm: float = [160.0, 180.0, 195.0][variant % 3]
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation", "Idle")
        actor.rotation.y = 0.65
        add_child(actor)
        var pivot := Node3D.new()
        pivot.name = "CameraPivot"
        actor.add_child(pivot)
        var visual := preload("res://scripts/humanoid_visual.gd").new()
        visual.appearance_profile = preload("res://scripts/character_appearance.gd").preset(sex)
        visual.appearance_profile.height_cm = height_cm
        actor.add_child(visual)
        visual.set_process(false)
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var data := {}
        visual.grip_modifier.modification_processed.connect(func():
            if not is_instance_valid(visual.held_weapon):
                var fists := []
                for side: String in ["Left", "Right"]:
                    var palm := preload("res://scripts/weapon_grip_modifier.gd").palm_frame(skeleton, side)
                    for finger: String in ["Index", "Middle", "Ring", "Pinky"]:
                        var a := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand" + finger + "1")).origin
                        var b := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand" + finger + "2")).origin
                        var c := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand" + finger + "3")).origin
                        fists.append([rad_to_deg((b - a).angle_to(c - b)), (b - a).normalized().cross((c - b).normalized()).dot(palm.basis.y) * (1.0 if side == "Right" else -1.0)])
                data.fists = fists
                return
            var side := "Left" if visual.held_item == "short_bow" else "Right"
            var a := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex1")).origin
            var b := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex2")).origin
            var c := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex3")).origin
            data.bend = rad_to_deg((b - a).angle_to(c - b))
            var first_direction := (skeleton.global_basis * (b - a)).normalized()
            var second_direction := (skeleton.global_basis * (c - b)).normalized()
            data.fold_side = first_direction.cross(second_direction).dot(visual.grip_modifier.last_grip.basis.y) * (1.0 if side == "Right" else -1.0)
            # Final modifier poses exist only during this signal (Godot API).
            var points := {}
            for bone: String in ["LeftArm", "RightArm", "RightForeArm", "RightHand", "Spine1", "Spine2", "Neck"]:
                points[bone] = actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin))
            data.pose_points = points
            data.arm_bend = rad_to_deg(((points.RightForeArm as Vector3) - (points.RightArm as Vector3)).angle_to((points.RightHand as Vector3) - (points.RightForeArm as Vector3)))
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
        for fraction: float in [0.0, 0.2, 0.4, 0.6, 0.8]:
            data.erase("fists")
            visual.animation_player.play("Punch", 0.0)
            visual.animation_player.seek(visual.animation_player.get_animation("Punch").length * fraction, true)
            visual.animation_player.pause()
            skeleton.advance(0.0)
            await get_tree().process_frame
            var fists: Array = data.get("fists", [])
            if fists.size() != 8 or visual.grip_modifier.closed_fingers != 10:
                failures.append("Missing final punch fist pose")
            for finger: Array in fists:
                if float(finger[0]) < 30.0 or float(finger[0]) > 120.0 or float(finger[1]) < 0.1:
                    failures.append("Punch hand is open or bends away from its palm")
        # A free hand should retain a mild native curl in locomotion, not the
        # donor rig's straight/splayed fingers. Inspect actual bone geometry.
        for clip: String in ["Idle", "Walk", "Run"]:
            visual.animation_player.play(clip)
            for fraction: float in [0.0, 0.25, 0.5, 0.75]:
                visual.animation_player.seek(visual.animation_player.get_animation(clip).length * fraction, true)
                visual.animation_player.pause()
                skeleton.advance(1.0 / 60.0)
                await get_tree().process_frame
                for side: String in ["Left", "Right"]:
                    for finger: String in ["Index", "Middle", "Ring", "Pinky"]:
                        var a := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand" + finger + "1")).origin
                        var b := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand" + finger + "2")).origin
                        var c := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand" + finger + "3")).origin
                        var angle := rad_to_deg((b - a).angle_to(c - b))
                        if angle < 5.0 or angle > 50.0:
                            failures.append("Unarmed finger is straight or over-curled: %s/%s/%s %.2f" % [sex, clip, finger, angle])
                        var palm := preload("res://scripts/weapon_grip_modifier.gd").palm_frame(skeleton, side)
                        var curl_side := (b - a).normalized().cross((c - b).normalized()).dot(palm.basis.y) * (1.0 if side == "Right" else -1.0)
                        if curl_side < 0.05:
                            failures.append("Unarmed finger bends away from palm: %s/%s/%s" % [sex, clip, finger])
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
                    if clip == "Axe_Chop" and time >= 0.12 and time <= 0.75:
                        var bend: float = data.get("arm_bend", -1.0)
                        if bend < 25.0 or bend > 140.0:
                            failures.append("Axe contact locks or folds elbow: body=%s height=%s bend=%s" % [sex, height_cm, bend])
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
                            var right_shoulder := actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightArm")).origin))
                            var right_elbow := actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightForeArm")).origin))
                            var right_wrist := actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin))
                            var ratio := height_cm / 180.0
                            if variant == 0 and is_equal_approx(time, 0.396):
                                print("BOW_RIGHT_ARM_DIAGNOSTIC shoulder=", right_shoulder, " elbow=", right_elbow, " wrist=", right_wrist)
                            if right_wrist.x < 0.04 * ratio or right_wrist.z > 0.03 * ratio:
                                failures.append("Drawing wrist crosses torso center or goes behind body: %s" % right_wrist)
                            if right_elbow.x < right_shoulder.x + 0.06 * ratio:
                                failures.append("Drawing elbow folds into the torso")
                            if right_elbow.y > right_shoulder.y + 0.14 * ratio:
                                failures.append("Drawing elbow rises above the natural shoulder line")
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
        actor.set_meta("preview_item", "short_bow")
        visual.call("_refresh_weapon")
        await _check_bow_sweep(actor, visual, skeleton, height_cm, data)
        actor.set_meta("preview_item", "starter_axe")
        visual.call("_refresh_weapon")
        await _check_axe_sweep(visual, skeleton, data)
        actor.set_meta("preview_item", "")
        visual.call("_refresh_weapon")
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
    print("BOW_BODY_SWEEP_CHECKED ", bow_sweep_checked)
    print("AXE_SWEEP_CHECKED ", axe_sweep_checked)
    print("PUNCH_FINGERS_CHECKED 240 final_modifier=true free_hand_recovery=checked")
    if failures.is_empty():
        print("WEAPON_GRIP_OK poses=",checked," bodies=2 heights=3 shaft_contact=measured fingers=closed string=contact unequip=released inventory=unchanged")
    get_tree().quit(0 if failures.is_empty() else 1)

func _check_bow_sweep(actor: CharacterBody3D, visual: Node3D, skeleton: Skeleton3D, height_cm: float, data: Dictionary) -> void:
    var ratio := height_cm / 180.0
    var pivot := actor.get_node("CameraPivot") as Node3D
    for pitch: float in [-0.55, 0.0, 0.55]:
        pivot.rotation.x = pitch
        for clip: String in ["Bow_Attack_Draw", "Bow_Attack_Shoot"]:
            for sample in range(25):
                var animator: AnimationPlayer = visual.get("animation_player")
                data.erase("pose_points")
                animator.play(clip, 0)
                animator.seek(animator.get_animation(clip).length * sample / 24.0, true)
                animator.pause()
                skeleton.advance(0)
                await get_tree().process_frame
                var points: Dictionary = data.get("pose_points", {})
                if points.is_empty():
                    failures.append("Missing final bow modifier pose")
                    continue
                # A conservative central torso volume, derived from the live
                # skeleton. This catches an arm crossing the chest/back; exact
                # cloth-surface clearance still requires graphical inspection.
                var center: Vector3 = points.Spine2
                var side: Vector3 = points.RightArm - points.LeftArm
                side.y = 0
                var radius_x := side.length() * 0.36
                side = side.normalized()
                var forward := Vector3(side.z, 0, -side.x)
                var radius_z := 0.09 * ratio
                for segment in [["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"]]:
                    for step in range(3 if segment[0] == "RightArm" else 1, 13):
                        var point: Vector3 = (points[segment[0]] as Vector3).lerp(points[segment[1]], step / 12.0)
                        if point.y <= points.Spine1.y or point.y >= points.Neck.y - 0.045 * ratio:
                            continue
                        var radial := pow((point - center).dot(side) / radius_x, 2) + pow((point - center).dot(forward) / radius_z, 2)
                        if radial < 1.0:
                            failures.append("Bow arm crosses central torso: height=%s pitch=%s %s sample=%d segment=%s point=%s" % [height_cm, pitch, clip, sample, segment, point])
                            break
                bow_sweep_checked += 1

func _check_axe_sweep(visual: Node3D, skeleton: Skeleton3D, data: Dictionary) -> void:
    var animator: AnimationPlayer = visual.get("animation_player")
    for sample in range(25):
        var time := 0.99 * sample / 24.0
        data.erase("arm_bend")
        animator.play("Axe_Chop", 0.0)
        animator.seek(time, true)
        animator.pause()
        skeleton.advance(0.0)
        await get_tree().process_frame
        var bend: float = data.get("arm_bend", -1.0)
        if bend < 0.0:
            failures.append("Missing final axe modifier pose")
        elif time >= 0.12 and time <= 0.75 and (bend < 25.0 or bend > 140.0):
            failures.append("Axe interpolated elbow locks or folds: time=%s bend=%s" % [time, bend])
        axe_sweep_checked += 1
