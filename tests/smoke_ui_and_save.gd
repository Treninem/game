extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_test")

func _checkpoint(text: String) -> void:
    print("UI_SMOKE_CHECKPOINT: ", text)

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=UI layout smoke::%s" % clean)
    push_error("UI smoke: %s" % message)
    get_tree().quit(code)

func _frame_error(frame: Control, available: Vector2, label: String) -> String:
    var render_scale := Vector2(absf(frame.scale.x), absf(frame.scale.y))
    if render_scale.x <= 0.0 or render_scale.y <= 0.0:
        return "%s has invalid render scale; scale=%s" % [label, frame.scale]
    var visual_size := frame.size * render_scale
    if visual_size.x > available.x + 1.0 or visual_size.y > available.y + 1.0:
        return "%s exceeds viewport; visual_size=%s frame_size=%s scale=%s available=%s" % [label, visual_size, frame.size, frame.scale, available]
    if frame.position.x < -1.0 or frame.position.y < -1.0:
        return "%s has negative drift; position=%s visual_size=%s available=%s" % [label, frame.position, visual_size, available]
    if frame.position.x + visual_size.x > available.x + 1.0 or frame.position.y + visual_size.y > available.y + 1.0:
        return "%s extends outside viewport; position=%s visual_size=%s available=%s" % [label, frame.position, visual_size, available]
    var expected := ((available - visual_size) * 0.5).floor()
    if frame.position.distance_to(expected) > 2.0:
        return "%s is not centered; got=%s expected=%s visual_size=%s frame_size=%s scale=%s available=%s" % [label, frame.position, expected, visual_size, frame.size, frame.scale, available]
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

func _remove_world_workload(scene: Node) -> void:
    # World boot and traversal have their own mandatory smoke tests. Keeping the
    # real UI nodes but removing World/Bootstrap makes this test deterministic
    # and prevents chunk streaming from masking UI regressions behind long CI runs.
    for path in ["Bootstrap", "World"]:
        var node := scene.get_node_or_null(path)
        if node != null:
            scene.remove_child(node)
            node.free()

func _run_test() -> void:
    var tree := get_tree()
    _checkpoint("start")
    var settings_manager := get_node_or_null("/root/SettingsManager")
    var save_manager := get_node_or_null("/root/SaveManager")
    var layout_guard := get_node_or_null("/root/UILayoutGuard")
    if settings_manager == null or save_manager == null or layout_guard == null:
        _fail(13, "required autoload nodes are missing from normal project tree")
        return

    settings_manager.call("set_value", "graphics", "ui_scale", 1.0)
    for _i in range(4):
        await tree.process_frame
    _checkpoint("ui-scale-baseline-restored")

    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "stage scene missing")
        return
    var scene := packed.instantiate()
    _remove_world_workload(scene)
    tree.root.add_child(scene)
    _checkpoint("stage-ui-instantiated")
    for _i in range(6):
        await tree.process_frame
    _checkpoint("stage-ui-warmup-complete")

    var menu := scene.get_node_or_null("UI/GameMenu") as Control
    var panels := scene.get_node_or_null("UI/GameplayPanels") as Control
    if menu == null or panels == null:
        _fail(3, "menu nodes missing")
        return

    _checkpoint("opening-pause-main")
    menu.call("open_menu", "main")
    for _i in range(4):
        await tree.process_frame
    _checkpoint("pause-main-settled")
    if not tree.paused or not menu.visible:
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
    menu.call("close_menu")
    await tree.process_frame
    if tree.paused or menu.visible:
        _fail(7, "pause menu did not restore gameplay")
        return

    _checkpoint("opening-inventory")
    panels.call("open_panel", "inventory")
    for _i in range(4):
        await tree.process_frame
    _checkpoint("inventory-settled")
    if not tree.paused or not panels.visible:
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
    panels.call("close_panel")
    await tree.process_frame
    if tree.paused or panels.visible:
        _fail(10, "gameplay panel did not restore gameplay")
        return

    _checkpoint("setting-ui-scale-150")
    settings_manager.call("set_value", "graphics", "ui_scale", 1.5)
    for _i in range(6):
        await tree.process_frame
    _checkpoint("ui-scale-150-settled")

    _checkpoint("opening-updates-150")
    menu.call("open_menu", "updates")
    for _i in range(6):
        await tree.process_frame
    _checkpoint("updates-150-settled")
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
    menu.call("close_menu")
    await tree.process_frame

    _checkpoint("opening-map-150")
    panels.call("open_panel", "map")
    for _i in range(6):
        await tree.process_frame
    _checkpoint("map-150-settled")
    panel_frame = panels.get("frame") as Control
    if panel_frame == null:
        _fail(16, "150 percent gameplay panel frame missing")
        return
    error = _frame_error(panel_frame, panels.size, "150 percent gameplay panel")
    if not error.is_empty():
        _fail(16, error)
        return
    panels.call("close_panel")
    settings_manager.call("set_value", "graphics", "ui_scale", 1.0)
    for _i in range(3):
        await tree.process_frame

    var slots = save_manager.call("list_slots")
    if not (slots is Array) or slots.size() != 10:
        var count := slots.size() if slots is Array else -1
        _fail(11, "save slot count regressed; count=%s" % count)
        return

    _checkpoint("passed")
    print("UI smoke passed: rendered bounds stay centered, 150% UI scaling adapts safely, and 10 save slots are stable")
    tree.quit(0)
