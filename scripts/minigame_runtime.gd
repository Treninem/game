extends Node

const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const ARENA_DURATION := 45.0
const RACE_DURATION := 35.0
const RUNE_DURATION := 18.0

var player: CharacterBody3D
var active_id := ""
var elapsed := 0.0
var target_score := 0
var challenge_root: Node3D
var overlay: CanvasLayer
var overlay_label: Label
var race_points: Array[Vector3] = []
var race_index := 0
var rune_sequence: Array[String] = []
var rune_index := 0
var start_position := Vector3.ZERO
var previous_pause := false

func _ready() -> void:
    add_to_group("minigame_runtime")
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_resolve_player")

func _process(delta: float) -> void:
    if active_id.is_empty():
        return
    _resolve_player()
    if player == null:
        _finish(0, "Испытание остановлено: игрок недоступен.")
        return
    if active_id == "rune_puzzle" or not get_tree().paused:
        elapsed += delta
    _update_overlay()
    if GameState.is_dead:
        _finish(0, "Испытание прервано поражением.")
        return
    match active_id:
        "arena_trial": _process_arena()
        "courier_race": _process_race()
        "rune_puzzle": _process_runes()
    if not active_id.is_empty() and elapsed >= _duration_for(active_id):
        _finish(_partial_score(), "Время испытания истекло.")

func _unhandled_input(event: InputEvent) -> void:
    if active_id != "rune_puzzle" or not event.is_pressed():
        return
    if event is InputEventKey and (event as InputEventKey).echo:
        return
    var token := ""
    if event.is_action_pressed("move_forward"):
        token = "W"
    elif event.is_action_pressed("move_left"):
        token = "A"
    elif event.is_action_pressed("move_back"):
        token = "S"
    elif event.is_action_pressed("move_right"):
        token = "D"
    if token.is_empty() or rune_sequence.is_empty():
        return
    get_viewport().set_input_as_handled()
    if rune_index < rune_sequence.size() and token == rune_sequence[rune_index]:
        rune_index += 1
        if rune_index >= rune_sequence.size():
            var score := target_score + maxi(0, int((RUNE_DURATION - elapsed) * 24.0))
            _finish(score, "Рунная последовательность решена.")
    else:
        rune_index = 0
        GameState.notify("Руна сбилась — последовательность начинается заново.")

func start_minigame(minigame_id: String) -> bool:
    if not active_id.is_empty() or bool(ProgressionSystem.snapshot().get("in_dungeon", false)):
        return false
    var definition := _definition(minigame_id)
    if definition.is_empty():
        return false
    _resolve_player()
    if player == null:
        return false
    active_id = minigame_id
    elapsed = 0.0
    target_score = int(definition.get("target", 0))
    start_position = player.global_position
    previous_pause = get_tree().paused
    _build_overlay(String(definition.get("name", minigame_id)))
    match active_id:
        "arena_trial": _start_arena()
        "courier_race": _start_race()
        "rune_puzzle": _start_runes()
        _:
            _finish(0, "Неизвестное испытание.")
            return false
    return true

func cancel_active() -> void:
    if not active_id.is_empty():
        _finish(0, "Испытание отменено.")

func is_active() -> bool:
    return not active_id.is_empty()

func _start_arena() -> void:
    get_tree().paused = false
    ProgressionSystem.set_combat_active(true)
    challenge_root = Node3D.new()
    challenge_root.name = "ArenaTrial"
    get_tree().current_scene.add_child(challenge_root)
    var offsets := [Vector3(7, 0, 0), Vector3(-7, 0, 0), Vector3(0, 0, 7), Vector3(0, 0, -7), Vector3(10, 0, 6)]
    for i in range(offsets.size()):
        _spawn_arena_enemy(i, start_position + offsets[i])
    GameState.notify("Испытание арены: победите всех противников до конца времени.")

func _process_arena() -> void:
    var living := 0
    for node in get_tree().get_nodes_in_group("minigame_hostile"):
        if is_instance_valid(node) and not node.is_queued_for_deletion():
            living += 1
    if living == 0:
        var score := target_score + maxi(0, int((ARENA_DURATION - elapsed) * 12.0))
        _finish(score, "Испытание арены завершено.")

func _spawn_arena_enemy(index: int, pos: Vector3) -> void:
    var enemy := CharacterBody3D.new()
    enemy.name = "ArenaEnemy_%02d" % index
    enemy.set_script(ENEMY_SCRIPT)
    enemy.set("enemy_id", "minigame:arena:%d:%d" % [int(Time.get_ticks_msec()), index])
    enemy.set("max_health", 55.0 + float(index) * 7.0)
    enemy.set("move_speed", 3.0)
    enemy.set("detection_range", 38.0)
    enemy.set("attack_damage", 5.0 + float(index))
    var xz := Vector2(pos.x, pos.z)
    enemy.global_position = Vector3(pos.x, WorldData.elevation_at(xz) + 0.9, pos.z)
    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.75
    collision.shape = shape
    collision.position.y = 0.82
    enemy.add_child(collision)
    var mesh_node := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.44
    mesh.height = 1.75
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.28, 0.12, 0.05)
    material.roughness = 0.78
    mesh.material = material
    mesh_node.mesh = mesh
    mesh_node.position.y = 0.82
    enemy.add_child(mesh_node)
    challenge_root.add_child(enemy)
    enemy.add_to_group("minigame_hostile")

func _start_race() -> void:
    get_tree().paused = false
    race_index = 0
    race_points.clear()
    challenge_root = Node3D.new()
    challenge_root.name = "CourierRace"
    get_tree().current_scene.add_child(challenge_root)
    var offsets := [Vector3(18, 0, 0), Vector3(30, 0, -14), Vector3(12, 0, -28), Vector3(-12, 0, -20), Vector3(-22, 0, 2), Vector3(0, 0, 14)]
    for offset in offsets:
        var raw := start_position + offset
        var xz := Vector2(raw.x, raw.z)
        race_points.append(Vector3(raw.x, WorldData.elevation_at(xz) + 0.25, raw.z))
    _build_race_markers()
    GameState.notify("Гонка курьеров: пройдите все световые контрольные точки по порядку.")

func _process_race() -> void:
    if race_index >= race_points.size():
        var score := target_score + maxi(0, int((RACE_DURATION - elapsed) * 18.0))
        _finish(score, "Маршрут курьера завершён.")
        return
    if player.global_position.distance_to(race_points[race_index]) <= 3.0:
        var marker := challenge_root.get_node_or_null("Checkpoint_%02d" % race_index)
        if marker != null:
            marker.queue_free()
        race_index += 1
        if race_index >= race_points.size():
            var score := target_score + maxi(0, int((RACE_DURATION - elapsed) * 18.0))
            _finish(score, "Маршрут курьера завершён.")

func _build_race_markers() -> void:
    for i in range(race_points.size()):
        var marker := MeshInstance3D.new()
        marker.name = "Checkpoint_%02d" % i
        var mesh := CylinderMesh.new()
        mesh.top_radius = 1.2
        mesh.bottom_radius = 1.2
        mesh.height = 0.18
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.05, 0.60, 0.88, 0.72)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.emission_enabled = true
        material.emission = Color(0.02, 0.35, 0.82)
        material.emission_energy_multiplier = 2.0
        mesh.material = material
        marker.mesh = mesh
        marker.global_position = race_points[i]
        challenge_root.add_child(marker)

func _start_runes() -> void:
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    rune_index = 0
    rune_sequence = ["W", "D", "A", "S", "W", "A", "D", "S"]
    var rotation := posmod(int(Time.get_ticks_msec() / 1000), rune_sequence.size())
    for _i in range(rotation):
        rune_sequence.append(rune_sequence.pop_front())
    GameState.notify("Рунная головоломка: повторите показанную последовательность клавиш WASD.")

func _process_runes() -> void:
    pass

func _partial_score() -> int:
    match active_id:
        "arena_trial":
            var living := 0
            for node in get_tree().get_nodes_in_group("minigame_hostile"):
                if is_instance_valid(node) and not node.is_queued_for_deletion():
                    living += 1
            return maxi(0, target_score - living * 160)
        "courier_race":
            return int(float(target_score) * float(race_index) / maxf(1.0, float(race_points.size())))
        "rune_puzzle":
            return int(float(target_score) * float(rune_index) / maxf(1.0, float(rune_sequence.size())))
    return 0

func _finish(score: int, message: String) -> void:
    var finished_id := active_id
    if finished_id.is_empty():
        return
    active_id = ""
    ProgressionSystem.set_combat_active(false)
    if challenge_root != null and is_instance_valid(challenge_root):
        challenge_root.queue_free()
    challenge_root = null
    if overlay != null and is_instance_valid(overlay):
        overlay.queue_free()
    overlay = null
    overlay_label = null
    race_points.clear()
    rune_sequence.clear()
    get_tree().paused = previous_pause
    if not previous_pause:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var result := ProgressionSystem.finish_minigame(finished_id, maxi(0, score))
    GameState.notify("%s Результат: %d • награда: %d монет." % [message, maxi(0, score), int(result.get("reward", 0))])

func _definition(id: String) -> Dictionary:
    for row in ProgressionSystem.minigame_catalog():
        if String(row.get("id", "")) == id:
            return row
    return {}

func _duration_for(id: String) -> float:
    match id:
        "arena_trial": return ARENA_DURATION
        "courier_race": return RACE_DURATION
        "rune_puzzle": return RUNE_DURATION
    return 1.0

func _build_overlay(title: String) -> void:
    overlay = CanvasLayer.new()
    overlay.name = "MinigameOverlay"
    overlay.layer = 80
    overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene.add_child(overlay)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
    panel.position = Vector2(-260, 24)
    panel.size = Vector2(520, 110)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.01, 0.02, 0.035, 0.94)
    style.border_color = Color(0.10, 0.52, 0.72, 0.94)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", style)
    overlay.add_child(panel)
    overlay_label = Label.new()
    overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_label.add_theme_font_size_override("font_size", 16)
    overlay_label.text = title
    panel.add_child(overlay_label)

func _update_overlay() -> void:
    if overlay_label == null:
        return
    var remaining := maxi(0, int(ceil(_duration_for(active_id) - elapsed)))
    match active_id:
        "arena_trial":
            var living := 0
            for node in get_tree().get_nodes_in_group("minigame_hostile"):
                if is_instance_valid(node) and not node.is_queued_for_deletion():
                    living += 1
            overlay_label.text = "ИСПЫТАНИЕ АРЕНЫ\nПротивников: %d • время: %d с" % [living, remaining]
        "courier_race":
            overlay_label.text = "ГОНКА КУРЬЕРОВ\nТочка %d/%d • время: %d с" % [mini(race_index + 1, race_points.size()), race_points.size(), remaining]
        "rune_puzzle":
            var sequence := " ".join(PackedStringArray(rune_sequence))
            overlay_label.text = "РУННАЯ ГОЛОВОЛОМКА\n%s\nВерно: %d/%d • время: %d с" % [sequence, rune_index, rune_sequence.size(), remaining]

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
