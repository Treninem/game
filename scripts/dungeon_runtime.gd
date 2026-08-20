extends Node3D

const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const INSTANCE_XZ := Vector2(24500.0, -24500.0)
const ARENA_SIZE := Vector2(34.0, 34.0)
const FLOOR_THICKNESS := 1.2
const WALL_HEIGHT := 5.0
const PLAYER_CLEARANCE := 1.2

var player: CharacterBody3D
var instance_root: Node3D
var return_position := Vector3.ZERO
var return_position_valid := false
var active_floor := 0
var current_run_id := ""
var transition_pending := false
var victory_delay := 0.0

func _ready() -> void:
    add_to_group("dungeon_runtime")
    process_priority = 5
    ProgressionSystem.dungeon_requested.connect(_on_dungeon_requested)
    ProgressionSystem.dungeon_exit_requested.connect(_on_dungeon_exit_requested)
    call_deferred("_recover_from_saved_run")

func _process(delta: float) -> void:
    _resolve_player()
    if not bool(ProgressionSystem.snapshot().get("in_dungeon", false)):
        return
    if transition_pending:
        return
    if instance_root == null or not is_instance_valid(instance_root):
        return
    var living := _living_dungeon_hostiles()
    if living > 0:
        victory_delay = 0.0
        return
    victory_delay += delta
    if victory_delay < 0.7:
        return
    victory_delay = 0.0
    transition_pending = true
    ProgressionSystem.set_combat_active(false)
    var result := ProgressionSystem.dungeon_floor_victory()
    if not bool(result.get("ok", false)):
        transition_pending = false
        return
    if bool(result.get("completed", false)):
        return
    var run: Dictionary = result.get("run", {})
    active_floor = int(run.get("current_floor", active_floor + 1))
    _build_floor(run)
    transition_pending = false

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _recover_from_saved_run() -> void:
    _resolve_player()
    var state := ProgressionSystem.snapshot()
    if not bool(state.get("in_dungeon", false)):
        return
    var run: Dictionary = state.get("dungeon_run", {})
    if run.is_empty():
        ProgressionSystem.fail_dungeon(false)
        return
    current_run_id = String(run.get("id", "recovered"))
    active_floor = int(run.get("current_floor", 1))
    return_position = _safe_world_return_position()
    return_position_valid = true
    _build_floor(run)

func _on_dungeon_requested(run: Dictionary) -> void:
    _resolve_player()
    if player == null:
        ProgressionSystem.fail_dungeon(false)
        return
    return_position = player.global_position
    return_position_valid = true
    current_run_id = String(run.get("id", "dungeon"))
    active_floor = int(run.get("current_floor", 1))
    transition_pending = false
    victory_delay = 0.0
    _build_floor(run)

func _on_dungeon_exit_requested(_result: Dictionary) -> void:
    ProgressionSystem.set_combat_active(false)
    _clear_instance()
    _resolve_player()
    if player == null:
        return
    var target := return_position if return_position_valid else _safe_world_return_position()
    player.global_position = target
    player.velocity = Vector3.ZERO
    if player.has_method("prepare_for_streamed_surface"):
        player.call("prepare_for_streamed_surface", false)
    elif player.has_method("_begin_ground_guard"):
        player.call("_begin_ground_guard", false)
    current_run_id = ""
    active_floor = 0
    return_position_valid = false
    transition_pending = false

func abort_current_dungeon() -> void:
    if bool(ProgressionSystem.snapshot().get("in_dungeon", false)):
        ProgressionSystem.fail_dungeon(false)

func _build_floor(run: Dictionary) -> void:
    _clear_instance()
    _resolve_player()
    if player == null:
        return
    instance_root = Node3D.new()
    instance_root.name = "DungeonInstance_%s_%02d" % [current_run_id.replace("-", "_"), active_floor]
    add_child(instance_root)

    var base_y := WorldData.elevation_at(INSTANCE_XZ) + 12.0
    instance_root.global_position = Vector3(INSTANCE_XZ.x, base_y, INSTANCE_XZ.y)
    _add_static_box("ArenaFloor", Vector3(ARENA_SIZE.x, FLOOR_THICKNESS, ARENA_SIZE.y), Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0), Color(0.12, 0.13, 0.16), instance_root)
    _add_static_box("WallNorth", Vector3(ARENA_SIZE.x, WALL_HEIGHT, 1.0), Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_SIZE.y * 0.5), Color(0.16, 0.17, 0.20), instance_root)
    _add_static_box("WallSouth", Vector3(ARENA_SIZE.x, WALL_HEIGHT, 1.0), Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_SIZE.y * 0.5), Color(0.16, 0.17, 0.20), instance_root)
    _add_static_box("WallWest", Vector3(1.0, WALL_HEIGHT, ARENA_SIZE.y), Vector3(-ARENA_SIZE.x * 0.5, WALL_HEIGHT * 0.5, 0.0), Color(0.16, 0.17, 0.20), instance_root)
    _add_static_box("WallEast", Vector3(1.0, WALL_HEIGHT, ARENA_SIZE.y), Vector3(ARENA_SIZE.x * 0.5, WALL_HEIGHT * 0.5, 0.0), Color(0.16, 0.17, 0.20), instance_root)

    var floor_count := int(run.get("floor_count", 5))
    var boss_floor := int(run.get("boss_floor", floor_count))
    var rank_id := String(run.get("rank", "H"))
    var rank_index := maxi(0, ProgressionSystem.rank_index(rank_id))
    var is_boss := active_floor >= boss_floor
    var enemy_count := 2 + mini(6, active_floor / 2 + rank_index / 2)
    if is_boss:
        enemy_count = maxi(1, mini(4, 1 + rank_index / 4))
    _spawn_floor_enemies(enemy_count, rank_index, is_boss)

    if int(run.get("hidden_floor", -1)) == active_floor:
        _add_hidden_floor_marker(instance_root)

    var entry := instance_root.global_position + Vector3(0.0, PLAYER_CLEARANCE, ARENA_SIZE.y * 0.32)
    player.global_position = entry
    player.velocity = Vector3.ZERO
    if player.has_method("set_dungeon_mode"):
        player.call("set_dungeon_mode", true)
    ProgressionSystem.set_combat_active(true)
    GameState.set_location("Подземелье %s • этаж %d/%d" % [String(run.get("name", "")), active_floor, floor_count])
    GameState.notify("Этаж %d/%d • победите всех противников." % [active_floor, floor_count])

func _spawn_floor_enemies(count: int, rank_index: int, boss_floor: bool) -> void:
    var radius := 8.0
    for i in range(maxi(1, count)):
        var angle := TAU * float(i) / float(maxi(1, count))
        var pos := Vector3(cos(angle) * radius, 1.0, sin(angle) * radius - 3.0)
        var is_boss := boss_floor and i == 0
        _spawn_enemy(i, pos, rank_index, is_boss)

func _spawn_enemy(index: int, local_pos: Vector3, rank_index: int, boss: bool) -> void:
    var enemy := CharacterBody3D.new()
    enemy.name = "DungeonBoss" if boss else "DungeonEnemy_%02d" % index
    enemy.set_script(ENEMY_SCRIPT)
    enemy.set("enemy_id", "dungeon:%s:%d:%d" % [current_run_id, active_floor, index])
    var scale_factor := 1.0 + float(rank_index) * 0.16 + float(active_floor - 1) * 0.06
    if boss:
        scale_factor *= 2.4
    enemy.set("max_health", 70.0 * scale_factor)
    enemy.set("move_speed", clampf(2.8 + float(rank_index) * 0.08, 2.8, 4.2))
    enemy.set("attack_damage", 6.0 + float(rank_index) * 1.5 + (10.0 if boss else 0.0))
    enemy.set("detection_range", 40.0)
    enemy.position = local_pos

    var shape_node := CollisionShape3D.new()
    shape_node.name = "CollisionShape3D"
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.55 if boss else 0.42
    capsule.height = 2.4 if boss else 1.75
    shape_node.shape = capsule
    shape_node.position.y = 1.1 if boss else 0.82
    enemy.add_child(shape_node)

    var mesh_node := MeshInstance3D.new()
    mesh_node.name = "Body"
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.58 if boss else 0.44
    mesh.height = 2.4 if boss else 1.75
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.30, 0.04, 0.05) if boss else Color(0.14, 0.17, 0.22)
    material.metallic = 0.15
    material.roughness = 0.72
    mesh.material = material
    mesh_node.mesh = mesh
    mesh_node.position.y = 1.1 if boss else 0.82
    enemy.add_child(mesh_node)

    instance_root.add_child(enemy)
    enemy.add_to_group("dungeon_hostile")
    if boss:
        enemy.add_to_group("dungeon_boss")

func _living_dungeon_hostiles() -> int:
    if instance_root == null:
        return 0
    var count := 0
    for node in get_tree().get_nodes_in_group("dungeon_hostile"):
        if is_instance_valid(node) and instance_root.is_ancestor_of(node) and not node.is_queued_for_deletion():
            count += 1
    return count

func _add_hidden_floor_marker(parent: Node3D) -> void:
    var marker := MeshInstance3D.new()
    marker.name = "HiddenFloorSeal"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 1.1
    mesh.bottom_radius = 1.1
    mesh.height = 0.18
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.72, 0.88, 1.0)
    material.emission_enabled = true
    material.emission = Color(0.04, 0.42, 0.70, 1.0)
    material.emission_energy_multiplier = 2.0
    mesh.material = material
    marker.mesh = mesh
    marker.position = Vector3(0.0, 0.12, 0.0)
    parent.add_child(marker)

func _add_static_box(node_name: String, size: Vector3, position: Vector3, color: Color, parent: Node3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = position
    parent.add_child(body)

    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.92
    mesh.material = material
    mesh_node.mesh = mesh
    body.add_child(mesh_node)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _clear_instance() -> void:
    if instance_root != null and is_instance_valid(instance_root):
        instance_root.queue_free()
    instance_root = null
    for node in get_tree().get_nodes_in_group("dungeon_hostile"):
        if is_instance_valid(node) and node.is_queued_for_deletion() == false and String(node.get("enemy_id") if node.get("enemy_id") != null else "").begins_with("dungeon:"):
            node.queue_free()

func _safe_world_return_position() -> Vector3:
    var xz := Vector2(65.0, 48.0)
    return Vector3(xz.x, WorldData.elevation_at(xz) + 0.08, xz.y)
