extends Node

# Override paths so this test never touches a player's real save slots.
class IsolatedSaveManager:
    extends "res://scripts/save_manager.gd"

    func _ready() -> void:
        pass

    func _slot_path(slot: int) -> String:
        return "user://recovery_smoke_slot_%02d.json" % slot

    func _backup_path(slot: int) -> String:
        return _slot_path(slot) + ".bak"

var _manager: IsolatedSaveManager
var _player: Node3D
var _errors: Array[String] = []

func _check(condition: bool, message: String) -> void:
    if not condition:
        _errors.append(message)
        push_error(message)

func _write(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(text)
    file.close()

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var original_state := GameState.snapshot()
    _manager = IsolatedSaveManager.new()
    add_child(_manager)
    _manager.delete_slot(1)
    _player = Node3D.new()
    add_child(_player)
    _player.position = Vector3(10, 20, 30)
    _check(_manager.save_game(_player, 1), "Initial save failed")
    _player.position = Vector3(40, 50, 60)
    _check(_manager.save_game(_player, 1), "Second save failed")
    var primary := _manager._slot_path(1)
    var backup := _manager._backup_path(1)
    var backup_text := FileAccess.get_file_as_string(backup)
    var primary_payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(primary))
    var backup_payload: Dictionary = JSON.parse_string(backup_text)
    _check(int(_manager.slot_info(1).get("saved_at_unix", -1)) == int(primary_payload["saved_at_unix"]), "Continue cannot select the latest slot without its persisted timestamp")
    _player.position = Vector3.ZERO
    _check(_manager.load_game(_player, 1), "Healthy primary failed to load")
    _check(_player.position == Vector3(40, 50, 60), "Healthy primary did not take precedence")
    var invalid_payloads: Array[String] = [
        "{truncated", "{}",
        '{"player":{"position":[1,2]}}',
        '{"player":{"position":[1,"bad",3]}}',
        '{"player":{"position":[1,2,3],"rotation_y":{}}}',
        '{"player":{"position":[1,2,3]},"game_state":[]}',
        '{"save_version":{},"player":{"position":[1,2,3]}}'
    ]
    for invalid in invalid_payloads:
        _write(primary, invalid)
        _player.position = Vector3.ZERO
        _check(_manager.slot_info(1).get("recovered_from_backup", false), "Slot metadata did not select backup")
        _check(int(_manager.slot_info(1).get("saved_at_unix", -1)) == int(backup_payload["saved_at_unix"]), "Recovered slot metadata must expose the backup timestamp")
        _check(_manager.load_game(_player, 1), "Valid backup was not loaded")
        _check(_player.position == Vector3(10, 20, 30), "Backup position was not restored")
    _check(_manager.save_game(_player, 1), "Save after recovery failed")
    _check(FileAccess.get_file_as_string(backup) == backup_text, "Corrupt primary replaced valid backup")
    _write(primary, "{}")
    _write(backup, "{}")
    _player.position = Vector3(7, 8, 9)
    _check(not _manager.load_game(_player, 1), "Two corrupt saves should fail")
    _check(_player.position == Vector3(7, 8, 9), "Failed load mutated player")
    _write(primary, '{"player":{"position":[3,4,5]}}')
    _check(_manager.load_game(_player, 1), "Legacy save without optional fields failed")
    _check(_player.position == Vector3(3, 4, 5), "Legacy position was not restored")
    _manager.delete_slot(1)
    GameState.load_snapshot(original_state)
    if _errors.is_empty():
        print("Save recovery smoke passed: malformed primary recovery, backup preservation and failed-load safety")
    get_tree().quit(0 if _errors.is_empty() else 1)
