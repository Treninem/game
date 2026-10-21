extends Node3D

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var snapshot := GameState.snapshot()
    var stage := preload("res://scenes/stage1.tscn").instantiate()
    var player := stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    var floor_body := StaticBody3D.new()
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(20, 1, 20)
    collider.shape = shape
    floor_body.add_child(collider)
    floor_body.position.y = -0.5
    add_child(floor_body)
    add_child(player)
    player.set_physics_process(false)
    player.set_process_input(false)
    player.global_position = Vector3(0, 0.08, 0)
    player.rotation.y = 0.73
    var visual := player.get_node("Avatar")
    visual.set_process(false)
    for frame in range(4):
        await get_tree().physics_frame
        player.velocity = Vector3.DOWN
        player.move_and_slide()
    if not player.is_on_floor():
        failures.append("Fixture did not acquire a physical floor")
    var actor_basis := player.global_basis
    for direction in [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3(1, 0, -1).normalized()]:
        var motion: Vector3 = actor_basis * direction * 5.0
        for frame in range(60):
            visual.call("_update_locomotion_facing", player, motion, 1.0 / 60.0)
        if (-visual.global_basis.z).normalized().dot(motion.normalized()) < 0.999:
            failures.append("Visual does not face actual motion: " + str(direction))
        if not player.global_basis.is_equal_approx(actor_basis):
            failures.append("Visual turn changed camera/input actor basis")
    var stopped_yaw: float = visual.rotation.y
    visual.call("_update_locomotion_facing", player, Vector3.ZERO, 0.5)
    if not is_equal_approx(stopped_yaw, visual.rotation.y):
        failures.append("Stationary visual turned without movement")
    for action in ["attack_elapsed", "cast_elapsed"]:
        player.set(action, 0.3)
        visual.call("_update_locomotion_facing", player, Vector3.RIGHT * 5, 0.016)
        if not is_zero_approx(visual.rotation.y):
            failures.append("Combat visual differs from aim: " + action)
        player.set(action, 0.0)
        visual.rotation.y = 1.1
    player.set_meta("activity", "sit")
    visual.call("_update_locomotion_facing", player, Vector3.LEFT * 5, 0.5)
    if not is_equal_approx(visual.rotation.y, 1.1):
        failures.append("Furniture pose changed orientation")
    player.set_meta("activity", "idle")
    # Exponential turning should agree under different render-frame partitions.
    visual.rotation.y = 0
    for frame in range(60):
        visual.call("_update_locomotion_facing", player, actor_basis * Vector3.RIGHT * 5, 1.0 / 60.0)
    var sixty_hz: float = visual.rotation.y
    visual.rotation.y = 0
    for frame in range(15):
        visual.call("_update_locomotion_facing", player, actor_basis * Vector3.RIGHT * 5, 1.0 / 15.0)
    if absf(angle_difference(sixty_hz, visual.rotation.y)) > 0.0001:
        failures.append("Turning depends on render frame partition")
    for sex: String in ["male", "female"]:
        visual.call("apply_appearance", {"sex": sex})
        var animator: AnimationPlayer = visual.get("animation_player")
        for phase: float in [0.2, 0.63, 0.92]:
            for transition in [["Walk", "Run"], ["Run", "Walk"]]:
                visual.call("_play", transition[0], 1.0)
                var source_clip := animator.get_animation(transition[0])
                animator.seek(source_clip.length * phase, true)
                visual.call("_play", transition[1], 1.0)
                var destination := animator.get_animation(transition[1])
                if absf(animator.current_animation_position / destination.length - phase) > 0.001:
                    failures.append("Foot cycle restarted: %s %s phase=%s" % [sex, transition, phase])
                visual.call("_play", transition[1], 1.2)
                if absf(animator.current_animation_position / destination.length - phase) > 0.001:
                    failures.append("Speed-only update restarted foot cycle")
        visual.call("_play", "Idle", 1.0)
        visual.call("_play", "Run", 1.0)
        if not is_zero_approx(animator.current_animation_position):
            failures.append("Idle transition inherited a stale gait phase")
    await _check_stride_speed(player, visual)
    await _check_airborne_actions(player, visual)
    await _check_jump_phases(player, visual)
    player.queue_free()
    await get_tree().process_frame
    GameState.load_snapshot(snapshot)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("LOCOMOTION_FACING_OK directions=5 camera=stable combat=aim furniture=stable rates=15,60 gait_phases=3 bodies=2")
    get_tree().quit(0 if failures.is_empty() else 1)

func _check_airborne_actions(player: CharacterBody3D, visual: Node3D) -> void:
    player.velocity = Vector3(2, 5, 0)
    player.move_and_slide()
    if player.is_on_floor():
        failures.append("Airborne fixture stayed grounded")
        return
    for sex: String in ["male", "female"]:
        GameState.set_world_value("player_appearance", {"sex": sex})
        visual.call("apply_appearance", {"sex": sex})
        visual.call("_process", 0.016)
        for entry in [["short_bow", "Bow_Attack_Draw", 0.1, 0.0], ["short_bow", "Bow_Attack_Shoot", 0.0, 0.0], ["starter_axe", "Axe_Chop", 0.0, 0.0], ["", "Punch", 0.0, 0.0], ["", "Cast_Left", 0.0, 0.2], ["short_bow", "Cast_Right", 0.0, 0.2]]:
            InventorySystem.unequip("weapon")
            if entry[0] != "":
                GameState.add_item(entry[0], 1)
                InventorySystem.equip(entry[0])
            player.set("attack_elapsed", 0.3 if float(entry[3]) == 0.0 else 0.0)
            player.set("pending_bow_elapsed", entry[2])
            player.set("cast_elapsed", entry[3])
            visual.call("_process", 0.016)
            var animator: AnimationPlayer = visual.get("animation_player")
            if animator.assigned_animation != entry[1]:
                failures.append("Airborne action lost its arm pose: %s %s got %s" % [sex, entry[1], animator.assigned_animation])
            if entry[1] == "Punch" and absf(animator.get_animation("Punch").length / animator.speed_scale - float(player.get("attack_cooldown"))) > 0.001:
                failures.append("Punch recovery is cut off by the attack window")
            animator.seek(0.2, true)
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            var modifier: Node = visual.get("grip_modifier")
            var previous_phase: float = modifier.get("gait_time")
            modifier.call("_moving_legs", skeleton, 0.24)
            if not is_equal_approx(previous_phase, float(modifier.get("gait_time"))):
                failures.append("Ground stride clock advanced while airborne")
            var airborne := animator.get_animation("Airborne")
            for name: String in ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot"]:
                for track in range(airborne.get_track_count()):
                    var path := airborne.track_get_path(track)
                    if path.get_subname_count() > 0 and String(path.get_subname(0)) == name and airborne.track_get_type(track) == Animation.TYPE_ROTATION_3D:
                        var time := clampf((5.5 - player.velocity.y) / 11.0, 0.0, 1.0) * airborne.length
                        var expected := airborne.rotation_track_interpolate(track, time)
                        if skeleton.get_bone_pose_rotation(skeleton.find_bone(name)).angle_to(expected) > 0.001:
                            failures.append("Airborne action uses grounded leg pose: %s %s %s" % [sex, entry[1], name])
    player.set("attack_elapsed", 0.0)
    player.set("pending_bow_elapsed", 0.0)
    player.set("cast_elapsed", 0.0)
    visual.call("_process", 0.016)
    if (visual.get("animation_player") as AnimationPlayer).assigned_animation != "Airborne":
        failures.append("Airborne idle lost its jump pose")
    InventorySystem.unequip("weapon")
    for frame in range(5):
        await get_tree().physics_frame
        player.velocity = Vector3.DOWN * 5
        player.move_and_slide()
    if not player.is_on_floor():
        failures.append("Landing fixture did not reacquire floor")
    visual.call("_process", 0.016)
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var modifier: Node = visual.get("grip_modifier")
    modifier.call("_moving_legs", skeleton, 0.016)
    if not is_zero_approx(float(modifier.get("airborne_time"))):
        failures.append("Airborne leg time did not reset on landing")
    print("AIRBORNE_ACTIONS_CHECKED bodies=2 actions=6 legs=6 idle=retained landing=reset gait=frozen")

func _check_stride_speed(player: CharacterBody3D, visual: Node3D) -> void:
    for sex: String in ["male", "female"]:
        var profile := {"sex": sex, "height_cm": 180.0}
        GameState.set_world_value("player_appearance", profile)
        visual.call("apply_appearance", profile)
        visual.set("appearance_revision", GameState.state_revision)
        visual.rotation.y = 0.0
        var animator: AnimationPlayer = visual.get("animation_player")
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var supports := {}
        # Ankle peak speed includes heel roll. Measure the median forefoot
        # backward speed only while both interval endpoints are near its low
        # contact height. All physical speed assertions remain at 15 percent.
        for gait: String in ["Walk", "Run"]:
            animator.play(gait, 0.0)
            var clip := animator.get_animation(gait)
            var poses: Array[Dictionary] = []
            var lows := {"Left": INF, "Right": INF}
            for sample in range(13):
                animator.seek(clip.length * sample / 12.0, true)
                animator.pause()
                skeleton.force_update_all_bone_transforms()
                await get_tree().process_frame
                var points := {}
                for side: String in ["Left", "Right"]:
                    var point := player.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(side + "ToeBase")).origin))
                    points[side] = point
                    lows[side] = minf(float(lows[side]), point.y)
                poses.append(points)
            var samples: Array[float] = []
            for sample in range(1, poses.size()):
                for side: String in ["Left", "Right"]:
                    var before: Vector3 = poses[sample - 1][side]
                    var after: Vector3 = poses[sample][side]
                    var speed := (after.z - before.z) / (clip.length / 12.0)
                    if maxf(before.y, after.y) <= float(lows[side]) + 0.02 and speed > 0.0:
                        samples.append(speed)
            if samples.size() < 3:
                failures.append("Insufficient actual forefoot contact samples: " + gait)
                supports[gait] = 0.0
            else:
                samples.sort()
                var middle := samples.size() / 2
                supports[gait] = samples[middle] if samples.size() % 2 == 1 else (samples[middle - 1] + samples[middle]) * 0.5
        for height: float in [160.0, 180.0, 195.0]:
            var ratio := height / 180.0
            visual.scale = Vector3.ONE * ratio
            for nominal: float in [0.3, 1.4, 2.4, 5.0, 8.0]:
                var speed := nominal * ratio
                await get_tree().physics_frame
                player.velocity = player.global_basis * Vector3(0, -1, -speed)
                player.move_and_slide()
                visual.set("measured_speed", speed)
                visual.call("_process", 0.016)
                var expected := "Walk" if nominal < 3.0 else "Run"
                if animator.assigned_animation != expected:
                    failures.append("Stride type mismatches physical speed: %s height=%s speed=%s got=%s" % [sex, height, speed, animator.assigned_animation])
                if not supports.has(animator.assigned_animation):
                    failures.append("Stride did not use a grounded gait")
                    continue
                var support: float = float(supports[animator.assigned_animation]) * ratio * animator.speed_scale
                if absf(support - speed) / speed > 0.15:
                    failures.append("Stride support speed mismatch: %s height=%s physical=%s support_median=%s" % [sex, height, speed, support])
        var modifier: Node = visual.get("grip_modifier")
        modifier.set("gait_name", "Walk")
        modifier.set("gait_time", animator.get_animation("Walk").length * 0.37)
        animator.play("Punch", 0.0)
        visual.set("active_animation", "Punch")
        modifier.call("_moving_legs", skeleton, 0.0)
        if absf(float(modifier.call("gait_phase")) - 0.37) > 0.001:
            failures.append("Combat gait change restarted foot phase")
        visual.call("_play", "Walk", 1.0)
        if absf(animator.current_animation_position / animator.get_animation("Walk").length - 0.37) > 0.001:
            failures.append("Combat exit restarted foot phase")
        print("STRIDE_PROFILE_CHECKED ", sex, " forefoot_supports=", supports)
    print("STRIDE_SPEED_CHECKED bodies=2 visual_heights=3 speeds=5 physical_motion=true combat_phase=retained")

func _check_jump_phases(player: CharacterBody3D, visual: Node3D) -> void:
    player.set("attack_elapsed", 0.0)
    player.set("cast_elapsed", 0.0)
    for sex: String in ["male", "female"]:
        GameState.set_world_value("player_appearance", {"sex": sex})
        visual.call("apply_appearance", {"sex": sex})
        visual.set("appearance_revision", GameState.state_revision)
        player.velocity = Vector3.UP * 5.5
        player.move_and_slide()
        var bends := []
        for vertical: float in [5.5, 0.0, -5.5]:
            player.velocity.y = vertical
            visual.call("_process", 0.016)
            var animator: AnimationPlayer = visual.get("animation_player")
            var expected := (5.5 - vertical) / 11.0 * animator.get_animation("Airborne").length
            if absf(animator.current_animation_position - expected) > 0.001:
                failures.append("Jump phase does not follow physical vertical velocity")
            # Isolate clip geometry from the live 0.18-second entry blend.
            # Normal input/blending is exercised by the graphical action test.
            animator.play("Airborne", 0.0)
            animator.seek(expected, true)
            animator.advance(0.0)
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            skeleton.force_update_all_bone_transforms()
            var hip := skeleton.get_bone_global_pose(skeleton.find_bone("RightUpLeg")).origin
            var knee := skeleton.get_bone_global_pose(skeleton.find_bone("RightLeg")).origin
            var ankle := skeleton.get_bone_global_pose(skeleton.find_bone("RightFoot")).origin
            bends.append(rad_to_deg((knee - hip).angle_to(ankle - knee)))
        if float(bends[1]) < float(bends[0]) + 15.0 or float(bends[1]) < 60.0 or float(bends[2]) > 35.0:
            failures.append("Jump does not tuck at apex and extend on descent: " + str(bends))
        print("JUMP_PHASE_PROFILE ", sex, " knee_bends=", bends)
    print("JUMP_PHASES_CHECKED bodies=2 physical_velocity=rise,apex,fall combat_legs=matched")
