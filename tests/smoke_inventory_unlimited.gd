extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(40.0, true, false, true).timeout.connect(func(): get_tree().quit(99))
    call_deferred("_run")

func _run() -> void:
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
    panels.open_panel("inventory")
    for frame in range(4):
        await get_tree().process_frame
    assert(panels.find_child("InventoryItems", true, false).get_child_count() == 48)
    panels.find_child("InventoryNext", true, false).pressed.emit()
    for frame in range(3):
        await get_tree().process_frame
    assert(panels.inventory_page_index == 1)
    var search := panels.find_child("InventorySearch", true, false) as LineEdit
    search.text_submitted.emit("ПОХОДНЫЙ ЛУК")
    for frame in range(3):
        await get_tree().process_frame
    assert(panels.inventory_page_index == 0)
    assert(panels.find_child("InventoryItems", true, false).get_child_count() == 1)
    panels._equip("short_bow")
    for frame in range(3):
        await get_tree().process_frame
    assert(InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == "short_bow")
    assert(GameState.inventory == expected, "Browsing/equipping changes quantities")
    panels.close_panel()
    assert(not get_tree().paused)
    print("INVENTORY_UNLIMITED_OK kinds=%d million_stacks=true json_roundtrip=true actual_UI=true" % expected.size())
    get_tree().quit(0)
