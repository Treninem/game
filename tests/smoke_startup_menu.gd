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
    if configured_main != "res://scenes/main_menu.tscn":
        _fail(2, "project does not boot into the main menu; main_scene=%s" % configured_main)
        return

    var packed := load("res://scenes/main_menu.tscn") as PackedScene
    if packed == null:
        _fail(3, "main menu scene is missing")
        return
    var menu := packed.instantiate() as Control
    if menu == null:
        _fail(4, "main menu scene root is not a Control")
        return
    add_child(menu)
    for _i in range(4):
        await get_tree().process_frame

    if menu.get_node_or_null("World") != null:
        _fail(5, "startup menu eagerly loads the world instead of waiting for player choice")
        return

    var actions = menu.call("startup_actions")
    if not (actions is PackedStringArray):
        _fail(6, "startup menu does not expose required actions")
        return
    for expected in ["continue", "new_game", "saves", "settings", "check_updates"]:
        if not expected in actions:
            _fail(7, "startup menu is missing required action: %s" % expected)
            return

    var latest_slot := int(menu.call("latest_save_slot"))
    if bool(menu.call("continue_is_available")) != (latest_slot > 0):
        _fail(8, "Continue availability is detached from real save slots")
        return
    if bool(menu.call("continue_button_is_visible")) != (latest_slot > 0):
        _fail(9, "Continue button visibility does not follow whether a game was started")
        return

    menu.call("show_page", "saves")
    await get_tree().process_frame
    if int(menu.get("save_row_count")) != SaveManager.SLOT_COUNT:
        _fail(10, "startup save browser does not show all 10 slots")
        return

    if not bool(menu.call("settings_overlay_ready")):
        _fail(11, "startup menu does not reuse the full settings system")
        return
    menu.call("open_settings")
    for _i in range(2):
        await get_tree().process_frame
    var settings_overlay := menu.get_node_or_null("SettingsOverlay") as Control
    if settings_overlay == null or not settings_overlay.visible or not get_tree().paused:
        _fail(12, "Settings button does not open the existing settings UI")
        return
    menu.call("close_settings_overlay")
    await get_tree().process_frame
    if get_tree().paused or settings_overlay.visible:
        _fail(13, "settings overlay does not return cleanly to the startup menu")
        return

    menu.call("show_page", "updates")
    await get_tree().process_frame
    if not (menu.get("update_status_label") is Label) or not (menu.get("install_update_button") is Button):
        _fail(14, "update page is not wired to UpdateManager controls")
        return

    print("STARTUP_MENU_SMOKE_OK actions=5 saves=10 settings=reused updates=wired world=deferred")
    get_tree().quit(0)
