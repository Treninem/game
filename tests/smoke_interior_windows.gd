extends Node3D

func _ready() -> void:
    get_tree().create_timer(70).timeout.connect(func(): push_error("Window test timeout"); get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    print("INTERIOR_WINDOWS_START")
    position.x = 60.0
    GameState.reset_new_game()
    var home := EnterableBuilding.new()
    home.configure(Vector3(12, 3.2, 10))
    add_child(home)
    var decorator := SettlementInteriorVisuals.new()
    add_child(decorator)
    decorator.decorate_building(home)
    var stage := load("res://scenes/stage1.tscn").instantiate() as Node
    var player := stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    add_child(player)
    player.call("_set_instanced_world_mode", true)
    print("INTERIOR_WINDOWS_PLAYER_READY")
    player.position = Vector3(0.8, 0.4, -0.5)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.23, 0.34, 0.46)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = 0.35
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -30, 0)
    sun.shadow_enabled = true
    add_child(sun)
    var camera := Camera3D.new()
    camera.position = Vector3(3.9, 2.3, 3.6)
    add_child(camera)
    camera.look_at(to_global(Vector3(-0.7, 1.25, -2)))
    camera.make_current()
    assert(home.window_lights.size() == 3)
    # Inspect the imported, rendered meshes rather than trusting registry state.
    var glass_count := 0
    for mesh: MeshInstance3D in home.find_children("Glass", "MeshInstance3D", true, false):
        assert(mesh.mesh.get_faces().size() == 6, "Glass must be one two-sided pane, not a closed box")
        assert(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
        assert((mesh.material_override as StandardMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED)
        glass_count += 1
    assert(glass_count == 3)
    GameState.world_minutes = 12.0 * 60.0
    for preset: int in [0, 1, 2, 3]:
        print("INTERIOR_WINDOWS_PRESET ", preset)
        SettingsManager.set_quality_preset(preset)
        await get_tree().process_frame
        await get_tree().process_frame
        home._update_window_light()
        for light: SpotLight3D in home.window_lights:
            assert(light.visible == (preset > 0))
            assert(not light.shadow_enabled)
            assert(light.global_basis.z.dot((home.global_position - light.global_position).normalized()) < -0.8, "Window light must face into its own room")
        assert(home.room_lantern.visible and home.room_lantern.shadow_enabled == (preset > 0))
    for i in range(30):
        await get_tree().physics_frame
    assert(player.is_on_floor(), "Character lacks physical room support")
    for preset: int in [0, 3]:
        SettingsManager.set_quality_preset(preset)
        home._update_window_light()
        for i in range(30):
            await get_tree().process_frame
        var started := Time.get_ticks_usec()
        for i in range(120):
            await get_tree().process_frame
        print("INTERIOR_ROOM_SAMPLE preset=", preset, " frames=120 ms_per_frame=", float(Time.get_ticks_usec() - started) / 120000.0, " video_bytes=", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    await _capture("day-character")
    var daytime_lantern_energy := home.room_lantern.light_energy
    GameState.world_minutes = 0.0
    home._update_window_light()
    for light: SpotLight3D in home.window_lights:
        assert(not light.visible and light.light_energy == 0.0)
    assert(home.room_lantern.light_energy > daytime_lantern_energy)
    sun.light_energy = 0.0
    environment.environment.ambient_light_energy = 0.10
    environment.environment.background_color = Color(0.015, 0.025, 0.05)
    await _capture("night-no-daylight")
    GameState.world_minutes = 12.0 * 60.0
    player.position.x = 30.0
    home._update_window_light()
    for light: SpotLight3D in home.window_lights:
        assert(not light.visible, "Distant house lights were not culled")
    assert(not home.room_lantern.visible and not home.room_lantern.shadow_enabled)
    print("INTERIOR_WINDOWS_OK glass=3 quality=4 day_night=true distance_budget=true physical_character=true")
    get_tree().quit(0)

func _capture(label: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("user://interior-window-" + label + ".png")
