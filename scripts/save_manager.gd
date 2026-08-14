extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 2

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
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".bak"))
        DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_PATH + ".bak"))
    var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(SAVE_PATH))
    if err != OK:
        push_error("Unable to finalize save file")
        return false
    return true

func load_game(player: Node3D) -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var data = JSON.parse_string(file.get_as_text())
    if typeof(data) != TYPE_DICTIONARY or not data.has("player"):
        return false
    var p = data["player"]
    if not p.has("position") or p["position"].size() != 3:
        return false
    player.global_position = Vector3(float(p["position"][0]), float(p["position"][1]), float(p["position"][2]))
    player.rotation.y = float(p.get("rotation_y", 0.0))
    var saved_state = data.get("game_state", {})
    if typeof(saved_state) == TYPE_DICTIONARY:
        GameState.load_snapshot(saved_state)
    return true
