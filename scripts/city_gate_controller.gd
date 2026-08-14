extends Node

var left_door: StaticBody3D
var right_door: StaticBody3D
var last_open_state := false
var initialized := false
var elapsed := 0.0

func _ready() -> void:
    call_deferred("_resolve_gate")

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed < 0.5:
        return
    elapsed = 0.0
    if not initialized:
        _resolve_gate()
    if initialized:
        _apply_schedule()

func _resolve_gate() -> void:
    var district := get_parent()
    if district == null:
        return
    left_door = district.get_node_or_null("GateDoorL") as StaticBody3D
    right_door = district.get_node_or_null("GateDoorR") as StaticBody3D
    initialized = left_door != null and right_door != null
    if initialized:
        _apply_schedule(true)

func _apply_schedule(force: bool = false) -> void:
    var hour := int(GameState.world_minutes / 60.0) % 24
    var should_open := hour >= 6 and hour < 21
    if not force and should_open == last_open_state:
        return
    last_open_state = should_open
    if should_open:
        left_door.position = Vector3(-5.25, 3.0, -13.1)
        right_door.position = Vector3(5.25, 3.0, -13.1)
        left_door.rotation.y = deg_to_rad(90.0)
        right_door.rotation.y = deg_to_rad(-90.0)
    else:
        left_door.position = Vector3(-1.9, 3.0, -13.1)
        right_door.position = Vector3(1.9, 3.0, -13.1)
        left_door.rotation.y = 0.0
        right_door.rotation.y = 0.0
