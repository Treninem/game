extends "res://tests/smoke_ui_and_save.gd"

func _run_test() -> void:
    var tree := get_tree()
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "stage scene missing")
        return
    var scene := packed.instantiate()
    _remove_world_workload(scene)
    tree.root.add_child(scene)
    var menu := scene.get_node("UI/GameMenu") as Control
    var panels := scene.get_node("UI/GameplayPanels") as Control
    var original_size := tree.root.size
    var original_scale_size := tree.root.content_scale_size
    var original_ui_scale := float(SettingsManager.get_value("graphics", "ui_scale"))
    for resolution in [Vector2i(800, 600), Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
        for ui_scale in [1.0, 1.5]:
            SettingsManager.set_value("graphics", "ui_scale", ui_scale)
            tree.root.size = resolution
            tree.root.content_scale_size = resolution
            for _i in range(6):
                await tree.process_frame
            var viewport_size := tree.root.get_visible_rect().size
            var expected_logical_size: Vector2 = Vector2(resolution) / float(ui_scale)
            if viewport_size.distance_to(expected_logical_size) > 1.0:
                _fail(18, "viewport did not resize to %s; got %s" % [resolution, viewport_size])
                return
            for section in ["main", "saves", "settings", "controls", "graphics", "audio", "other", "updates"]:
                menu.call("open_menu", section)
                for _i in range(4):
                    await tree.process_frame
                var frame := menu.get("frame") as Control
                var error := _frame_error(frame, viewport_size, "%s/%s/%s" % [resolution, ui_scale, section])
                if error.is_empty():
                    error = _sidebar_error(menu, frame)
                if error.is_empty():
                    var menu_content := menu.get("content") as Control
                    var scroll := menu_content.get_parent().get_parent() as ScrollContainer
                    var bar := scroll.get_h_scroll_bar()
                    if bar.max_value - bar.page > 1.0:
                        error = "%s/%s/%s needs horizontal scrolling; overflow=%s" % [resolution, ui_scale, section, bar.max_value - bar.page]
                if not error.is_empty():
                    _fail(19, error)
                    return
                menu.call("close_menu")
            for section in ["inventory", "map", "crafting", "journal"]:
                panels.call("open_panel", section)
                for _i in range(4):
                    await tree.process_frame
                var error := _frame_error(panels.get("frame") as Control, viewport_size, "%s/%s/%s" % [resolution, ui_scale, section])
                if not error.is_empty():
                    _fail(20, error)
                    return
                panels.call("close_panel")
            if tree.paused or menu.visible or panels.visible:
                _fail(21, "closing overlays did not restore gameplay")
                return
            print("RESPONSIVE_UI_OK resolution=%s scale=%s sections=12" % [resolution, ui_scale])
    SettingsManager.set_value("graphics", "ui_scale", original_ui_scale)
    tree.root.size = original_size
    tree.root.content_scale_size = original_scale_size
    _finished = true
    print("RESPONSIVE_UI_SMOKE_OK combinations=8 menu_and_panel_checks=96")
    tree.quit(0)
