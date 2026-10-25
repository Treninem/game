extends SceneTree

var records: Array = []

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int) -> void:
    for index in range(count):
        await RenderingServer.frame_post_draw

func _run() -> void:
    await process_frame
    root.get_node("GameState").reset_new_game()
    var state := root.get_node("GameState")
    var inventory_system := root.get_node("InventorySystem")
    for item in inventory_system.ITEMS:
        state.add_item(item, 3)
    var original_inventory: Dictionary = state.inventory.duplicate(true)
    var original_coins: int = state.coins
    var scene: Node = load("res://scenes/stage1.tscn").instantiate()
    scene.set_script(null)
    var world := scene.get_node("World")
    scene.remove_child(world)
    world.free()
    root.add_child(scene)
    var panels: Control = scene.get_node("UI/GameplayPanels")
    var menu: Control = scene.get_node("UI/GameMenu")
    menu.visible = false
    panels.open_panel("inventory")
    for size: Vector2i in [Vector2i(1280,720), Vector2i(960,540), Vector2i(1920,1080)]:
        root.size = size
        await _frames(8)
        panels._inventory_search("")
        panels._inventory_select("short_bow")
        await _frames(8)
        var grid: GridContainer = panels.find_child("InventoryItems", true, false)
        var details: GridContainer = panels.find_child("InventoryDetails", true, false)
        var scroll: ScrollContainer = panels.find_child("InventoryGridScroll", true, false)
        var layout: BoxContainer = panels.find_child("InventoryLayout", true, false)
        assert(grid != null and grid.get_child_count() == original_inventory.size())
        assert(scroll.follow_focus and scroll.mouse_force_pass_scroll_events == false)
        var picture := root.get_texture().get_image()
        var filename := "inventory-models-%dx%d.png" % [size.x,size.y]
        assert(picture.save_png("user://"+filename) == OK)
        var frame: Control = panels.frame
        # Compare rendered pixel coordinates, including the production canvas
        # stretch transform, against the actual captured image dimensions.
        var bounds := frame.get_viewport_transform() * frame.get_global_transform() * Rect2(Vector2.ZERO, frame.size)
        var pixels := picture.get_size()
        print("INVENTORY_RENDERED_BOUNDS ", size, " image=", pixels, " bounds=", bounds)
        assert(bounds.position.x >= -1 and bounds.position.y >= -1 and bounds.end.x <= pixels.x + 1 and bounds.end.y <= pixels.y + 1, "Inventory frame leaves the actual viewport")
        for cell: Button in grid.get_children():
            var caption := cell.get_node("ItemCaption") as Label
            assert(not caption.text.is_empty() and caption.size.y >= 24)
            assert(caption.position.y >= 0 and caption.get_rect().end.y <= cell.size.y, "Item name is outside its visible cell")
        if not layout.vertical:
            assert(scroll.get_global_rect().end.x <= details.get_global_rect().position.x, "Grid overlaps selected item")
        var preview: TextureRect = panels.find_child("SelectedItemModel", true, false)
        assert(preview != null and preview.get_meta("production_model") == "res://assets/production/weapons/settler_equipment/Bow_Wooden.gltf", "Inventory must display the authored production bow")
        var texture_pixels := _verify_preview(preview)
        assert(texture_pixels > 100, "Actual bow model preview is blank")
        records.append({"size":str(size),"columns":grid.columns,"compact":layout.vertical,"grid_scroll_size":str(scroll.size),"frame":str(bounds),"bow_nontransparent_pixels":texture_pixels,"file":filename})
    # Actual production models, including the arrow, not replacement drawings.
    for item: String in ["starter_axe","stone_knife","short_bow","arrow"]:
        panels._inventory_select(item)
        await _frames(6)
        var preview: TextureRect = panels.find_child("SelectedItemModel", true, false)
        assert(preview != null and _verify_preview(preview)>30)
        assert(preview.get_meta("production_model") == load("res://scripts/weapon_model_catalog.gd").scene_for(item).resource_path, "Item preview differs from its live catalog model")
        assert(preview.texture.get_image().save_png("user://item-model-"+item+".png") == OK)
    var catalog: Script = load("res://scripts/weapon_model_catalog.gd")
    var humanoid: Script = load("res://scripts/humanoid_visual.gd")
    assert(catalog.SCENES == humanoid.WEAPONS, "Inventory and held-weapon model authorities diverge")
    assert(state.inventory == original_inventory and state.coins == original_coins, "Preview or layout changes inventory/currency")
    panels.close_panel()
    var file := FileAccess.open("user://inventory-presentation.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"source_sha":OS.get_environment("GITHUB_SHA"),"cases":records,"actual_model_ids":["starter_axe","stone_knife","short_bow","arrow"],"one_shot_previews":true,"inventory_and_currency_unchanged":true,"fixture":"Actual stage1 UI and models with world pruned. Existing unmodified unlimited-inventory keyboard/save test is a separate required step.","manual_play":false,"full_visual_acceptance":false},"  "))
    file.close()
    print("INVENTORY_PRESENTATION_REVIEW_OK ",JSON.stringify(records))
    quit(0)

func _verify_preview(preview: TextureRect) -> int:
    var viewport: SubViewport = preview.render_view
    assert(viewport.own_world_3d and viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Static inventory model keeps rendering")
    assert(viewport.size == Vector2i(256,192))
    var picture := preview.texture.get_image()
    var opaque := 0
    for y in range(picture.get_height()):
        for x in range(picture.get_width()):
            var color := picture.get_pixel(x,y)
            if color.a > .5 and (color.r + color.g + color.b) > .05:
                opaque += 1
    return opaque
