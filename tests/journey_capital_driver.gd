extends Node

var player: CharacterBody3D
var points: Array[Vector2] = [Vector2(10, 385), Vector2(90, 365), Vector2(250, 294), Vector2(650, 120), Vector2(1400, -200), Vector2(1450, -100), Vector2(1900, -100), Vector2(1900, -500), Vector2(2450, -900), Vector2(3650, -1750), Vector2(7200, -3300), Vector2(11450, -6250), Vector2(11570, -6250), Vector2(11580, -6200), Vector2(13500, -6200), Vector2(13500, -7000)]
var index := 0
var previous := Vector3.ZERO
var elapsed := 0.0
var report_elapsed := 0.0
var distance := 0.0
var stuck := 0.0
var started := false
var resting := false
var window_position := Vector3.ZERO
var avoid_until := 0.0
var avoid_direction := Vector3.ZERO

func _ready() -> void:
    process_priority = 100
    call_deferred("_start")

func _start() -> void:
    await get_tree().create_timer(5.0).timeout
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    previous = player.global_position
    window_position = previous
    GameState.add_item("berries", 10)
    GameState.add_item("water_flask", 10)
    started = true
    print("JOURNEY_START position=", previous, " speed=", player.run_speed, " time_scale=", Engine.time_scale, " test_supplies=10_berries_10_water no_position_assignments=true")

func _physics_process(delta: float) -> void:
    if not started:
        return
    elapsed += delta
    var moved := player.global_position - previous
    var horizontal := Vector2(moved.x, moved.z).length()
    previous = player.global_position
    if horizontal > player.run_speed * delta * 3.0 + 0.4 or absf(moved.y) > 1.0:
        _finish(false, "Unexpected discontinuous displacement: %s" % moved)
        return
    distance += horizontal
    if GameState.is_dead:
        _finish(false, "Player died during the route")
        return
    if elapsed > 7200:
        _finish(false, "Route exceeded two simulated hours")
        return
    var position := Vector2(player.global_position.x, player.global_position.z)
    if position.distance_to(points[index]) < 4.0:
        print("JOURNEY_WAYPOINT index=", index, " position=", player.global_position, " travelled=", distance, " seconds=", elapsed)
        index += 1
        if index >= points.size():
            _finish(true, "Capital square reached on foot")
            return
    if GameState.hunger < 45:
        GameState.use_consumable("berries")
    if GameState.thirst < 45:
        GameState.use_consumable("water_flask")
    if GameState.stamina < 8:
        resting = true
    elif GameState.stamina > 70:
        resting = false
    if index == 12 and player.global_position.x > 11470 and not CapitalData.gates_are_open(GameState.world_minutes):
        Input.action_release("move_forward")
        Input.action_release("sprint")
        return
    Input.action_press("move_forward")
    if resting:
        Input.action_release("sprint")
    else:
        Input.action_press("sprint")
    var to_target := points[index] - position
    var direction := Vector3(to_target.x, 0, to_target.y).normalized()
    if elapsed < avoid_until:
        direction = avoid_direction
    elif _blocked(direction, 2.5):
        for angle in [0.65, -0.65, 1.15, -1.15, 1.65, -1.65]:
            var candidate := direction.rotated(Vector3.UP, angle)
            if not _blocked(candidate, 3.0):
                avoid_direction = candidate
                avoid_until = elapsed + 1.5
                direction = candidate
                break
    player.rotation.y = atan2(-direction.x, -direction.z)
    stuck = stuck + delta if horizontal < 0.005 and not player.ground_guard_active else 0.0
    if stuck > 20:
        _finish(false, "Blocked route at %s waypoint=%d" % [player.global_position, index])
        return
    report_elapsed += delta
    if report_elapsed > 15:
        if player.global_position.distance_to(window_position) < 2.0 and not player.ground_guard_active:
            _finish(false, "No net progress during a 15-second interval")
            return
        window_position = player.global_position
        report_elapsed = 0
        print("JOURNEY_PROGRESS waypoint=", index, " position=", player.global_position, " travelled=", distance, " grounded=", player.is_on_floor(), " fps=", Engine.get_frames_per_second(), " seconds=", elapsed)

func _blocked(direction: Vector3, length: float) -> bool:
    var origin := player.global_position + Vector3.UP * 1.0
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * length, 1, [player.get_rid()])
    return not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _finish(success: bool, reason: String) -> void:
    started = false
    Input.action_release("move_forward")
    Input.action_release("sprint")
    print("JOURNEY_RESULT success=", success, " reason=", reason, " distance=", distance, " seconds=", elapsed, " position=", player.global_position)
    if not success:
        push_error(reason)
    else:
        var saved := SaveManager.save_game(player, 1)
        var proof := {"success": true, "reason": reason, "distance_m": distance, "simulated_seconds": elapsed, "position": [player.global_position.x, player.global_position.y, player.global_position.z], "waypoints_completed": index, "position_assignments": 0, "saved_slot_1": saved, "engine_time_scale": Engine.time_scale}
        var file := FileAccess.open("user://journey_result.json", FileAccess.WRITE)
        file.store_string(JSON.stringify(proof, "  "))
        file.close()
        if not saved:
            push_error("Route finished but arrival save failed")
            success = false
    if DisplayServer.get_name() == "headless":
        get_tree().quit(0 if success else 1)


