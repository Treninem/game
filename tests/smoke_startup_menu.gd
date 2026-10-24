extends Node

var failed := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    push_error("Startup menu smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var configured_main := String(ProjectSettings.get_setting("application/run/main_scene", ""))
    if configured_main != "res://scenes/boot_launcher.tscn":
        _fail(2, "project does not boot through the non-blocking launcher; main_scene=%s" % configured_main)
        return

    var boot_packed := load("res://scenes/boot_launcher.tscn") as PackedScene
    if boot_packed == null:
        _fail(3, "boot launcher scene is missing")
        return
    var boot := boot_packed.instantiate() as Control
    if boot == null:
        _fail(4, "boot launcher root is not a Control")
        return
    add_child(boot)
    var deadline := Time.get_ticks_msec() + 15000
    while Time.get_ticks_msec() < deadline:
        var current := get_tree().current_scene
        if current != null and current.name == "MainMenu":
            break
        await get_tree().process_frame

    var menu := get_tree().current_scene as Control
    if menu == null or menu.name != "MainMenu":
        _fail(6, "boot launcher did not open the main menu within 15 seconds")
        return
    for _i in range(4):
        await get_tree().process_frame

    if menu.get_node_or_null("World") != null:
        _fail(7, "startup menu eagerly loads the world instead of waiting for player choice")
        return

    var actions = menu.call("startup_actions")
    if not (actions is PackedStringArray):
        _fail(8, "startup menu does not expose required actions")
        return
    for expected in ["continue", "new_game", "saves", "settings", "check_updates"]:
        if not expected in actions:
            _fail(9, "startup menu is missing required action: %s" % expected)
            return
    if String(menu.call("world_loading_scene")) != "res://scenes/world_loading.tscn":
        _fail(23, "gameplay actions bypass the mandatory loading screen")
        return
    if not ResourceLoader.exists("res://scenes/world_loading.tscn"):
        _fail(24, "world loading scene is missing")
        return

    var latest_slot := int(menu.call("latest_save_slot"))
    if bool(menu.call("continue_is_available")) != (latest_slot > 0):
        _fail(10, "Continue availability is detached from real save slots")
        return
    if bool(menu.call("continue_button_is_visible")) != (latest_slot > 0):
        _fail(11, "Continue button visibility does not follow whether a game was started")
        return

    var menu_music := menu.get_node_or_null("MenuMusic") as AudioStreamPlayer
    if menu_music == null or menu_music.stream == null:
        _fail(15, "startup menu has no real music stream")
        return
    var music_path := String(menu_music.stream.resource_path)
    if not music_path.begins_with("res://assets/audio/music/production/"):
        _fail(16, "menu music is not a production audio asset: %s" % music_path)
        return
    if "source_packs" in music_path or "assets/staging" in music_path:
        _fail(17, "menu runtime depends on a staging/source-pack music path")
        return
    if menu_music.bus != "Music" or not bool(menu_music.call("uses_music_bus")):
        _fail(18, "menu music bypasses the Music settings bus")
        return
    if not menu_music.autoplay:
        _fail(19, "menu music is not configured to autoplay")
        return
    if menu_music.process_mode != Node.PROCESS_MODE_ALWAYS:
        _fail(20, "menu music would pause while the settings overlay pauses the scene tree")
        return
    if not bool(menu_music.call("loop_enabled")):
        _fail(21, "menu music stream is not looped")
        return

    menu.call("show_page", "saves")
    await get_tree().process_frame
    if int(menu.get("save_row_count")) != SaveManager.SLOT_COUNT:
        _fail(12, "startup save browser does not show all 10 slots")
        return

    if not bool(menu.call("settings_overlay_ready")):
        _fail(13, "startup menu does not reuse the full settings system")
        return
    menu.call("open_settings")
    for _i in range(2):
        await get_tree().process_frame
    var settings_overlay := menu.get_node_or_null("SettingsOverlay") as Control
    if settings_overlay == null or not settings_overlay.visible or not get_tree().paused:
        _fail(14, "Settings button does not open the existing settings UI")
        return
    menu.call("close_settings_overlay")
    await get_tree().process_frame
    if get_tree().paused or settings_overlay.visible:
        _fail(15, "settings overlay does not return cleanly to the startup menu")
        return

    menu.call("show_page", "updates")
    await get_tree().process_frame
    if not (menu.get("update_status_label") is Label) or not (menu.get("install_update_button") is Button):
        _fail(16, "update page is not wired to UpdateManager controls")
        return
    if not (menu.get("update_progress_bar") is ProgressBar) or not UpdateManager.has_signal("progress_changed"):
        _fail(25, "update page has no real progress channel")
        return

    menu.call("show_page", "home")
    var original_size := get_viewport().get_visible_rect().size
    for logical_size in [Vector2i(853,480), Vector2i(640,360)]:
        get_tree().root.content_scale_size = logical_size
        menu.call("_layout_ui")
        for _i in range(4):
            await get_tree().process_frame
        var frame := menu.get("frame") as Control
        var viewport_rect := menu.get_viewport_rect()
        if frame.get_global_rect().end.y > viewport_rect.end.y + 2.0:
            _fail(26, "startup menu extends below the viewport with large UI text")
            return
        var scroll := menu.get("menu_scroll") as ScrollContainer
        var column := menu.get("menu_column") as VBoxContainer
        var exit_button := column.get_child(column.get_child_count() - 1) as Button
        scroll.ensure_control_visible(exit_button)
        for _i in range(3):
            await get_tree().process_frame
        if exit_button.get_global_rect().end.y > scroll.get_global_rect().end.y + 2.0:
            _fail(27, "startup exit action cannot be reached at large UI scale")
            return
    get_tree().root.content_scale_size = Vector2i(original_size)
    print("STARTUP_MENU_SMOKE_OK boot=non-blocking menu=first loading=mandatory updates=byte-progress saves=10 settings=reused music=production-looped responsive=scrollable")
    menu.queue_free()
    # Let the audio server retire playback before checking shutdown for leaks.
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0)
