extends RefCounted

func run(parent: Node3D) -> Array[String]:
    var failures: Array[String] = []
    var tree := parent.get_tree()
    var ground := StaticBody3D.new()
    ground.position = Vector3(80, -0.5, 0)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(12, 1, 12)
    collider.shape = shape
    ground.add_child(collider)
    parent.add_child(ground)
    for sex: String in ["male", "female"]:
        var stage := load("res://scenes/stage1.tscn").instantiate() as Node
        var player := stage.get_node("World/Player") as CharacterBody3D
        player.get_parent().remove_child(player)
        stage.free()
        parent.add_child(player)
        player.call("_set_instanced_world_mode", true)
        player.position = Vector3(80, 0.08, 0)
        for action: String in ["move_forward", "move_back", "move_left", "move_right", "sprint", "attack"]:
            Input.action_release(action)
        InventorySystem.unequip("weapon")
        GameState.set_world_value("player_appearance", {"sex":sex, "height_cm":180.0})
        var visual := player.get_node("Avatar") as Node3D
        visual.call("apply_appearance", {"sex":sex, "height_cm":180.0})
        visual.set("appearance_revision", GameState.state_revision)
        var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
        var modifier: Node = visual.get("grip_modifier")
        var probe := preload("res://tests/humanoid_skin_probe.gd").new()
        var data := {"hip":0.0,"peak":false,"compression":0.0}
        modifier.modification_processed.connect(func():
            data.hip = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin).y
            var remaining := float(player.get("landing_elapsed"))
            if remaining > 0.07 and remaining < 0.17 and not data.peak:
                data.peak = true
                data.peak_hip = data.hip
                data.compression = float(modifier.get("support").get("landing_compression"))
                var points := probe.points(visual, skeleton)
                var low := INF
                for side: String in ["Left", "Right"]:
                    for point: Vector3 in points[side]:
                        low = minf(low, point.y)
                data.sole_gap = low
        )
        for frame in range(25):
            await tree.physics_frame
        var neutral: float = data.hip
        if not player.is_on_floor():
            failures.append("Landing fixture did not acquire floor")
        var jump := InputEventAction.new()
        jump.action = "jump"
        jump.pressed = true
        player.call("_unhandled_input", jump)
        var left_floor := false
        for frame in range(75):
            await tree.physics_frame
            left_floor = left_floor or not player.is_on_floor()
        if not left_floor or not data.peak:
            failures.append("Physical jump never produced its landing compression")
        elif data.compression < 0.04 or float(data.peak_hip) > neutral - 0.025 or float(data.sole_gap) < -0.015 or float(data.sole_gap) > 0.020:
            failures.append("Landing does not compress body with grounded soles: " + str(data))
        if float(player.get("landing_elapsed")) > 0.0 or absf(float(data.hip) - neutral) > 0.02:
            failures.append("Landing pose failed to recover to grounded idle")
        var animator: AnimationPlayer = visual.get("animation_player")
        modifier.set("gait_name", "Walk")
        modifier.set("gait_time", animator.get_animation("Walk").length * 0.37)
        visual.set("active_animation", "Airborne")
        animator.play("Airborne", 0.0)
        visual.call("_play", "Run", 1.0)
        if absf(animator.current_animation_position / animator.get_animation("Run").length - 0.37) > 0.001:
            failures.append("Landing restarted the preserved ground stride")
        player.set("landing_elapsed", 0.12)
        player.call("_set_instanced_world_mode", true)
        if not is_zero_approx(float(player.get("landing_elapsed"))):
            failures.append("World/load mode transition retained stale landing pose")
        print("HUMANOID_LANDING_PROFILE ",sex," compression=",data.compression," peak_sole_gap=",data.get("sole_gap",INF)," neutral_hip=",neutral," peak_hip=",data.get("peak_hip",INF))
        player.queue_free()
        await tree.process_frame
    ground.queue_free()
    await tree.process_frame
    print("HUMANOID_LANDING_CHECKED bodies=2 input=jump impact=physical soles=skinned recovery=idle gait_phase=retained transient_reset=true")
    return failures
