extends Node

signal game_loaded(slot: int)

const SLOT_COUNT := 10
const SAVE_VERSION := 6
const LEGACY_SAVE_PATH := "user://savegame.json"

var current_slot: int = 1
var pending_new_game: bool = false
var pending_load_game: bool = false
var pending_character_profile: Dictionary = {}

func _ready() -> void:
    _migrate_legacy_save_once()

func prepare_new_game(slot: int, appearance: Dictionary = {}) -> void:
    current_slot = _valid_slot(slot)
    pending_new_game = true
    pending_load_game = false
    pending_character_profile = preload("res://scripts/character_appearance.gd").normalized(appearance)

func consume_character_profile() -> Dictionary:
    var profile := preload("res://scripts/character_appearance.gd").normalized(pending_character_profile)
    pending_character_profile = {}
    return profile

func prepare_load(slot: int) -> bool:
    slot = _valid_slot(slot)
    if not slot_exists(slot):
        return false
    current_slot = slot
    pending_new_game = false
    pending_load_game = true
    pending_character_profile = {}
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
        "world_geometry_revisions": {"capital_canals":1},
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
    var revisions:Variant=data.get("world_geometry_revisions",{})
    var revision:Variant=revisions.get("capital_canals",0) if revisions is Dictionary else 0
    if not preload("res://scripts/capital_canal_data.gd").has_current_revision(revision) and String(GameState.get_world_value("current_realm","main"))=="main" and not ProgressionSystem.is_in_dungeon():
        player.global_position=preload("res://scripts/capital_canal_data.gd").legacy_bridge_position(player.global_position)
    game_loaded.emit(slot)
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
    var timestamp = data.get("saved_at_unix", -1)
    var saved_at_unix := int(timestamp) if _is_finite_number(timestamp) else -1
    return {"slot": slot, "exists": true, "saved_at": String(data.get("saved_at", "неизвестно")), "saved_at_unix": saved_at_unix, "location": location, "world_time": "%02d:%02d" % [hour, minute], "recovered_from_backup": from_backup}

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
    file.flush()
    var write_error := file.get_error()
    file.close()
    if write_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        push_error("Unable to write complete save file")
        return false
    # Never rotate a corrupt primary over the last recoverable backup.
    var had_previous := not _read_save(path).is_empty()
    if FileAccess.file_exists(path) and not had_previous:
        var remove_invalid := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        if remove_invalid != OK:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
            return false
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
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK:
        return {}
    var parsed = json.data
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var raw_version = parsed.get("save_version", 1)
    if not _is_finite_number(raw_version) or float(raw_version) != floorf(float(raw_version)):
        return {}
    var version := int(raw_version)
    if version < 1:
        return {}
    if version > SAVE_VERSION:
        push_error("Save file is newer than this game build")
        return {}
    # Validate before choosing primary versus backup or mutating the player.
    var player_data = parsed.get("player")
    if typeof(player_data) != TYPE_DICTIONARY:
        return {}
    var position_data = player_data.get("position")
    if typeof(position_data) != TYPE_ARRAY or position_data.size() != 3:
        return {}
    for component in position_data:
        if not _is_finite_number(component):
            return {}
    if not _is_finite_number(player_data.get("rotation_y", 0.0)):
        return {}
    if typeof(parsed.get("game_state", {})) != TYPE_DICTIONARY:
        return {}
    return parsed

func _is_finite_number(value: Variant) -> bool:
    return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

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
