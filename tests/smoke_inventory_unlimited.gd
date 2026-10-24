extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(40.0, true, false, true).timeout.connect(func(): get_tree().quit(99))
    call_deferred("_run")

func _run() -> void:
    SettingsManager.bindings = SettingsManager.DEFAULT_BINDINGS.duplicate(true)
    SettingsManager._apply_bindings()
    SettingsManager.save_settings()
    GameState.reset_new_game()
    for index in range(137):
        GameState.add_item("qa_supply_%03d" % index, 1000000)
    GameState.add_item("short_bow", 1)
    var expected := GameState.inventory.duplicate(true)
    var before := JSON.parse_string(JSON.stringify(GameState.snapshot())) as Dictionary
    GameState.load_snapshot(before)
    assert(GameState.inventory == expected, "Large inventory changed through JSON save/load")
    var page := InventorySystem.inventory_page()
    assert(int(page.total) > 137 and page.rows.size() == 48)
    var seen := {}
    for index in range(int(page.pages)):
        for row in InventorySystem.inventory_page("", index).rows:
            assert(not seen.has(row.id), "Repeated item across pages")
            seen[row.id] = true
    var positive := 0
    for item_id in expected:
        if int(expected[item_id]) > 0:
            positive += 1
            assert(seen.has(item_id), "Inventory page hides an owned item")
    assert(seen.size() == positive, "Inventory page repeats or adds items")
    assert(InventorySystem.inventory_page("qa_supply_136").rows.size() == 1)
    assert(InventorySystem.inventory_page("  ПОХОДНЫЙ ЛУК  ").rows.size() == 1)
    assert(InventorySystem.inventory_page("no_such_item", 99).page == 0)
    assert(InventorySystem.inventory_page("", -1).page == 0)
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    var scene := packed.instantiate()
    scene.set_script(null)
    var world := scene.get_node("World")
    scene.remove_child(world)
    world.free()
    add_child(scene)
    var panels := scene.get_node("UI/GameplayPanels")
    await _key(KEY_I)
    assert(panels.visible and get_tree().paused, "I does not open/pause inventory")
    for frame in range(4):
        await get_tree().process_frame
    assert(panels.find_child("InventoryItems", true, false).get_child_count() == 48)
    assert(get_viewport().gui_get_focus_owner() == panels.find_child("InventoryItems", true, false).get_child(0), "Opening inventory does not focus its first cell")
    panels.find_child("InventoryNext", true, false).grab_focus()
    await _key(KEY_SPACE)
    for frame in range(3):
        await get_tree().process_frame
    assert(panels.inventory_page_index == 1)
    assert(get_viewport().gui_get_focus_owner() == panels.find_child("InventoryItems", true, false).get_child(0), "Page change loses inventory focus")
    var search := panels.find_child("InventorySearch", true, false) as LineEdit
    var upper_menu := scene.get_node("UI/GameMenu") as Control
    upper_menu.visible = true
    var upper_editor := LineEdit.new()
    upper_menu.add_child(upper_editor)
    upper_editor.grab_focus()
    await _key(KEY_F, true)
    assert(get_viewport().gui_get_focus_owner() == upper_editor, "Inventory search steals focus from upper menu")
    upper_menu.visible = false
    upper_editor.free()
    await _key(KEY_F, true)
    assert(get_viewport().gui_get_focus_owner() == search, "Ctrl+F does not focus inventory search")
    search.text = "ПОХОДНЫЙ ЛУК"
    await _key(KEY_ENTER)
    for frame in range(3):
        await get_tree().process_frame
    assert(panels.inventory_page_index == 0)
    assert(panels.find_child("InventoryItems", true, false).get_child_count() == 1)
    var bow_cell := panels.find_child("InventoryItems", true, false).get_child(0) as Button
    assert(bow_cell.get_meta("item_id") == "short_bow")
    bow_cell.pressed.emit()
    for frame in range(3):
        await get_tree().process_frame
    assert(panels.inventory_selected_id == "short_bow")
    var selected_cell := panels.find_child("InventoryItems", true, false).get_child(0) as Button
    assert(get_viewport().gui_get_focus_owner() == selected_cell, "Selecting a cell loses keyboard focus")
    panels._inventory_select("short_bow")
    var draft_search := panels.find_child("InventorySearch", true, false) as LineEdit
    draft_search.grab_focus()
    for frame in range(3):
        await get_tree().process_frame
    assert(get_viewport().gui_get_focus_owner() == draft_search, "Deferred selection steals search focus")
    var action := _find_button(panels.find_child("InventoryDetails", true, false), "Экипировать")
    assert(action != null, "Selected cell has no equipment action")
    action.grab_focus()
    await _key(KEY_SPACE)
    for frame in range(3):
        await get_tree().process_frame
    assert(InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == "short_bow")
    assert(get_viewport().gui_get_focus_owner() == panels.find_child("InventoryItems", true, false).get_child(0), "Equip loses cell focus")
    assert(GameState.inventory == expected, "Browsing/equipping changes quantities")
    action = _find_button(panels.find_child("InventoryDetails", true, false), "Снять")
    assert(action != null)
    action.grab_focus()
    await _key(KEY_SPACE)
    for frame in range(3):
        await get_tree().process_frame
    assert(InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON).is_empty())
    assert(get_viewport().gui_get_focus_owner() == panels.find_child("InventoryItems", true, false).get_child(0), "Unequip loses cell focus")
    GameState.add_item("berries", 1)
    var berries_before := int(GameState.inventory.berries)
    if berries_before > 1:
        assert(GameState.remove_item("berries", berries_before - 1))
    panels._inventory_search("Лесные ягоды")
    for frame in range(3):
        await get_tree().process_frame
    action = _find_button(panels.find_child("InventoryDetails", true, false), "Использовать")
    assert(action != null)
    action.grab_focus()
    await _key(KEY_SPACE)
    assert(int(GameState.inventory.berries) == 0, "Keyboard consumption did not remove exactly the last berry")
    assert(panels.inventory_selected_id.is_empty())
    assert(get_viewport().gui_get_focus_owner() == panels.find_child("InventorySearch", true, false), "Last item does not return focus to search")
    await _key(KEY_ESCAPE)
    assert(not panels.visible and not get_tree().paused, "Escape in search does not close/resume inventory")
    assert(not scene.get_node("UI/GameMenu").visible, "Escape closes inventory and also opens pause menu")
    await _key(KEY_I)
    assert(panels.visible and get_tree().paused)
    var saved_bindings := SettingsManager.bindings.duplicate(true)
    _bind("open_inventory", KEY_F10)
    assert(panels.tab_buttons.inventory.text.begins_with("[%s]" % SettingsManager.binding_text("open_inventory")), "Binding change does not refresh visible caption")
    _bind("pause_menu", KEY_F8)
    await _key(KEY_ESCAPE)
    assert(not panels.visible and not get_tree().paused, "Rebinding pause disables Escape close")
    await _key(KEY_I)
    assert(not panels.visible, "Old inventory binding still opens panel")
    await _key(KEY_F10)
    assert(panels.visible and get_tree().paused, "New inventory binding does not open panel")
    assert(panels.tab_buttons.inventory.text.begins_with("[%s]" % SettingsManager.binding_text("open_inventory")), "Inventory caption shows stale binding")
    await _key(KEY_F, true)
    await _key(KEY_F8)
    assert(not panels.visible and not get_tree().paused, "New pause binding does not close panel")
    _bind("pause_menu", KEY_P)
    await _key(KEY_F10)
    await _key(KEY_F, true)
    await _key(KEY_P, false, 112)
    assert(panels.visible and panels.find_child("InventorySearch", true, false).text == "p", "Typing pause-bound letter closes search")
    await _key(KEY_ESCAPE)
    assert(not panels.visible and not get_tree().paused)
    SettingsManager.bindings = saved_bindings
    SettingsManager._apply_bindings()
    SettingsManager.save_settings()
    await _key(KEY_I)
    assert(panels.visible and get_tree().paused)
    panels._inventory_search("no_such_item")
    for frame in range(3):
        await get_tree().process_frame
    assert(panels.inventory_selected_id.is_empty())
    assert(panels.find_child("InventoryDetails", true, false) == null, "Empty filter leaves stale actions")
    panels._inventory_search("")
    for frame in range(3):
        await get_tree().process_frame
    for cell in panels.find_child("InventoryItems", true, false).get_children():
        assert(cell is Button and cell.size.y >= 88 and cell.size.x >= 76)
    var grid := panels.find_child("InventoryItems", true, false) as GridContainer
    var target_id := String(grid.get_child(1).get_meta("item_id"))
    grid.get_child(0).pressed.emit()
    for frame in range(3):
        await get_tree().process_frame
    await _key(KEY_RIGHT)
    assert(String(get_viewport().gui_get_focus_owner().get_meta("item_id", "")) == target_id, "Arrow key does not navigate cells")
    await _key(KEY_SPACE)
    assert(panels.inventory_selected_id == target_id, "Space does not select focused cell")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("user://inventory-cells.png")
    panels._inventory_select(target_id)
    await _key(KEY_ESCAPE)
    for frame in range(3):
        await get_tree().process_frame
    assert(not get_tree().paused)
    assert(not panels.visible and get_viewport().gui_get_focus_owner() == null, "Closed inventory restores hidden focus")
    print("INVENTORY_UNLIMITED_OK kinds=%d million_stacks=true json_roundtrip=true actual_UI=true" % expected.size())
    get_tree().quit(0)

func _find_button(node: Node, text: String) -> Button:
    if node == null:
        return null
    if node is Button and node.text == text:
        return node as Button
    for child in node.get_children():
        var found := _find_button(child, text)
        if found != null:
            return found
    return null

func _key(code: Key, ctrl: bool = false, unicode: int = 0) -> void:
    var press := InputEventKey.new()
    press.keycode = code
    press.physical_keycode = code
    press.ctrl_pressed = ctrl
    press.unicode = unicode
    press.pressed = true
    Input.parse_input_event(press)
    await get_tree().process_frame
    var release := InputEventKey.new()
    release.keycode = code
    release.physical_keycode = code
    release.ctrl_pressed = ctrl
    Input.parse_input_event(release)
    for frame in range(3):
        await get_tree().process_frame

func _bind(action: String, code: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.keycode = code
    event.pressed = true
    assert(SettingsManager.rebind_action(action, event))
