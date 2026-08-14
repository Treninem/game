extends Node

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.json.bak"
const SAVE_VERSION := 3

func save_game(player: Node3D) -> bool:
    var payload := {
        "save_version": SAVE_VERSION,
        "player": {
            "position": [player.global_position.x, player.global_position.y, player.global_position.z],
            "rotation_y": player.rotation.y
        },
        "game_state": GameState.snapshot()
    }
    var temp_path := SAVE_PATH + ".tmp"
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        push_error("Unable to open temporary save file for writing")
        return false
    file.store_string(JSON.stringify(payload))
    file.close()
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))
        DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
    var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(SAVE_PATH))
    if err != OK:
        push_error("Unable to finalize save file")
        return false
    return true

func load_game(player: Node3D) -> bool:
    var data := _read_save(SAVE_PATH)
    if data.is_empty():
        data = _read_save(BACKUP_PATH)
        if not data.is_empty():
            GameState.notify("Основное сохранение повреждено. Загружена резервная копия.")
    if data.is_empty() or not data.has("player"):
        return false
    var p = data["player"]
    if typeof(p) != TYPE_DICTIONARY or not p.has("position") or p["position"].size() != 3:
        return false
    player.global_position = Vector3(float(p["position"][0]), float(p["position"][1]), float(p["position"][2]))
    player.rotation.y = float(p.get("rotation_y", 0.0))
    var saved_state = data.get("game_state", {})
    if typeof(saved_state) == TYPE_DICTIONARY:
        GameState.load_snapshot(saved_state)
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
