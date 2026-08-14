extends SceneTree

func _initialize() -> void:
    call_deferred("_run_test")

func _run_test() -> void:
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        push_error("Boot smoke: stage scene missing")
        quit(2)
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _i in range(12):
        await process_frame

    var player := scene.get_node_or_null("World/Player") as CharacterBody3D
    var camera := scene.get_node_or_null("World/Player/CameraPivot/Camera3D") as Camera3D
    var env_host := scene.get_node_or_null("World/WorldEnvironmentController")
    var hud := scene.get_node_or_null("UI/HUD") as Control
    var pause_menu := scene.get_node_or_null("UI/GameMenu") as Control
    var gameplay_panels := scene.get_node_or_null("UI/GameplayPanels") as Control

    if player == null or camera == null or env_host == null or hud == null:
        push_error("Boot smoke: mandatory world nodes missing")
        quit(3)
        return
    if camera.far < 900.0:
        push_error("Boot smoke: camera view distance regressed")
        quit(4)
        return
    if pause_menu == null or gameplay_panels == null or pause_menu.visible or gameplay_panels.visible:
        push_error("Boot smoke: blocking UI visible on gameplay start")
        quit(5)
        return
    if not hud.visible:
        push_error("Boot smoke: HUD is hidden")
        quit(6)
        return

    var found_world_environment := false
    for child in env_host.get_children():
        if child is WorldEnvironment and (child as WorldEnvironment).environment != null:
            found_world_environment = true
            break
    if not found_world_environment:
        push_error("Boot smoke: world environment was not created")
        quit(7)
        return

    print("Boot smoke passed: world, camera, HUD and environment are stable")
    quit(0)
