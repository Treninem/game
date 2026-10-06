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
                        var visual_error := _visual_world_error(scene, player, streamer)
                        if not visual_error.is_empty():
                            _fail(11, visual_error)
                            return

                        var initial_y := player.global_position.y
                        for _i in range(18):
                            await get_tree().physics_frame
                        if not is_instance_valid(player):
                            _fail(12, "player disappeared immediately after loading handoff")
                            return
                        if bool(player.get("ground_guard_active")):
                            _fail(13, "player surface guard did not release after world reveal")
                            return
                        if absf(player.global_position.y - initial_y) > 0.75 or player.velocity.y < -1.0:
                            _fail(14, "player is falling after world reveal; initial_y=%s current_y=%s velocity_y=%s" % [initial_y, player.global_position.y, player.velocity.y])
                            return

                        _pass("boot -> menu -> new game -> visible terrain/environment -> stable grounded player")
                        return
        await get_tree().process_frame
    _fail(10, "world did not become playable within 35 seconds")

func _visual_world_error(scene: Node, player: CharacterBody3D, streamer: Node) -> String:
    if not streamer.has_method("_world_to_chunk"):
        return "world streamer cannot resolve the player's visual chunk"
    var loaded_variant: Variant = streamer.get("loaded_chunks")
    if not (loaded_variant is Dictionary):
        return "world streamer has no loaded chunk registry"
    var center_variant: Variant = streamer.call("_world_to_chunk", Vector2(player.global_position.x, player.global_position.z))
    if not (center_variant is Vector2i):
        return "world streamer returned an invalid player chunk coordinate"
    var loaded: Dictionary = loaded_variant
    var center: Vector2i = center_variant
    if not loaded.has(center) or not is_instance_valid(loaded.get(center)):
        return "player center chunk is missing after loading handoff"

    var chunk := loaded.get(center) as Node
    var terrain := chunk.get_node_or_null("Terrain") as MeshInstance3D if chunk != null else null
    if terrain == null or terrain.mesh == null:
        return "player center chunk has no visible terrain mesh"
    if not terrain.visible or not terrain.is_visible_in_tree():
        return "player center terrain exists but is hidden"
    if terrain.mesh.get_surface_count() <= 0:
        return "player center terrain mesh has no renderable surfaces"
    var bounds := terrain.get_aabb()
    if bounds.size.x < 1.0 or bounds.size.z < 1.0:
        return "player center terrain has invalid visual bounds: %s" % bounds
    if terrain.material_override == null and terrain.mesh.surface_get_material(0) == null:
        return "player center terrain has no render material"

    var environment_controller := scene.get_node_or_null("World/WorldEnvironmentController")
    var world_environment := environment_controller.get_node_or_null("StableWorldEnvironment") as WorldEnvironment if environment_controller != null else null
    if world_environment == null or world_environment.environment == null:
        return "world environment was not materialized before gameplay reveal"
    if world_environment.environment.background_mode != Environment.BG_SKY or world_environment.environment.sky == null:
        return "world environment has no active sky and could reveal a grey clear color"

    var camera := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
    if camera == null or not camera.current:
        return "player camera is missing or not current after loading handoff"
    if camera.get_viewport() == null or camera.get_viewport().get_camera_3d() != camera:
        return "viewport is not rendering through the player camera"
    return ""
