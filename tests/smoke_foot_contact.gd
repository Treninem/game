extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(100).timeout.connect(func():push_error("Foot contact validation timed out");quit(1))
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var fixture = load("res://tests/physical_human_fixture.gd")
    fixture.add_floor(world)
    var floor_body := world.get_child(0) as StaticBody3D
    var actor := fixture.player(world, Vector3(0, 0.08, 0)) as CharacterBody3D
    var audio := load("res://scripts/world_audio.gd").new() as Node3D
    world.add_child(audio)
    var vfx := root.get_node("WorldVFX")
    var weather := root.get_node("EnvironmentState")
    weather.set("wetness", 0.0)
    for i in range(25):await physics_frame
    assert(actor.is_on_floor())
    for surface: String in ["wood", "stone", "metal", "glass", "sand", "mud", "snow", "grass", "dirt"]:
        floor_body.set_meta("surface_type", surface)
        var contact: Dictionary = actor.call("_foot_contact")
        assert(contact.surface == surface and absf(contact.position.y) < 0.001)
        assert(contact.normal.dot(Vector3.UP) > 0.99)
        actor.call("_play_footstep_audio", 0.8, contact)
        var expected := "wood" if surface == "wood" else ("wet" if surface == "mud" else "ground")
        assert(audio.get("last_footstep_surface") == expected, "Floor contact disagrees with audio")
        var before := world.get_child_count()
        vfx.call("spawn_landing", contact.position, 12.0, surface, Vector3.FORWARD, contact.normal)
        if surface in ["wood", "stone", "metal", "glass"]:
            assert(world.get_child_count() == before, "Intact floor emitted soil/chips on landing")
    # Camera underwater state cannot turn a dry bank into water.
    var geography = load("res://scripts/world_geography.gd")
    var spawn: Vector2 = geography.START_SPAWN
    var data := root.get_node("WorldData")
    var bank := Vector3(spawn.x, data.call("elevation_at", spawn), spawn.y)
    weather.set("is_underwater", false)
    var dry_surface: String = vfx.call("surface_at", bank)
    weather.set("is_underwater", true)
    assert(vfx.call("surface_at", bank) == dry_surface)
    weather.set("is_underwater", false)
    var hydro = load("res://scripts/world_hydrology.gd")
    var ford: Vector2 = hydro.START_FORD_CENTER
    ford.x = geography.start_river_x(ford.y)
    var water_level: float = data.call("water_level_at", ford)
    assert(vfx.call("surface_at", Vector3(ford.x, water_level, ford.y)) == "water")
    floor_body.remove_meta("surface_type")
    floor_body.name = "TerrainCollision"
    assert(vfx.call("surface_from_collider", floor_body, bank) == dry_surface)
    floor_body.set_meta("surface_type", "wood")
    assert(vfx.call("surface_from_collider", floor_body, bank) == "wood")
    # A single-frame effect must preserve caller alpha and fade continuously.
    var puff = load("res://scripts/vfx_flipbook_3d.gd").new()
    world.add_child(puff)
    var paths: Array[String] = ["res://assets/vfx/third_party/kenney_particle_pack/PNG (Transparent)/smoke_03.png"]
    assert(puff.setup(paths, 0.25, Color(0.6, 0.5, 0.4, 0.18), 0.34))
    puff.set_process(false)
    puff.call("_process", 0.1)
    assert(absf(puff.material.albedo_color.a - 0.18) < 0.0001)
    puff.call("_process", 0.21)
    assert(puff.material.albedo_color.a > 0.0 and puff.material.albedo_color.a < 0.08)
    puff.queue_free()
    await process_frame
    for dust in get_nodes_in_group("foot_contact_dust"):dust.queue_free()
    await process_frame
    weather.set("wetness", 0.8)
    for surface: String in ["grass", "dirt"]:
        vfx.call("spawn_footstep", Vector3.ZERO, 1.0, surface)
    assert(get_node_count_in_group("foot_contact_dust") == 0, "Wet ground emitted dry dust")
    weather.set("wetness", 0.0)
    for i in range(80):vfx.call("spawn_footstep", Vector3.ZERO, 1.0, "dirt")
    assert(get_node_count_in_group("foot_contact_dust") == 36, "Transparent contact budget was exceeded")
    for dust in get_nodes_in_group("foot_contact_dust"):
        assert(not dust.material.emission_enabled)
        assert(dust.material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL)
        assert(dust.mesh_instance.mesh is QuadMesh)
        assert(dust.mesh_instance.mesh.size.x <= 0.4)
        assert(dust.base_alpha <= 0.24)
    await create_timer(0.6).timeout
    assert(get_node_count_in_group("foot_contact_dust") == 0, "Contact effects did not expire")
    audio.call("shutdown")
    print("FOOT_CONTACT_OK materials=9 physical_floor=true audio=matched camera_independent=true freshwater=true alpha=preserved budget=36 expiry=bounded")
    world.queue_free()
    await process_frame
    quit()
