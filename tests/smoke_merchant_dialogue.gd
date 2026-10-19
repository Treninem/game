extends Node

var errors: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await get_tree().process_frame

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    await _frames(120)
    var trader := preload("res://scripts/settlement_npc.gd").new()
    trader.configure("Марта", "trader", 1, [])
    world.get_node("World").add_child(trader)
    var dialogue := world.get_node("UI/DialogueUI") as Control
    for resolution in [Vector2i(1280, 720), Vector2i(800, 450)]:
        get_tree().root.size = resolution
        trader.call("_open_shop")
        await _frames(8)
        var panel := dialogue.get("box") as PanelContainer
        var viewport := get_viewport().get_visible_rect()
        if not viewport.grow(0.5).encloses(panel.get_global_rect()):
            errors.append("Merchant panel extends beyond the viewport at %s" % resolution)
        var options := dialogue.get("options_box") as VBoxContainer
        if options.get_child_count() != 7:
            errors.append("Real merchant dialogue is missing a purchase/supply/close option")
        var scrolls := dialogue.find_children("*", "ScrollContainer", true, false)
        if not scrolls.is_empty():
            var scroll := scrolls[0] as ScrollContainer
            scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
            await _frames(4)
            var last := options.get_child(options.get_child_count() - 1) as Button
            if not viewport.grow(0.5).encloses(last.get_global_rect()):
                errors.append("Merchant close option is not reachable by scrolling at %s" % resolution)
            var horizontal := scroll.get_h_scroll_bar()
            if horizontal.max_value - horizontal.page > 1:
                errors.append("Merchant choices require horizontal scrolling")
        else:
            var last := options.get_child(options.get_child_count() - 1) as Button
            if not viewport.grow(0.5).encloses(last.get_global_rect()):
                errors.append("Merchant close option is clipped at %s" % resolution)
        if DisplayServer.get_name() != "headless":
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png("user://merchant-dialogue-%dx%d.png" % [resolution.x, resolution.y])
        var close_button := options.get_child(options.get_child_count() - 1) as Button
        close_button.emit_signal("pressed")
        await _frames(2)
        if get_tree().paused or dialogue.visible or DialogueManager.is_open:
            errors.append("Actual merchant close button does not resume gameplay")
    if errors.is_empty():
        print("MERCHANT_DIALOGUE_OK real_shop=7_choices viewport=bounded close=reachable horizontal_overflow=none sizes=1280x720,800x450")
    for error in errors:
        push_error(error)
    world.queue_free()
    await _frames(2)
    # AudioServer releases Ogg playback on its mixer thread, not on a scene
    # frame. Keep errors strict while allowing bounded asynchronous teardown.
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if errors.is_empty() else 1)
