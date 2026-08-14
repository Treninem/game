extends SceneTree

func _initialize() -> void:
    call_deferred("_run_test")

func _run_test() -> void:
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        push_error("UI smoke: stage scene missing")
        quit(2)
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _i in range(8):
        await process_frame

    var menu := scene.get_node_or_null("UI/GameMenu") as Control
    var panels := scene.get_node_or_null("UI/GameplayPanels") as Control
    if menu == null or panels == null:
        push_error("UI smoke: menu nodes missing")
        quit(3)
        return

    menu.open_menu("main")
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
    var vp := root.get_viewport().get_visible_rect().size
    if frame.size.x > vp.x + 1.0 or frame.size.y > vp.y + 1.0:
        push_error("UI smoke: pause menu exceeds viewport")
        quit(6)
        return
    menu.close_menu()
    await process_frame
    if paused or menu.visible:
        push_error("UI smoke: pause menu did not restore gameplay")
        quit(7)
        return

    panels.open_panel("inventory")
    await process_frame
    if not paused or not panels.visible:
        push_error("UI smoke: gameplay panel failed to open")
        quit(8)
        return
    var panel_frame = panels.get("frame") as Control
    if panel_frame == null or panel_frame.size.x > vp.x + 1.0 or panel_frame.size.y > vp.y + 1.0:
        push_error("UI smoke: gameplay panel exceeds viewport")
        quit(9)
        return
    panels.close_panel()
    await process_frame
    if paused or panels.visible:
        push_error("UI smoke: gameplay panel did not restore gameplay")
        quit(10)
        return

    if SaveManager.list_slots().size() != 10:
        push_error("UI smoke: save slot count regressed")
        quit(11)
        return

    print("UI smoke passed: pause, gameplay panels and 10 save slots are stable")
    quit(0)
