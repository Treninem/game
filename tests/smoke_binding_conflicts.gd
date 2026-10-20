extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(40.0, true, false, true).timeout.connect(func(): get_tree().quit(99))
    call_deferred("_run")

func _run() -> void:
    SettingsManager.bindings = SettingsManager.DEFAULT_BINDINGS.duplicate(true)
    SettingsManager._apply_bindings()
    SettingsManager.save_settings()
    var before := SettingsManager.bindings.duplicate(true)
    var saved := FileAccess.get_file_as_bytes(SettingsManager.SETTINGS_PATH)
    var original_events := _events("open_inventory")
    var changes := [0]
    SettingsManager.bindings_changed.connect(func(): changes[0] += 1)
    if SettingsManager.rebind_action("open_inventory", _event(KEY_F9)):
        push_error("Binding conflict accepted: inventory duplicates quick_load")
        get_tree().quit(2)
        return
    assert(SettingsManager.get("last_binding_conflict") == "quick_load")
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    mouse.pressed = true
    assert(not SettingsManager.rebind_action("cast_magic", mouse))
    assert(SettingsManager.get("last_binding_conflict") == "attack")
    var echo := _event(KEY_F10)
    echo.echo = true
    assert(not SettingsManager.rebind_action("open_inventory", echo))
    assert(SettingsManager.bindings == before and _events("open_inventory") == original_events)
    assert(FileAccess.get_file_as_bytes(SettingsManager.SETTINGS_PATH) == saved and changes[0] == 0, "Rejected binding changes persisted state/signals")
    assert(SettingsManager.rebind_action("open_inventory", _event(KEY_I)), "Own binding is falsely rejected")
    var menu := preload("res://scripts/game_menu.gd").new()
    menu.add_to_group("game_menu")
    add_child(menu)
    menu.open_menu("controls")
    get_node("/root/UILayoutGuard").call("_discover")
    for frame in range(6):
        await get_tree().process_frame
    menu._begin_rebind("open_inventory")
    await _key(KEY_F9)
    assert(menu.awaiting_action == "open_inventory", "Conflict exits capture mode")
    assert(menu.rebinding_label.text.contains(menu.ACTION_LABELS.quick_load), "Conflict UI does not identify assigned action")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("user://binding-conflict.png")
    var focused_button := menu.content.find_children("*", "Button", true, false)[0] as Button
    focused_button.grab_focus()
    await _key(KEY_SPACE)
    assert(menu.awaiting_action == "open_inventory" and SettingsManager.bindings.open_inventory == before.open_inventory, "Rejected Space activates a focused button")
    assert(menu.rebinding_label.text.contains(menu.ACTION_LABELS.jump))
    await _key(KEY_F10)
    assert(menu.awaiting_action.is_empty() and int(SettingsManager.bindings.open_inventory.code) == KEY_F10)
    menu._begin_rebind("pause_menu")
    await _key(KEY_ESCAPE)
    assert(menu.awaiting_action.is_empty() and menu.visible and SettingsManager.bindings.pause_menu == before.pause_menu)
    menu.close_menu()
    assert(not get_tree().paused)
    SettingsManager.load_settings()
    assert(int(SettingsManager.bindings.open_inventory.code) == KEY_F10, "Accepted binding lost through settings reload")
    print("BINDING_CONFLICTS_OK keyboard=true mouse=true unchanged_rejection=true capture_retry=true cancel=true persisted=true")
    get_tree().quit(0)

func _event(code: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.keycode = code
    event.pressed = true
    return event

func _events(action: String) -> Array:
    return InputMap.action_get_events(action).map(func(event: InputEvent): return event.as_text())

func _key(code: Key) -> void:
    Input.parse_input_event(_event(code))
    await get_tree().process_frame
    var release := _event(code)
    release.pressed = false
    Input.parse_input_event(release)
    for frame in range(3):
        await get_tree().process_frame
