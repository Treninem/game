extends Node

signal status_changed(text: String, update_available: bool)
signal progress_changed(stage: String, downloaded_bytes: int, total_bytes: int, percent: float)

const API_URL := "https://api.github.com/repos/Treninem/game/releases/tags/stable"

var latest_tag := ""
var latest_name := ""
var update_available := false
var checking := false
var _request: HTTPRequest
var _last_bytes := -1
var _last_total := -2

func _ready() -> void:
    _request = HTTPRequest.new()
    _request.use_threads = true
    _request.download_chunk_size = 64 * 1024
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)
    set_process(false)

func _process(_delta: float) -> void:
    if not checking or _request == null:
        return
    var downloaded := maxi(0, _request.get_downloaded_bytes())
    var total := _request.get_body_size()
    if downloaded == _last_bytes and total == _last_total:
        return
    _last_bytes = downloaded
    _last_total = total
    var percent := -1.0
    if total > 0:
        percent = clampf(float(downloaded) * 100.0 / float(total), 0.0, 100.0)
    progress_changed.emit("Проверка стабильного канала", downloaded, total, percent)

func check_for_updates() -> void:
    if checking:
        return
    checking = true
    update_available = false
    _last_bytes = -1
    _last_total = -2
    set_process(true)
    status_changed.emit("Проверка стабильного канала обновлений...", false)
    progress_changed.emit("Подключение к стабильному каналу", 0, -1, -1.0)
    var err := _request.request(API_URL, PackedStringArray(["User-Agent: ImPuls-Updater/4.1", "Accept: application/vnd.github+json"]))
    if err != OK:
        checking = false
        set_process(false)
        status_changed.emit("Не удалось начать проверку обновлений.", false)
        progress_changed.emit("Ошибка проверки", 0, -1, 0.0)

func install_latest_update() -> bool:
    if not update_available:
        status_changed.emit("Новых стабильных обновлений нет.", false)
        return false
    var root := _install_root()
    var bootstrap := root.path_join("updater_bootstrap.ps1")
    var updater_v4 := root.path_join("updater_v4.ps1")
    var updater_legacy := root.path_join("updater.ps1")
    var updater := bootstrap if FileAccess.file_exists(bootstrap) else (updater_v4 if FileAccess.file_exists(updater_v4) else updater_legacy)
    if not FileAccess.file_exists(updater):
        status_changed.emit("Updater не найден. Переустановите ImPuls последним стабильным установщиком.", false)
        return false
    progress_changed.emit("Запуск установщика обновления", 0, -1, -1.0)
    var args := PackedStringArray(["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", updater, "-InstallDir", root, "-WaitForGameExit"])
    var pid := OS.create_process("powershell.exe", args, false)
    if pid <= 0:
        status_changed.emit("Не удалось запустить обновление.", false)
        progress_changed.emit("Ошибка запуска обновления", 0, -1, 0.0)
        return false
    status_changed.emit("Открыто видимое окно обновления: реальные МБ, процент, применение дельты и проверка файлов.", true)
    await get_tree().create_timer(0.45).timeout
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
    var downloaded := body.size()
    var total := _request.get_body_size() if _request != null else downloaded
    checking = false
    set_process(false)
    if response_code != 200:
        status_changed.emit("Стабильный канал сейчас недоступен. Игра продолжит работать офлайн.", false)
        progress_changed.emit("Проверка завершилась ошибкой", downloaded, total, 0.0)
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        status_changed.emit("Получен некорректный ответ сервера обновлений.", false)
        progress_changed.emit("Некорректный ответ канала", downloaded, total, 0.0)
        return
    latest_tag = String(parsed.get("tag_name", "stable"))
    latest_name = String(parsed.get("name", ""))
    var local := local_build_tag()
    update_available = _is_remote_newer(local, latest_tag)
    progress_changed.emit("Проверка стабильного канала завершена", downloaded, maxi(downloaded, total), 100.0)
    if update_available:
        status_changed.emit("Доступно стабильное обновление: %s (установлено: %s). Будет загружена только дельта." % [latest_tag, local], true)
    else:
        status_changed.emit("Установлена последняя стабильная версия: %s" % local, false)

func _build_number(value: String) -> int:
    var pos := value.find("build-")
    if pos < 0:
        return -1
    var tail := value.substr(pos + 6)
    var digits := ""
    for ch in tail:
        if ch >= "0" and ch <= "9":
            digits += ch
        else:
            break
    return int(digits) if not digits.is_empty() else -1

func _is_remote_newer(local: String, remote: String) -> bool:
    if remote.is_empty():
        return false
    var local_build := _build_number(local)
    var remote_build := _build_number(remote)
    if local_build >= 0 and remote_build >= 0:
        return remote_build > local_build
    return remote != local and local != "development"

func _install_root() -> String:
    var exe_dir := OS.get_executable_path().get_base_dir()
    if exe_dir.get_file().to_lower() == "current":
        return exe_dir.get_base_dir()
    return exe_dir
