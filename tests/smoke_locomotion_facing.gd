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
    player.queue_free()
    await get_tree().process_frame
    GameState.load_snapshot(snapshot)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("LOCOMOTION_FACING_OK directions=5 camera=stable combat=aim furniture=stable rates=15,60 gait_phases=3 bodies=2")
    get_tree().quit(0 if failures.is_empty() else 1)
