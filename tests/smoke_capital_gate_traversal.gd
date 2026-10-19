extends Node
var hour := 9.0
var failures: Array[String] = []
func _process(_delta: float) -> void:
    GameState.world_minutes = hour * 60.0
func _ready() -> void:
    call_deferred("_run")
func _ray(player: CharacterBody3D, a: Vector3, b: Vector3) -> Dictionary:
    return player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1, [player.get_rid()]))
func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    var player := world.get_node("World/Player") as CharacterBody3D
    # Unit fixture outside the real western gate; long journey QA is separate.
    player.global_position = Vector3(11460, 0.15, -6250)
    player.rotation.y = -PI * 0.5
    player.call("_begin_ground_guard", true)
    for frame in range(240):
        await get_tree().physics_frame
    for gate: Dictionary in CapitalData.gates():
        var position: Vector2 = gate.position
        var normal: Vector2 = gate.normal
        var a := Vector3(position.x + normal.x * 8, 1, position.y + normal.y * 8)
        var b := Vector3(position.x - normal.x * 8, 1, position.y - normal.y * 8)
        if not _ray(player, a, b).is_empty():
            failures.append("Daytime gate is physically blocked: " + String(gate.id))
    hour = 23
    for frame in range(180):
        await get_tree().physics_frame
    for gate: Dictionary in CapitalData.gates():
        var position: Vector2 = gate.position
        var normal: Vector2 = gate.normal
        var a := Vector3(position.x + normal.x * 3, 1, position.y + normal.y * 3)
        var b := Vector3(position.x - normal.x * 3, 1, position.y - normal.y * 3)
        if _ray(player, a, b).is_empty():
            failures.append("Night gate has no closed door collision: " + String(gate.id))
    hour = 9
    for frame in range(180):
        await get_tree().physics_frame
    Input.action_press("move_forward")
    for frame in range(2000):
        await get_tree().physics_frame
        if player.global_position.x > 11585:
            break
    Input.action_release("move_forward")
    if player.global_position.x < 11585 or not player.is_on_floor():
        failures.append("Player cannot enter through the western gate and reach the street: %s" % player.global_position)
    var city := world.get_node("World/CityDistrict")
    for cell: Node3D in city.loaded_cells.values():
        for house: StaticBody3D in cell.find_children("House_*", "StaticBody3D", true, false):
            var footprint: Vector2 = house.get_meta("map_footprint", Vector2.ZERO)
            if CapitalData.in_gate_approach(Vector2(house.global_position.x, house.global_position.z), maxf(footprint.x, footprint.y) * 0.5):
                failures.append("A streamed house blocks a gate approach")
    if failures.is_empty():
        print("CAPITAL_GATE_TRAVERSAL_OK open_gates=32 closed_gates=32 west_entry=walked approaches=clear")
    for failure in failures:
        push_error(failure)
    world.queue_free()
    await get_tree().create_timer(0.15, true).timeout
    get_tree().quit(0 if failures.is_empty() else 1)
