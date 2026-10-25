extends SceneTree

var results: Array = []

func _initialize() -> void:
    _run.call_deferred()

func _settle() -> void:
    for frame in range(6):
        await process_frame

func _key(code: Key, unicode: int = 0) -> void:
    var press := InputEventKey.new()
    press.keycode = code
    press.physical_keycode = code
    press.unicode = unicode
    press.pressed = true
    Input.parse_input_event(press)
    await process_frame
    var release := InputEventKey.new()
    release.keycode = code
    release.physical_keycode = code
    Input.parse_input_event(release)
    await _settle()

func _run() -> void:
    var settings := root.get_node("SettingsManager")
    var game := root.get_node("GameState")
    settings.bindings = settings.DEFAULT_BINDINGS.duplicate(true)
    settings._apply_bindings()
    game.reset_new_game()
    results.append({"case": "default_inventory_caption_exposes_both_shortcuts", "expected": true, "actual": settings.binding_text("open_inventory").contains("Tab") and settings.binding_text("open_inventory").contains("I")})
    var before: Dictionary = game.inventory.duplicate(true)
    var before_coins := int(game.coins)
    var stage := Node.new()
    stage.name = "UIInputAudit"
    root.add_child(stage)
    current_scene = stage
    var menu: Control = load("res://scripts/game_menu.gd").new()
    menu.add_to_group("game_menu")
    stage.add_child(menu)
    var panels: Control = load("res://scripts/gameplay_panels.gd").new()
    panels.add_to_group("gameplay_panels")
    stage.add_child(panels)
    await _settle()
    await _key(KEY_TAB)
    results.append({"case": "default_tab_opens_inventory", "expected": true, "actual": panels.visible})
    if panels.visible:
        panels.close_panel()
    await _key(KEY_I)
    results.append({"case": "default_I_opens_inventory", "expected": true, "actual": panels.visible})
    if panels.visible:
        await _key(KEY_TAB)
        results.append({"case": "default_tab_closes_inventory_from_focused_cell", "expected": true, "actual": not panels.visible})
    panels.close_panel()
    var event := InputEventKey.new()
    event.keycode = KEY_P
    event.physical_keycode = KEY_P
    event.pressed = true
    assert(settings.rebind_action("pause_menu", event))
    panels.open_panel("inventory")
    await _settle()
    var search := panels.find_child("InventorySearch", true, false) as LineEdit
    assert(search != null)
    search.grab_focus()
    search.text = ""
    await _key(KEY_P, 112)
    results.append({"case": "pause_bound_letter_types_in_search_without_guard", "expected": true, "actual": panels.visible and search.text == "p"})
    panels.close_panel()
    var guard: Node = load("res://scripts/runtime_stability_guard.gd").new()
    stage.add_child(guard)
    panels.open_panel("inventory")
    await _settle()
    search = panels.find_child("InventorySearch", true, false) as LineEdit
    search.text = ""
    search.grab_focus()
    await _key(KEY_P, 112)
    results.append({"case": "pause_bound_letter_types_in_search_with_actual_guard", "expected": true, "actual": panels.visible and search.text == "p", "panel_visible": panels.visible, "search": search.text})
    if panels.visible:
        panels.close_panel()
    await _key(KEY_P, 112)
    results.append({"case": "rebound_pause_opens_menu_outside_text", "expected": true, "actual": menu.visible and paused})
    if menu.visible:
        menu.close_menu()
    event = InputEventKey.new()
    event.keycode = KEY_TAB
    event.physical_keycode = KEY_TAB
    event.pressed = true
    assert(settings.rebind_action("pause_menu", event))
    await _key(KEY_TAB)
    results.append({"case": "explicit_tab_pause_binding_takes_priority_over_alias", "expected": true, "actual": menu.visible and not panels.visible})
    if menu.visible:
        menu.close_menu()
    settings.bindings = settings.DEFAULT_BINDINGS.duplicate(true)
    settings._apply_bindings()
    await _key(KEY_TAB)
    results.append({"case": "default_tab_alias_returns_after_default_bindings", "expected": true, "actual": panels.visible})
    if panels.visible:
        panels.close_panel()
    results.append({"case": "inventory_unchanged", "expected": true, "actual": game.inventory == before})
    results.append({"case": "coins_unchanged", "expected": true, "actual": int(game.coins) == before_coins})
    var file := FileAccess.open("user://editor-ui-input-audit.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"source_sha": "711edb0dc5ee39e6b4b0d3b3a1d2db46535a0df9", "cases": results, "headless": true, "manual_play": false, "private_server_proposal": true, "root_runtime_changed": false}, "  "))
    file.close()
    print("EDITOR_UI_INPUT_AUDIT ", JSON.stringify(results))
    paused = false
    stage.queue_free()
    await _settle()
    var failed := false
    for result: Dictionary in results:
        failed = failed or result.actual != result.expected
    quit(1 if failed else 0)
