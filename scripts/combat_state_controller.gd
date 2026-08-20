extends Node

const COMBAT_RADIUS := 20.0
const COMBAT_RELEASE_SECONDS := 4.0

var player: Node3D
var scan_elapsed := 0.0
var release_elapsed := 0.0
var last_state := false

func _ready() -> void:
    process_priority = 15
    call_deferred("_resolve_player")

func _process(delta: float) -> void:
    _resolve_player()
    if player == null:
        return
    if bool(ProgressionSystem.snapshot().get("in_dungeon", false)):
        _set_combat(true)
        release_elapsed = 0.0
        return
    scan_elapsed += delta
    if scan_elapsed < 0.25:
        return
    scan_elapsed = 0.0

    var hostile_near := false
    for hostile in get_tree().get_nodes_in_group("hostile"):
        if not is_instance_valid(hostile) or hostile is not Node3D:
            continue
        if player.global_position.distance_to((hostile as Node3D).global_position) <= COMBAT_RADIUS:
            hostile_near = true
            break

    if hostile_near:
        release_elapsed = 0.0
        _set_combat(true)
    elif last_state:
        release_elapsed += 0.25
        if release_elapsed >= COMBAT_RELEASE_SECONDS:
            release_elapsed = 0.0
            _set_combat(false)

func mark_combat(seconds: float = COMBAT_RELEASE_SECONDS) -> void:
    release_elapsed = minf(0.0, COMBAT_RELEASE_SECONDS - maxf(seconds, 0.0))
    _set_combat(true)

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D

func _set_combat(active: bool) -> void:
    if last_state == active:
        return
    last_state = active
    ProgressionSystem.set_combat_active(active)
