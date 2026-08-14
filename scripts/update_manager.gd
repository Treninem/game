extends Node

signal status_changed(text: String, update_available: bool)

const API_URL := "https://api.github.com/repos/Treninem/game/releases/latest"

var latest_tag := ""
var latest_name := ""
var update_available := false
var checking := false
var _request: HTTPRequest

func _ready() -> void:
    _request = HTTPRequest.new()
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func check_for_updates() -> void:
    if checking:
        return
    checking = true
    update_available = false
    status_changed.emit("Проверка обновлений...", false)
    var err := _request.request(API_URL, PackedStringArray(["User-Agent: ImPuls-Updater/1.0", "Accept: application/vnd.github+json"]))
    if err != OK:
        checking = false
        status_changed.emit("Не удалось начать проверку обновлений.", false)

func install_latest_update() -> bool:
    if not update_available:
        status_changed.emit("Новых обновлений нет.", false)
        return false
    var root := _install_root()
    var updater := root.path_join("updater.ps1")
    if not FileAccess.file_exists(updater):
        status_changed.emit("Updater не найден. Переустановите ImPuls последним установщиком.", false)
        return false
    var args := PackedStringArray([
        "-NoProfile",
        "-WindowStyle", "Hidden",
        "-ExecutionPolicy", "Bypass",
        "-File", updater,
        "-InstallDir", root,
        "-WaitForGameExit"
    ])
    var pid := OS.create_process("powershell.exe", args, false)
    if pid <= 0:
        status_changed.emit("Не удалось запустить обновление.", false)
        return false
    status_changed.emit("Обновление запускается. Игра будет закрыта и обновлена.", true)
    await get_tree().create_timer(0.35).timeout
    get_tree().quit()
    return true

func local_build_tag() -> String:
    var tag_path := _install_root().path_join("release_tag.txt")
    if FileAccess.file_exists(tag_path):
        var file := FileAccess.open(tag_path, FileAccess.READ)
        if file != null:
            return file.get_as_text().strip_edges()
    return String(ProjectSettings.get_setting("application/config/version", "development"))

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    checking = false
    if response_code != 200:
        status_changed.emit("Проверка обновлений недоступна. Игра продолжит работать офлайн.", false)
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        status_changed.emit("Получен некорректный ответ сервера обновлений.", false)
        return
    latest_tag = String(parsed.get("tag_name", ""))
    latest_name = String(parsed.get("name", latest_tag))
    var local := local_build_tag()
    update_available = _is_remote_newer(local, latest_tag)
    if update_available:
        status_changed.emit("Доступно обновление: %s (установлено: %s)" % [latest_tag, local], true)
    else:
        status_changed.emit("Установлена последняя версия: %s" % local, false)

func _is_remote_newer(local: String, remote: String) -> bool:
    if remote.is_empty():
        return false
    if local.begins_with("build-") and remote.begins_with("build-"):
        return int(remote.trim_prefix("build-")) > int(local.trim_prefix("build-"))
    return remote != local and local != "development"

func _install_root() -> String:
    var exe_dir := OS.get_executable_path().get_base_dir()
    if exe_dir.get_file().to_lower() == "current":
        return exe_dir.get_base_dir()
    return exe_dir
