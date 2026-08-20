extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const PLAYER_ACTIVATION_DISTANCE := 5200.0
const WAVE_SLOTS := PackedInt32Array([0, 1, 2, 3])

var player: Node3D
var scan_elapsed := 0.0
var active_markers: Dictionary = {}

func _ready() -> void:
    process_priority = 35
    call_deferred("_resolve_player")

func _process(delta: float) -> void:
    scan_elapsed += delta
    if scan_elapsed < 1.0:
        return
    scan_elapsed = 0.0
    _resolve_player()
    if player == null:
        return
    var player_xz := Vector2(player.global_position.x, player.global_position.z)
    if player_xz.distance_to(CAPITAL.CENTER) > PLAYER_ACTIVATION_DISTANCE:
        return
    if CAPITAL.gates_are_open(GameState.world_minutes):
        return
    var slot := _night_wave_slot(GameState.world_minutes)
    if slot < 0:
        return
    var day := int(ProgressionSystem.snapshot().get("event_day", 0))
    var marker := "%d:%d" % [day, slot]
    if bool(GameState.get_world_value("capital_siege:" + marker, false)):
        return
    GameState.set_world_value("capital_siege:" + marker, true)
    _spawn_wave(day, slot, player_xz)

func _night_wave_slot(minutes: float) -> int:
    var minute := int(minutes) % 1440
    if minute >= 21 * 60 and minute < 23 * 60:
        return 0
    if minute >= 23 * 60 or minute < 1 * 60:
        return 1
    if minute >= 1 * 60 and minute < 3 * 60:
        return 2
    if minute >= 3 * 60 and minute < 6 * 60:
        return 3
    return -1

func _spawn_wave(day: int, slot: int, player_xz: Vector2) -> void:
    var gates := CAPITAL.gates()
    var ranked: Array[Dictionary] = []
    for gate in gates:
        var gate_pos: Vector2 = gate.get("position", CAPITAL.CENTER)
        ranked.append({"distance": gate_pos.distance_to(player_xz), "gate": gate})
    ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("distance", INF)) < float(b.get("distance", INF)))

    var chosen_count := mini(2, ranked.size())
    for gate_index in range(chosen_count):
        var gate: Dictionary = ranked[gate_index].get("gate", {})
        var gate_pos: Vector2 = gate.get("position", CAPITAL.CENTER)
        var normal: Vector2 = gate.get("normal", Vector2.UP)
        var tangent := Vector2(-normal.y, normal.x)
        for i in range(3 + slot):
            var lateral := float(i - (2 + slot) / 2.0) * 4.5
            var spawn_xz := gate_pos + normal * (CAPITAL.DEFENSE_BELT * 0.58) + tangent * lateral
            if CAPITAL.inside_capital(spawn_xz):
                continue
            _spawn_siege_enemy(day, slot, String(gate.get("id", "gate")), i, spawn_xz)
    GameState.notify("Ночная тревога: у ближайших ворот началась волна %d." % (slot + 1))

func _spawn_siege_enemy(day: int, slot: int, gate_id: String, index: int, xz: Vector2) -> void:
    var enemy := CharacterBody3D.new()
    enemy.name = "Siege_%s_%02d" % [gate_id, index]
    enemy.set_script(ENEMY_SCRIPT)
    enemy.set("enemy_id", "capital_siege:%d:%d:%s:%d" % [day, slot, gate_id, index])
    enemy.set("max_health", 72.0 + float(slot) * 22.0)
    enemy.set("move_speed", 3.0 + float(slot) * 0.18)
    enemy.set("detection_range", 42.0)
    enemy.set("attack_damage", 8.0 + float(slot) * 2.0)
    enemy.global_position = Vector3(xz.x, WorldData.elevation_at(xz) + 0.9, xz.y)

    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var shape := CapsuleShape3D.new()
    shape.radius = 0.44
    shape.height = 1.8
    collision.shape = shape
    collision.position.y = 0.85
    enemy.add_child(collision)

    var mesh_node := MeshInstance3D.new()
    mesh_node.name = "Body"
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.46
    mesh.height = 1.8
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.20 + float(slot) * 0.035, 0.035, 0.045, 1.0)
    material.roughness = 0.80
    mesh.material = material
    mesh_node.mesh = mesh
    mesh_node.position.y = 0.85
    enemy.add_child(mesh_node)

    add_child(enemy)
    enemy.add_to_group("capital_siege_hostile")

func active_siege_enemy_count() -> int:
    var count := 0
    for hostile in get_tree().get_nodes_in_group("capital_siege_hostile"):
        if is_instance_valid(hostile) and not hostile.is_queued_for_deletion():
            count += 1
    return count

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
