extends Node

signal status_changed(text: String, update_available: bool)
signal progress_changed(stage: String, downloaded_bytes: int, total_bytes: int, percent: float)

const STABLE_API_URL := "https://api.github.com/repos/Treninem/game/releases/tags/stable"
const SOURCE_API_URL := "https://api.github.com/repos/Treninem/game/commits/main"

var latest_tag := ""
var latest_name := ""
var update_available := false
var checking := false
var _request: HTTPRequest
var _last_bytes := -1
var _last_total := -2
var _checking_source := false

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
    var stage := "Проверка ветки main" if _checking_source else "Проверка стабильного канала"
    progress_changed.emit(stage, downloaded, total, percent)

func check_for_updates() -> void:
    if checking:
        return
    _checking_source = _is_source_checkout()
    checking = true
    update_available = false
    _last_bytes = -1
    _last_total = -2
    set_process(true)

    var url := SOURCE_API_URL if _checking_source else STABLE_API_URL
    var status := "Проверка обновлений исходников в main..." if _checking_source else "Проверка стабильного канала обновлений..."
    var progress := "Подключение к ветке main" if _checking_source else "Подключение к стабильному каналу"
    status_changed.emit(status, false)
    progress_changed.emit(progress, 0, -1, -1.0)

    var err := _request.request(url, PackedStringArray([
        "User-Agent: ImPuls-Updater/4.2",
        "Accept: application/vnd.github+json"
    ]))
    if err != OK:
        checking = false
        set_process(false)
        status_changed.emit("Не удалось начать проверку обновлений.", false)
        progress_changed.emit("Ошибка проверки", 0, -1, 0.0)

func install_latest_update() -> bool:
    if not update_available:
        status_changed.emit("Новых обновлений нет.", false)
        return false

    if _is_source_checkout():
        return await _install_source_update()

    var root := _install_root()
    var bootstrap := root.path_join("updater_bootstrap.ps1")
    var updater_v4 := root.path_join("updater_v4.ps1")
    var updater_legacy := root.path_join("updater.ps1")
    var updater := bootstrap if FileAccess.file_exists(bootstrap) else (updater_v4 if FileAccess.file_exists(updater_v4) else updater_legacy)
    if not FileAccess.file_exists(updater):
        status_changed.emit("Updater повреждён или отсутствует. Запустите последний установщик ImPuls один раз для восстановления служебных файлов.", false)
        return false

    progress_changed.emit("Запуск установщика обновления", 0, -1, -1.0)
    var args := PackedStringArray([
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", updater,
        "-InstallDir", root, "-WaitForGameExit"
    ])
    var pid := OS.create_process("powershell.exe", args, false)
    if pid <= 0:
        status_changed.emit("Не удалось запустить обновление.", false)
        progress_changed.emit("Ошибка запуска обновления", 0, -1, 0.0)
        return false

    status_changed.emit("Открыто окно обновления. Игра сейчас закроется, после проверки будет применена дельта.", true)
    await get_tree().create_timer(0.45).timeout
    get_tree().quit()
    return true

func _install_source_update() -> bool:
    var root := _source_root()
    var updater := root.path_join("installer/dev_update_bootstrap.ps1")
    if not FileAccess.file_exists(updater):
        status_changed.emit("DEBUG-updater не найден в installer/dev_update_bootstrap.ps1. Сначала получите последние файлы репозитория.", false)
        return false

    progress_changed.emit("Запуск обновления исходников", 0, -1, -1.0)
    var args := PackedStringArray([
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", updater,
        "-ProjectDir", root,
        "-GamePid", str(OS.get_process_id())
    ])
    var pid := OS.create_process("powershell.exe", args, false)
    if pid <= 0:
        status_changed.emit("Не удалось запустить DEBUG-updater.", false)
        progress_changed.emit("Ошибка запуска обновления", 0, -1, 0.0)
        return false

    status_changed.emit("DEBUG-updater запущен. После закрытия игры он безопасно обновит ветку main через Git без принудительной перезаписи локальных изменений.", true)
    await get_tree().create_timer(0.45).timeout
    get_tree().quit()
    return true

func local_build_tag() -> String:
    if _is_source_checkout():
        var source_sha := _local_git_sha()
        if not source_sha.is_empty():
            return source_sha
        return "source"

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
        var unavailable := "GitHub main сейчас недоступен. Локальный проект не изменён." if _checking_source else "Стабильный канал сейчас недоступен. Игра продолжит работать офлайн."
        status_changed.emit(unavailable, false)
        progress_changed.emit("Проверка завершилась ошибкой", downloaded, total, 0.0)
        return

    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        status_changed.emit("Получен некорректный ответ сервера обновлений.", false)
        progress_changed.emit("Некорректный ответ канала", downloaded, total, 0.0)
        return

    if _checking_source:
        _handle_source_response(parsed as Dictionary, downloaded, total)
        return

    _handle_stable_response(parsed as Dictionary, downloaded, total)

func _handle_source_response(parsed: Dictionary, downloaded: int, total: int) -> void:
    var remote_sha := String(parsed.get("sha", "")).strip_edges()
    var local_sha := _local_git_sha()
    latest_name = "main"
    latest_tag = remote_sha

    if remote_sha.is_empty():
        update_available = false
        status_changed.emit("GitHub не вернул commit ветки main.", false)
        progress_changed.emit("Проверка main завершилась ошибкой", downloaded, maxi(downloaded, total), 0.0)
        return

    update_available = local_sha.is_empty() or remote_sha != local_sha
    progress_changed.emit("Проверка ветки main завершена", downloaded, maxi(downloaded, total), 100.0)
    if update_available:
        var local_text := _short_sha(local_sha) if not local_sha.is_empty() else "не определён"
        status_changed.emit("Есть изменения исходников: %s → %s. Нажмите «Установить обновление»." % [local_text, _short_sha(remote_sha)], true)
    else:
        status_changed.emit("Исходники уже актуальны: main %s" % _short_sha(local_sha), false)

func _handle_stable_response(parsed: Dictionary, downloaded: int, total: int) -> void:
    var channel_tag := String(parsed.get("tag_name", "stable")).strip_edges()
    latest_name = String(parsed.get("name", "")).strip_edges()
    latest_tag = latest_name if not latest_name.is_empty() else channel_tag

    var local := local_build_tag()
    update_available = _is_remote_newer(local, latest_tag)
    progress_changed.emit("Проверка стабильного канала завершена", downloaded, maxi(downloaded, total), 100.0)
    if update_available:
        status_changed.emit("Доступно стабильное обновление: %s (установлено: %s)." % [latest_tag, local], true)
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
    return digits.to_int() if not digits.is_empty() else -1

func _numeric_version(value: String) -> PackedInt32Array:
    var result := PackedInt32Array()
    var current := ""
    var started := false
    for ch in value:
        if ch >= "0" and ch <= "9":
            current += ch
            started = true
        elif ch == "." and started:
            result.append(current.to_int() if not current.is_empty() else 0)
            current = ""
        elif started:
            break
    if started:
        result.append(current.to_int() if not current.is_empty() else 0)
    return result

func _compare_numeric_versions(local: String, remote: String) -> int:
    var local_parts := _numeric_version(local)
    var remote_parts := _numeric_version(remote)
    if local_parts.is_empty() or remote_parts.is_empty():
        return 0
    var count := maxi(local_parts.size(), remote_parts.size())
    for i in range(count):
        var a := local_parts[i] if i < local_parts.size() else 0
        var b := remote_parts[i] if i < remote_parts.size() else 0
        if b > a:
            return 1
        if b < a:
            return -1
    return 0

func _is_remote_newer(local: String, remote: String) -> bool:
    if remote.is_empty():
        return false
    if local.is_empty() or local == "development":
        return false

    var local_build := _build_number(local)
    var remote_build := _build_number(remote)
    if local_build >= 0 and remote_build >= 0:
        return remote_build > local_build

    var version_compare := _compare_numeric_versions(local, remote)
    if version_compare != 0:
        return version_compare > 0
    return remote != local

func _source_root() -> String:
    return ProjectSettings.globalize_path("res://").trim_suffix("/").trim_suffix("\\")

func _git_dir() -> String:
    var root := _source_root()
    var marker := root.path_join(".git")
    if DirAccess.dir_exists_absolute(marker):
        return marker
    if not FileAccess.file_exists(marker):
        return ""

    var marker_file := FileAccess.open(marker, FileAccess.READ)
    if marker_file == null:
        return ""
    var marker_text := marker_file.get_as_text().strip_edges()
    if not marker_text.begins_with("gitdir:"):
        return ""
    var path := marker_text.substr(7).strip_edges()
    if path.is_absolute_path():
        return path.simplify_path()
    return root.path_join(path).simplify_path()

func _is_source_checkout() -> bool:
    return not _git_dir().is_empty()

func _read_text_file(path: String) -> String:
    if not FileAccess.file_exists(path):
        return ""
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    return file.get_as_text().strip_edges()

func _local_git_sha() -> String:
    var git_dir := _git_dir()
    if git_dir.is_empty():
        return ""
    var head := _read_text_file(git_dir.path_join("HEAD"))
    if head.is_empty():
        return ""
    if not head.begins_with("ref:"):
        return head

    var ref_name := head.substr(4).strip_edges()
    var loose_ref := _read_text_file(git_dir.path_join(ref_name))
    if not loose_ref.is_empty():
        return loose_ref

    var packed := _read_text_file(git_dir.path_join("packed-refs"))
    if packed.is_empty():
        return ""
    for line in packed.split("\n"):
        var clean := String(line).strip_edges()
        if clean.is_empty() or clean.begins_with("#") or clean.begins_with("^"):
            continue
        var parts := clean.split(" ", false, 1)
        if parts.size() == 2 and String(parts[1]) == ref_name:
            return String(parts[0])
    return ""

func _short_sha(value: String) -> String:
    if value.is_empty():
        return "--------"
    return value.substr(0, mini(8, value.length()))

func _install_root() -> String:
    var exe_dir := OS.get_executable_path().get_base_dir()
    if exe_dir.get_file().to_lower() == "current":
        return exe_dir.get_base_dir()
    return exe_dir
