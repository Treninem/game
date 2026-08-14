extends Node

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Boot smoke::%s" % clean)
    push_error("Boot smoke: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "stage scene missing")
        return
    var scene := packed.instantiate()
    get_tree().root.add_child(scene)
    for _i in range(18):
        await get_tree().process_frame

    var player := scene.get_node_or_null("World/Player") as CharacterBody3D
    var camera := scene.get_node_or_null("World/Player/CameraPivot/Camera3D") as Camera3D
    var env_host := scene.get_node_or_null("World/WorldEnvironmentController")
    var hud := scene.get_node_or_null("UI/HUD") as Control
    var pause_menu := scene.get_node_or_null("UI/GameMenu") as Control
    var gameplay_panels := scene.get_node_or_null("UI/GameplayPanels") as Control

    if player == null or camera == null or env_host == null or hud == null:
        _fail(3, "mandatory world nodes missing")
        return
    if camera.far < 900.0:
        _fail(4, "camera view distance regressed")
        return
    if pause_menu == null or gameplay_panels == null or pause_menu.visible or gameplay_panels.visible:
        _fail(5, "blocking UI visible on gameplay start")
        return
    if not hud.visible:
        _fail(6, "HUD is hidden")
        return

    var found_world_environment := false
    for child in env_host.get_children():
        if child is WorldEnvironment and (child as WorldEnvironment).environment != null:
            found_world_environment = true
            break
    if not found_world_environment:
        _fail(7, "world environment was not created")
        return

    print("Boot smoke passed: world, camera, HUD and environment are stable")
    get_tree().quit(0)
