extends Node

var finished := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _fail(code: int, message: String) -> void:
    if finished:
        return
    finished = true
    push_error("Boot/world smoke: %s" % message)
    print("BOOT_WORLD_SMOKE_FAIL: ", message)
    get_tree().quit(code)

func _pass(message: String) -> void:
    if finished:
        return
    finished = true
    print("BOOT_WORLD_SMOKE_PASS: ", message)
    get_tree().quit(0)

func _wait_for_scene_name(name: String, timeout_seconds: float) -> bool:
    var deadline := Time.get_ticks_msec() + roundi(timeout_seconds * 1000.0)
    while Time.get_ticks_msec() < deadline:
        var scene := get_tree().current_scene
        if scene != null and scene.name == name:
            return true
        await get_tree().process_frame
    return false

func _run() -> void:
    var boot := load("res://scenes/boot_launcher.tscn") as PackedScene
    if boot == null:
        _fail(2, "boot launcher scene is missing")
        return
    var instance := boot.instantiate()
    if instance == null:
        _fail(3, "boot launcher could not be instantiated")
        return
    get_tree().root.add_child(instance)

    if not await _wait_for_scene_name("MainMenu", 15.0):
        _fail(4, "main menu did not open from boot launcher")
        return
    var menu := get_tree().current_scene
    var music := menu.get_node_or_null("MenuMusic") as AudioStreamPlayer
    if music == null or music.stream == null:
        _fail(5, "menu music stream is missing")
        return
    if not music.playing:
        _fail(6, "menu music is not playing")
        return
    var button_texture = menu.get("button_texture")
    if button_texture == null:
        _fail(7, "menu button texture was not decoded")
        return

    if not menu.has_method("_new_game"):
        _fail(8, "new game action is missing")
        return
    menu.call("_new_game")
    if not await _wait_for_scene_name("WorldLoading", 8.0):
        _fail(9, "new game did not open the world loading screen")
        return

    var deadline := Time.get_ticks_msec() + 35000
    while Time.get_ticks_msec() < deadline:
        var scene := get_tree().current_scene
        if scene != null and scene.name == "Bootstrap":
            var player := scene.get_node_or_null("World/Player") as CharacterBody3D
            var streamer := scene.get_node_or_null("World/WorldStreamer")
            if player != null and streamer != null:
                var loaded = streamer.get("loaded_chunks")
                var collisions = streamer.get("collision_chunks")
                if loaded is Dictionary and collisions is Dictionary and not loaded.is_empty() and not collisions.is_empty():
                    var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 2.0, player.global_position + Vector3.DOWN * 4.0)
                    ray.exclude = [player.get_rid()]
                    ray.collision_mask = 1
                    if not player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
                        _pass("boot -> menu -> new game -> generated terrain/collision -> playable world")
                        return
        await get_tree().process_frame
    _fail(10, "world did not become playable within 35 seconds")
