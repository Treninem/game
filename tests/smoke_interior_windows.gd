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
    var details := home.get_node("HouseholdDetails")
    var detail_count := details.get_child_count()
    assert(detail_count >= 17, "House lacks cooking, storage and personal furnishing zones")
    decorator.decorate_building(home)
    assert(details.get_child_count() == detail_count, "Repeated decoration duplicates objects")
    var table_top := _actual_bounds(home.get_node("InteriorFurniture/Table/RealTableModel"), home)
    for item: Node3D in details.get_children():
        if not String(item.name).begins_with("Table"):
            continue
        var bounds := _actual_bounds(item, home)
        assert(absf(bounds.position.y - table_top.end.y) < 0.005, "Tableware floats or penetrates the table")
        assert(bounds.position.x >= table_top.position.x and bounds.end.x <= table_top.end.x and bounds.position.z >= table_top.position.z and bounds.end.z <= table_top.end.z, "Tableware overhangs its support")
    var case_bounds := _actual_bounds(details.get_node("HouseBookcase"), home)
    assert(absf(case_bounds.position.y - home.floor_thickness) < 0.005)
    var row_count := 0
    for child in details.get_node("HouseBookcase").get_children():
        if child.get_meta("household_prop", "") == "Book_Stack_1":
            row_count += 1
    assert(row_count >= 2, "Books were not placed on measured shelf surfaces")
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
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky.sky_material = sky_material
    environment.environment.sky = sky
    environment.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -30, 0)
    sun.shadow_enabled = true
    add_child(sun)
    var camera := Camera3D.new()
    camera.position = Vector3(0.25, 2.3, 3.7)
    add_child(camera)
    camera.look_at(to_global(Vector3(0.1, 1.25, -2.5)))
    camera.make_current()
    assert(home.window_lights.size() == 4)
    # Inspect the imported, rendered meshes rather than trusting registry state.
    var glass_count := 0
    for mesh: MeshInstance3D in home.find_children("Glass", "MeshInstance3D", true, false):
        assert(mesh.mesh.get_faces().size() == 6, "Glass must be one two-sided pane, not a closed box")
        assert(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
        assert((mesh.material_override as StandardMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED)
        glass_count += 1
    assert(glass_count == 4)
    GameState.world_minutes = 12.0 * 60.0
    for preset: int in [0, 1, 2, 3]:
        print("INTERIOR_WINDOWS_PRESET ", preset)
        SettingsManager.set_quality_preset(preset)
        for light: SpotLight3D in home.window_lights:
            assert(light.visible == (preset > 0))
            assert(not light.shadow_enabled)
            var inward: Vector3 = light.get_parent_node_3d().global_basis.z.normalized()
            assert((-light.global_basis.z).dot(inward) > 0.99 and inward.dot((home.global_position - light.global_position).normalized()) > 0.0, "Window light must face along its own opening's inward normal")
        assert(home.room_lantern.visible and home.room_lantern.shadow_enabled == (preset > 0))
        await get_tree().process_frame
        await get_tree().process_frame
    for i in range(30):
        await get_tree().physics_frame
    assert(player.is_on_floor(), "Character lacks physical room support")
    var query := PhysicsRayQueryParameters3D.create(to_global(Vector3(0, 1.25, 4)), to_global(Vector3(0, 1.25, -4)))
    assert(get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Dressing blocks the main aisle")
    var shelf := details.get_node("HouseBookcase") as StaticBody3D
    query = PhysicsRayQueryParameters3D.create(shelf.global_position + Vector3(0, 0.8, 1), shelf.global_position + Vector3(0, 0.8, -0.5))
    assert(get_world_3d().direct_space_state.intersect_ray(query).get("collider") == shelf, "Bookcase lacks physical collision")
    for door: DoorInteractable in home.get_node("HouseRooms").room_doors:
        door.set_open(false, true)
        assert(GameState.get_world_value(door.persistence_key, true) == false)
        var saved := JSON.parse_string(JSON.stringify(GameState.snapshot())) as Dictionary
        door.set_open(true, true)
        GameState.load_snapshot(saved)
        door.restore_saved_state()
        assert(not door.is_open(), "Internal door state does not survive save restore")
    for destination: Vector3 in [Vector3(-3.1, 0, -3.27), Vector3(-3.1, 0, -0.27), Vector3(3.0, 0, 3.1), Vector3(0.5, 0, -0.5)]:
        await _walk_room(player, home, destination)
    print("HOUSE_ROOM_WALK_OK rooms=3 closed_doors_opened_by_path=true")
    for preset: int in [0, 3]:
        SettingsManager.set_quality_preset(preset)
        for i in range(30):
            await get_tree().process_frame
        var started := Time.get_ticks_usec()
        for i in range(120):
            await get_tree().process_frame
        print("INTERIOR_ROOM_SAMPLE preset=", preset, " frames=120 ms_per_frame=", float(Time.get_ticks_usec() - started) / 120000.0, " video_bytes=", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    await _capture("day-character")
    camera.position = Vector3(5.2, 2.1, 1.4)
    camera.look_at(to_global(table_top.get_center() + Vector3.UP * table_top.size.y * 0.5))
    await _capture("table-closeup")
    camera.position = Vector3(1.4, 2.2, -0.8)
    camera.look_at(to_global(Vector3(4.2, 1.0, -0.45)))
    await _capture("dining")
    camera.position = Vector3(-2.0, 2.1, -2.1)
    camera.look_at(to_global(Vector3(-3.8, 1.2, -3.0)))
    await _capture("bedroom")
    camera.position = Vector3(2.0, 2.3, 2.8)
    camera.fov = 82
    camera.look_at(to_global(Vector3(4.0, 1.35, 4.0)))
    await _capture("kitchen")
    camera.fov = 75
    camera.position = Vector3(-1.6, 2.2, 1.6)
    camera.look_at(to_global(Vector3(-3.2, 1.1, 3.8)))
    await _capture("living-storage")
    camera.position = Vector3(0.25, 2.3, 3.7)
    camera.look_at(to_global(Vector3(0.1, 1.25, -2.5)))
    var daytime_lantern_energy := home.room_lantern.light_energy
    GameState.world_minutes = 0.0
    home._update_window_light()
    for light: SpotLight3D in home.window_lights:
        assert(not light.visible and light.light_energy == 0.0)
    assert(home.room_lantern.light_energy > daytime_lantern_energy)
    sun.light_energy = 0.0
    environment.environment.ambient_light_energy = 0.10
    environment.environment.background_color = Color(0.015, 0.025, 0.05)
    sky_material.sky_energy_multiplier = 0.15
    sky_material.ground_energy_multiplier = 0.15
    await _capture("night-no-daylight")
    GameState.world_minutes = 12.0 * 60.0
    player.position.x = 30.0
    home._update_window_light()
    for light: SpotLight3D in home.window_lights:
        assert(not light.visible, "Distant house lights were not culled")
    assert(not home.room_lantern.visible and not home.room_lantern.shadow_enabled)
    print("INTERIOR_WINDOWS_OK glass=4 quality=4 day_night=true distance_budget=true physical_character=true")
    get_tree().quit(0)

func _walk_room(player: CharacterBody3D, home: EnterableBuilding, destination: Vector3) -> void:
    var arrived := false
    var start := player.global_position
    Input.action_press("move_forward")
    for frame in range(600):
        var local := home.to_local(player.global_position)
        if Vector2(local.x - destination.x, local.z - destination.z).length() < 0.22:
            arrived = true
            break
        var point: Vector3 = home.get_node("HouseRooms").waypoint(local, destination, player)
        var direction := home.to_global(point) - player.global_position
        player.rotation.y = atan2(-direction.x, -direction.z)
        await get_tree().physics_frame
    Input.action_release("move_forward")
    for frame in range(8):
        await get_tree().physics_frame
    print("HOUSE_ROOM_WALK destination=", destination, " arrived=", arrived, " position=", home.to_local(player.global_position), " displacement=", start.distance_to(player.global_position))
    assert(arrived and player.is_on_floor(), "Actual character failed to walk through furnished rooms")

func _actual_bounds(node: Node3D, reference: Node3D) -> AABB:
    var result := AABB()
    var measured := false
    for candidate in [node] + node.find_children("*", "MeshInstance3D", true, false):
        if candidate is MeshInstance3D:
            var part: AABB = (reference.global_transform.affine_inverse() * candidate.global_transform) * candidate.get_aabb()
            result = result.merge(part) if measured else part
            measured = true
    assert(measured)
    return result

func _capture(label: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("user://interior-window-" + label + ".png")
