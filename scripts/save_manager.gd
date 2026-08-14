extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

func save_game(player: Node3D) -> bool:
    var payload := {
        "save_version": SAVE_VERSION,
        "player": {
            "position": [player.global_position.x, player.global_position.y, player.global_position.z],
            "rotation_y": player.rotation.y
        }
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Unable to open save file for writing")
        return false
    file.store_string(JSON.stringify(payload))
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
    return true
