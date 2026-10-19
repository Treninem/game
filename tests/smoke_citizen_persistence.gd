extends Node

const CITIZEN := preload("res://scripts/settlement_npc.gd")
var errors: Array[String] = []
var world: Node3D
var height := 0.0

func _ready() -> void:
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await get_tree().physics_frame

func _citizen(id: String = "test:persistent_traveler") -> SettlementNPC:
    var citizen := CITIZEN.new()
    citizen.name = "PersistentTraveler"
    citizen.autonomous = true
    citizen.set_meta("citizen_id", id)
    citizen.configure("Путник", "traveler", 0, [])
    citizen.position = Vector3(10, height + 0.08, 0)
    world.add_child(citizen)
    return citizen

func _run() -> void:
    GameState.reset_new_game()
    world = Node3D.new()
    world.position = Vector3(65, 0, 48)
    add_child(world)
    height = WorldData.elevation_at(Vector2(65, 48))
    var floor := StaticBody3D.new()
    floor.position.y = height - 0.5
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(100, 1, 100)
    collision.shape = shape
    floor.add_child(collision)
    world.add_child(floor)
    var citizen := _citizen()
    await _frames(240)
    var point := citizen.position
    if point.distance_to(Vector3(10, height, 0)) < 3:
        errors.append("Persistence fixture did not actually walk away from its authored spawn")
    citizen.home_crossing = true
    citizen.witnessed_pause = 3.0
    var snapshot: Dictionary = JSON.parse_string(JSON.stringify(GameState.snapshot()))
    citizen.free()
    citizen = _citizen()
    if citizen.position.distance_to(point) > 0.02:
        errors.append("Streamed resident returns to spawn instead of its last physical position")
    if not citizen.home_crossing or citizen.witnessed_pause < 2.99:
        errors.append("Streaming loses doorway transit or a pending witnessed-event reaction")
    await _frames(10)
    var actor := Node3D.new()
    world.add_child(actor)
    var saved_point := citizen.position
    if not SaveManager.save_game(actor, 3):
        errors.append("Physical resident state could not be saved to an actual slot")
    citizen.position += Vector3(15, 0, 0) # Isolated corruption fixture, not gameplay movement.
    if not SaveManager.load_game(actor, 3) or citizen.position.distance_to(saved_point) > 0.02:
        errors.append("Loading a real save does not restore an already loaded resident immediately")
    if citizen.visual.visible:
        errors.append("Restored resident is visible before revalidating physical ground")
    await _frames(12)
    if not citizen.ground_ready or not citizen.is_on_floor():
        errors.append("Restored resident does not reacquire real floor collision")
    GameState.load_snapshot(snapshot)
    citizen.free()
    citizen = _citizen()
    if citizen.position.distance_to(point) > 0.02:
        errors.append("JSON save round trip loses the resident transform")
    await _frames(5)
    var door := preload("res://scripts/door_interactable.gd").new()
    door.persistence_key = "door:test:resident-transit"
    world.add_child(door)
    door.set_open(true, true)
    var transit_snapshot := GameState.snapshot()
    door.set_open(false, true)
    GameState.load_snapshot(transit_snapshot)
    if not door.opened:
        errors.append("In-place load restores resident transit but leaves its physical door in the wrong state")
    GameState.reset_new_game()
    citizen.free()
    for key: String in GameState.world_state:
        if key.begins_with("citizen:"):
            errors.append("Old scene teardown repopulates a clean new-game state")
    var valid := {"runtime_version": 1, "role": "traveler", "anchor": [65,0,48], "position": [11,height,3], "yaw": 0.5}
    var corrupt: Array = ["not-a-record", {"phase":"home","role":"traveler"}]
    for field in ["position", "anchor", "yaw", "runtime_version", "role"]:
        var bad := valid.duplicate(true)
        bad[field] = {"unexpected":"object"}
        corrupt.append(bad)
    for point_value in [[1000000,0,0], [NAN,0,0], [0,INF,0]]:
        var bad := valid.duplicate(true)
        bad.position = point_value
        corrupt.append(bad)
    for index in range(corrupt.size()):
        var id := "test:corrupt:%d" % index
        GameState.set_world_value("citizen:" + id, corrupt[index])
        var probe := _citizen(id)
        if probe.position.distance_to(Vector3(10,height+0.08,0)) > 0.01:
            errors.append("Malformed/legacy resident state places a citizen outside its safe authored spawn")
        await _frames(2)
        probe.free()
    var bad_anchor := valid.duplicate(true)
    bad_anchor.anchor = [0,0,0]
    var decoder := preload("res://scripts/citizen_runtime_state.gd")
    if not decoder.decode(bad_anchor, world.global_position, Vector3(10,height,0), "traveler").is_empty():
        errors.append("Saved citizen from a different parent anchor is accepted")
    var soft := valid.duplicate(true)
    soft.home_crossing = {"invalid":true}
    soft.witnessed_pause = NAN
    soft.pause_elapsed = INF
    soft.route_index = "bad-index"
    var decoded: Dictionary = decoder.decode(soft, world.global_position, Vector3(10,height,0), "traveler")
    if decoded.is_empty() or decoded.home_crossing or decoded.witnessed_pause != 0.0 or decoded.pause_elapsed != 0.0 or decoded.route_index != 0:
        errors.append("Malformed optional transient fields are not safely bounded")
    for error in errors:
        push_error(error)
    if errors.is_empty():
        print("CITIZEN_PERSISTENCE_OK moved=physical streaming=last_position save=real_slot load=immediate json=round_trip reset=clean corrupt=bounded doorway=retained reaction=retained")
    world.queue_free()
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if errors.is_empty() else 1)
