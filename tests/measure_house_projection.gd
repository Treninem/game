extends "res://tests/capture_streamed_home_door.gd"

# A stationary A/B/A material experiment, not a replacement for the failing
# continuous rendered gameplay test. Its source and deadline remain intact.
var measured_cases: Array = []

func _run() -> void:
    var state := root.get_node("GameState")
    state.world_minutes = 22 * 60
    fixture = Node3D.new()
    var center: Vector2 = load("res://scripts/capital_data.gd").CENTER
    var elevation: float = root.get_node("WorldData").elevation_at(center)
    fixture.position = Vector3(center.x, elevation + .025, center.y)
    root.add_child(fixture)
    current_scene = fixture
    var ground := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(150, .2, 150)
    collision.shape = shape
    collision.position.y = -.1
    ground.add_child(collision)
    fixture.add_child(ground)
    _build_square()
    for actor: CharacterBody3D in [trader, artisan]:
        actor.autonomous = false
    # Controlled pose setup only; no travel, AI or ordinary-play claim.
    artisan.position = home.position + Vector3(0, home.floor_thickness + .04, 6)
    trader.position = home.position + Vector3(-2.5, home.floor_thickness + .04, 8)
    await _frames(12)
    for actor: CharacterBody3D in [trader, artisan]:
        actor.set_physics_process(false)
        actor.visual.set_process(false)
        actor.visual.animation_player.pause()
    var original_materials: Array = []
    for material: StandardMaterial3D in home.wall_materials:
        original_materials.append({"material": material, "triplanar": material.uv1_triplanar,
            "world_triplanar": material.uv1_world_triplanar,
            "albedo": material.albedo_texture, "normal": material.normal_texture,
            "orm": material.roughness_texture, "normal_enabled": material.normal_enabled})
    await _measure("baseline-triplanar")
    for record: Dictionary in original_materials:
        record.material.uv1_triplanar = false
    await _measure("uv-cost-probe-not-production-uvs")
    for record: Dictionary in original_materials:
        record.material.uv1_triplanar = record.triplanar
        assert(record.material.uv1_world_triplanar == record.world_triplanar)
        assert(record.material.albedo_texture == record.albedo)
        assert(record.material.normal_texture == record.normal)
        assert(record.material.roughness_texture == record.orm)
        assert(record.material.normal_enabled == record.normal_enabled)
    await _measure("restored-triplanar")
    var drift: float = absf(float(measured_cases[2].median_ms) / float(measured_cases[0].median_ms) - 1)
    var file := FileAccess.open("user://house-projection-cost.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"scope": "Stationary production house and human at high1280x720. Only plaster projection toggled in memory; the UV probe intentionally uses unsuitable old box UVs and is not a visual candidate.",
        "production_runtime_changed": false, "manual_play": false, "animations_paused_for_comparison": true,
        "clock_scale": Engine.time_scale, "physics_ticks_per_second": Engine.physics_ticks_per_second,
        "adapter": RenderingServer.get_video_adapter_name(), "viewport": str(root.size),
        "scale_3d": root.scaling_3d_scale, "msaa_3d": root.msaa_3d,
        "restored_materials_verified": true, "baseline_median_drift_fraction": drift,
        "cases": measured_cases, "full_graphical_gameplay_pass": false}, "  "))
    file.close()
    assert(drift <= .25, "A/B/A baseline drift exceeds the predeclared25percent comparison bound")
    print("HOUSE_PROJECTION_COST_MEASURED ", JSON.stringify(measured_cases))
    quit(0)

func _measure(label: String) -> void:
    for frame in range(6):
        await RenderingServer.frame_post_draw
    var values: Array[float] = []
    var before := Time.get_ticks_usec()
    for frame in range(32):
        await RenderingServer.frame_post_draw
        var now := Time.get_ticks_usec()
        values.append(float(now - before) / 1000.0)
        before = now
    var ordered := values.duplicate()
    ordered.sort()
    var sum := 0.0
    for value in values:
        sum += value
    measured_cases.append({"label": label, "frames": values.size(),
        "mean_ms": sum / values.size(), "median_ms": ordered[16],
        "p95_ms": ordered[30], "max_ms": ordered.back(),
        "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
        "video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
    assert(root.get_texture().get_image().save_png("user://projection-" + label + ".png") == OK)
