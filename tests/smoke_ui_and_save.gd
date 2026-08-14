extends SceneTree

func _initialize() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=UI layout smoke::%s" % clean)
    push_error("UI smoke: %s" % message)
    quit(code)

func _frame_error(frame: Control, available: Vector2, label: String) -> String:
    if frame.size.x > available.x + 1.0 or frame.size.y > available.y + 1.0:
        return "%s exceeds viewport; frame_size=%s available=%s" % [label, frame.size, available]
    if frame.position.x < -1.0 or frame.position.y < -1.0:
        return "%s has negative drift; position=%s size=%s available=%s" % [label, frame.position, frame.size, available]
    if frame.position.x + frame.size.x > available.x + 1.0 or frame.position.y + frame.size.y > available.y + 1.0:
        return "%s extends outside viewport; position=%s size=%s available=%s" % [label, frame.position, frame.size, available]
    var expected := ((available - frame.size) * 0.5).floor()
    if frame.position.distance_to(expected) > 2.0:
        return "%s is not centered; got=%s expected=%s size=%s available=%s" % [label, frame.position, expected, frame.size, available]
    return ""

func _sidebar_error(menu: Control, frame: Control) -> String:
    var sidebar_value = menu.get("sidebar")
    if not (sidebar_value is VBoxContainer):
        return "sidebar missing"
    var sidebar := sidebar_value as VBoxContainer
    var sidebar_min := sidebar.get_combined_minimum_size()
    if sidebar_min.y > frame.size.y - 12.0:
        return "sidebar minimum height overflows frame; sidebar_min=%s frame_size=%s" % [sidebar_min, frame.size]
    return ""

func _run_test() -> void:
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "stage scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _i in range(10):
        await process_frame

    var menu := scene.get_node_or_null("UI/GameMenu") as Control
    var panels := scene.get_node_or_null("UI/GameplayPanels") as Control
    if menu == null or panels == null:
        _fail(3, "menu nodes missing")
        return
    if root.get_node_or_null("UILayoutGuard") == null:
        _fail(13, "centralized UI layout guard is not loaded")
        return

    menu.open_menu("main")
    for _i in range(5):
        await process_frame
    if not paused or not menu.visible:
        _fail(4, "pause menu did not pause/show")
        return
    var frame = menu.get("frame") as Control
    if frame == null:
        _fail(5, "pause frame missing")
        return
    var error := _frame_error(frame, menu.size, "pause menu")
    if not error.is_empty():
        _fail(6, error)
        return
    error = _sidebar_error(menu, frame)
    if not error.is_empty():
        _fail(14, error)
        return
    menu.close_menu()
    await process_frame
    if paused or menu.visible:
        _fail(7, "pause menu did not restore gameplay")
        return

    panels.open_panel("inventory")
    for _i in range(5):
        await process_frame
    if not paused or not panels.visible:
        _fail(8, "gameplay panel failed to open")
        return
    var panel_frame = panels.get("frame") as Control
    if panel_frame == null:
        _fail(9, "gameplay panel frame missing")
        return
    error = _frame_error(panel_frame, panels.size, "gameplay panel")
    if not error.is_empty():
        _fail(9, error)
        return
    panels.close_panel()
    await process_frame
    if paused or panels.visible:
        _fail(10, "gameplay panel did not restore gameplay")
        return

    # Maximum supported UI scale used to reintroduce the offset/overflow bug.
    SettingsManager.set_value("graphics", "ui_scale", 1.5)
    for _i in range(8):
        await process_frame

    menu.open_menu("updates")
    for _i in range(8):
        await process_frame
    frame = menu.get("frame") as Control
    if frame == null:
        _fail(12, "150 percent pause frame missing")
        return
    error = _frame_error(frame, menu.size, "150 percent pause menu")
    if not error.is_empty():
        _fail(12, error)
        return
    error = _sidebar_error(menu, frame)
    if not error.is_empty():
        _fail(15, "150 percent %s" % error)
        return
    menu.close_menu()
    await process_frame

    panels.open_panel("map")
    for _i in range(8):
        await process_frame
    panel_frame = panels.get("frame") as Control
    if panel_frame == null:
        _fail(16, "150 percent gameplay panel frame missing")
        return
    error = _frame_error(panel_frame, panels.size, "150 percent gameplay panel")
    if not error.is_empty():
        _fail(16, error)
        return
    panels.close_panel()
    SettingsManager.set_value("graphics", "ui_scale", 1.0)
    for _i in range(4):
        await process_frame

    if SaveManager.list_slots().size() != 10:
        _fail(11, "save slot count regressed; count=%s" % SaveManager.list_slots().size())
        return

    print("UI smoke passed: centralized auto-alignment, 150% UI scaling and 10 save slots are stable")
    quit(0)
