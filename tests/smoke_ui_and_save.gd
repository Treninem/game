extends SceneTree

func _initialize() -> void:
    call_deferred("_run_test")

func _frame_is_inside_and_centered(frame: Control, available: Vector2, label: String) -> bool:
    if frame.size.x > available.x + 1.0 or frame.size.y > available.y + 1.0:
        push_error("UI smoke: %s exceeds viewport" % label)
        return false
    if frame.position.x < -1.0 or frame.position.y < -1.0:
        push_error("UI smoke: %s has negative drift: %s" % [label, frame.position])
        return false
    if frame.position.x + frame.size.x > available.x + 1.0 or frame.position.y + frame.size.y > available.y + 1.0:
        push_error("UI smoke: %s extends outside viewport" % label)
        return false
    var expected := ((available - frame.size) * 0.5).floor()
    if frame.position.distance_to(expected) > 2.0:
        push_error("UI smoke: %s is not centered. got=%s expected=%s" % [label, frame.position, expected])
        return false
    return true

func _sidebar_fits(menu: Control, frame: Control) -> bool:
    var sidebar_value = menu.get("sidebar")
    if not (sidebar_value is VBoxContainer):
        push_error("UI smoke: sidebar missing")
        return false
    var sidebar := sidebar_value as VBoxContainer
    var sidebar_min := sidebar.get_combined_minimum_size()
    if sidebar_min.y > frame.size.y - 12.0:
        push_error("UI smoke: sidebar minimum height overflows frame: %s > %s" % [sidebar_min.y, frame.size.y])
        return false
    return true

func _run_test() -> void:
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        push_error("UI smoke: stage scene missing")
        quit(2)
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _i in range(10):
        await process_frame

    var menu := scene.get_node_or_null("UI/GameMenu") as Control
    var panels := scene.get_node_or_null("UI/GameplayPanels") as Control
    if menu == null or panels == null:
        push_error("UI smoke: menu nodes missing")
        quit(3)
        return
    if root.get_node_or_null("UILayoutGuard") == null:
        push_error("UI smoke: centralized UI layout guard is not loaded")
        quit(13)
        return

    menu.open_menu("main")
    for _i in range(4):
        await process_frame
    if not paused or not menu.visible:
        push_error("UI smoke: pause menu did not pause/show")
        quit(4)
        return
    var frame = menu.get("frame") as Control
    if frame == null:
        push_error("UI smoke: pause frame missing")
        quit(5)
        return
    if not _frame_is_inside_and_centered(frame, menu.size, "pause menu"):
        quit(6)
        return
    if not _sidebar_fits(menu, frame):
        quit(14)
        return
    menu.close_menu()
    await process_frame
    if paused or menu.visible:
        push_error("UI smoke: pause menu did not restore gameplay")
        quit(7)
        return

    panels.open_panel("inventory")
    for _i in range(4):
        await process_frame
    if not paused or not panels.visible:
        push_error("UI smoke: gameplay panel failed to open")
        quit(8)
        return
    var panel_frame = panels.get("frame") as Control
    if panel_frame == null or not _frame_is_inside_and_centered(panel_frame, panels.size, "gameplay panel"):
        quit(9)
        return
    panels.close_panel()
    await process_frame
    if paused or panels.visible:
        push_error("UI smoke: gameplay panel did not restore gameplay")
        quit(10)
        return

    # Maximum supported UI scale used to reintroduce the offset/overflow bug.
    # Force 150%, open both menu families and prove the guard realigns them.
    SettingsManager.set_value("graphics", "ui_scale", 1.5)
    for _i in range(6):
        await process_frame

    menu.open_menu("updates")
    for _i in range(5):
        await process_frame
    frame = menu.get("frame") as Control
    if frame == null or not _frame_is_inside_and_centered(frame, menu.size, "150 percent pause menu"):
        quit(12)
        return
    if not _sidebar_fits(menu, frame):
        quit(15)
        return
    menu.close_menu()
    await process_frame

    panels.open_panel("map")
    for _i in range(5):
        await process_frame
    panel_frame = panels.get("frame") as Control
    if panel_frame == null or not _frame_is_inside_and_centered(panel_frame, panels.size, "150 percent gameplay panel"):
        quit(16)
        return
    panels.close_panel()
    SettingsManager.set_value("graphics", "ui_scale", 1.0)
    for _i in range(3):
        await process_frame

    if SaveManager.list_slots().size() != 10:
        push_error("UI smoke: save slot count regressed")
        quit(11)
        return

    print("UI smoke passed: centralized auto-alignment, 150% UI scaling and 10 save slots are stable")
    quit(0)
