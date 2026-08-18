extends Node

const SLOT_COUNT := 10
const SAVE_VERSION := 5
const LEGACY_SAVE_PATH := "user://savegame.json"

var current_slot: int = 1
var pending_new_game: bool = false
var pending_load_game: bool = false

func _ready() -> void:
    _migrate_legacy_save_once()

func prepare_new_game(slot: int) -> void:
    current_slot = _valid_slot(slot)
    pending_new_game = true
    pending_load_game = false

func prepare_load(slot: int) -> bool:
    slot = _valid_slot(slot)
    if not slot_exists(slot):
        return false
    current_slot = slot
    pending_new_game = false
    pending_load_game = true
    return true

func consume_new_game_request() -> bool:
    var value := pending_new_game
    pending_new_game = false
    return value

func consume_load_request() -> bool:
    var value := pending_load_game
    pending_load_game = false
    return value

func save_game(player: Node3D, slot: int = -1) -> bool:
    slot = current_slot if slot < 1 else _valid_slot(slot)
    current_slot = slot
    var payload := {
        "save_version": SAVE_VERSION,
        "slot": slot,
        "saved_at_unix": int(Time.get_unix_time_from_system()),
        "saved_at": Time.get_datetime_string_from_system(false, true),
        "player": {"position": [player.global_position.x, player.global_position.y, player.global_position.z], "rotation_y": player.rotation.y},
        "game_state": GameState.snapshot()
    }
    return _write_atomic(_slot_path(slot), _backup_path(slot), payload)

func load_game(player: Node3D, slot: int = -1) -> bool:
    slot = current_slot if slot < 1 else _valid_slot(slot)
    current_slot = slot
    var data := _read_save(_slot_path(slot))
    if data.is_empty():
        data = _read_save(_backup_path(slot))
        if not data.is_empty():
            GameState.notify("Основное сохранение слота %d повреждено. Загружена резервная копия." % slot)
    if data.is_empty() or not data.has("player"):
        return false
    var p = data["player"]
    if typeof(p) != TYPE_DICTIONARY or not p.has("position") or typeof(p["position"]) != TYPE_ARRAY or p["position"].size() != 3:
        return false
    player.global_position = Vector3(float(p["position"][0]), float(p["position"][1]), float(p["position"][2]))
    player.rotation.y = float(p.get("rotation_y", 0.0))
    var saved_state = data.get("game_state", {})
    if typeof(saved_state) == TYPE_DICTIONARY:
        GameState.load_snapshot(saved_state)
    return true

func delete_slot(slot: int) -> bool:
    slot = _valid_slot(slot)
    var removed := false
    for path in [_slot_path(slot), _backup_path(slot), _slot_path(slot) + ".tmp"]:
        if FileAccess.file_exists(path):
            var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
            removed = removed or err == OK
    return removed

func slot_exists(slot: int) -> bool:
    slot = _valid_slot(slot)
    return FileAccess.file_exists(_slot_path(slot)) or FileAccess.file_exists(_backup_path(slot))

func slot_info(slot: int) -> Dictionary:
    slot = _valid_slot(slot)
    var data := _read_save(_slot_path(slot))
    var from_backup := false
    if data.is_empty():
        data = _read_save(_backup_path(slot))
        from_backup = not data.is_empty()
    if data.is_empty():
        return {"slot": slot, "exists": false}
    var state = data.get("game_state", {})
    var world_minutes := float(state.get("world_minutes", 0.0)) if typeof(state) == TYPE_DICTIONARY else 0.0
    var hour := int(world_minutes / 60.0) % 24
    var minute := int(world_minutes) % 60
    var location := String(state.get("current_location", "неизвестная локация")) if typeof(state) == TYPE_DICTIONARY else "неизвестная локация"
    return {"slot": slot, "exists": true, "saved_at": String(data.get("saved_at", "неизвестно")), "location": location, "world_time": "%02d:%02d" % [hour, minute], "recovered_from_backup": from_backup}

func list_slots() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for slot in range(1, SLOT_COUNT + 1):
        result.append(slot_info(slot))
    return result

func first_used_slot() -> int:
    for slot in range(1, SLOT_COUNT + 1):
        if slot_exists(slot):
            return slot
    return 0

func first_free_slot() -> int:
    for slot in range(1, SLOT_COUNT + 1):
        if not slot_exists(slot):
            return slot
    return 0

func _write_atomic(path: String, backup_path: String, payload: Dictionary) -> bool:
    var temp_path := path + ".tmp"
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        push_error("Unable to open temporary save file for writing")
        return false
    file.store_string(JSON.stringify(payload))
    file.close()
    var had_previous := FileAccess.file_exists(path)
    if had_previous:
        if FileAccess.file_exists(backup_path):
            var backup_remove := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
            if backup_remove != OK:
                DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
                push_error("Unable to replace previous save backup")
                return false
        var move_old := DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path))
        if move_old != OK:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
            push_error("Unable to protect previous save before writing new save")
            return false
    var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))
    if err != OK:
        if had_previous and not FileAccess.file_exists(path) and FileAccess.file_exists(backup_path):
            DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        push_error("Unable to finalize save file")
        return false
    return true

func _read_save(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var version := int(parsed.get("save_version", 1))
    if version > SAVE_VERSION:
        push_error("Save file is newer than this game build")
        return {}
    return parsed

func _migrate_legacy_save_once() -> void:
    if not FileAccess.file_exists(LEGACY_SAVE_PATH) or slot_exists(1):
        return
    var legacy := _read_save(LEGACY_SAVE_PATH)
    if legacy.is_empty():
        return
    legacy["save_version"] = SAVE_VERSION
    legacy["slot"] = 1
    legacy["saved_at_unix"] = int(Time.get_unix_time_from_system())
    legacy["saved_at"] = Time.get_datetime_string_from_system(false, true)
    _write_atomic(_slot_path(1), _backup_path(1), legacy)

func _slot_path(slot: int) -> String:
    return "user://save_slot_%02d.json" % slot

func _backup_path(slot: int) -> String:
    return "user://save_slot_%02d.json.bak" % slot

func _valid_slot(slot: int) -> int:
    return clampi(slot, 1, SLOT_COUNT)
