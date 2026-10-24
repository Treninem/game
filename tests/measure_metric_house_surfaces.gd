extends "res://tests/measure_house_projection.gd"

var pixel_checks: Array = []
var preset_checks: Array = []

func _build_square() -> void:
    super._build_square()
    var settings := root.get_node("SettingsManager")
    var original_preset: int = settings.get_value("graphics", "quality_preset")
    var original_scale: float = settings.get_value("graphics", "render_scale")
    for preset in range(4):
        settings.set_quality_preset(preset)
        var checked := 0
        for record: Dictionary in home.projected_materials.values():
            var source: StandardMaterial3D = record.source
            var mapped: StandardMaterial3D = record.mapped
            assert(mapped.albedo_texture == source.albedo_texture and mapped.normal_texture == source.normal_texture)
            assert(mapped.ao_texture == source.ao_texture and mapped.roughness_texture == source.roughness_texture)
            assert(mapped.normal_enabled == source.normal_enabled and mapped.ao_enabled == source.ao_enabled)
            assert(mapped.roughness == source.roughness)
            if source in home.wall_materials:
                assert(mapped.normal_enabled == (preset >= 2) and mapped.ao_enabled == (preset >= 2))
            checked += 1
        assert(checked >= 3)
        preset_checks.append({"preset": preset, "mapped_materials_checked": checked, "maps_and_flags_match_source": true})
    settings.set_quality_preset(original_preset)
    settings.set_value("graphics", "render_scale", original_scale)

func _run() -> void:
    await super._run()
    # Keep the source A/B/A safeguards and add actual PBR pixel comparisons.
    _set_projection(false)
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://house-projection-cost.json"))
    data.scope = "Stationary production house, unchanged high1280x720, normal maps and texture objects; source world triplanar versus properly baked metric UVs and restored source. No gameplay/FPS acceptance."
    data.source_sha = OS.get_environment("GITHUB_SHA")
    data.pixel_checks = pixel_checks
    data.preset_checks = preset_checks
    data.unwarped_metric_uv_candidate = true
    data.full_graphical_gameplay_pass = false
    var file := FileAccess.open("user://metric-house-projection.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "  "))
    file.close()
    for record: Dictionary in pixel_checks:
        if float(record.mean_absolute_rgb_error) > .03:
            push_error("Metric UV surface changes the reference texture/PBR appearance: " + JSON.stringify(record))
            quit(1)
    print("METRIC_HOUSE_SURFACES_REVIEW ", JSON.stringify(pixel_checks))

func _measure(label: String) -> void:
    # The parent probe toggles the original partition materials. This test
    # leaves those authored surfaces unchanged and compares only mapped boxes.
    for material: StandardMaterial3D in home.wall_materials:
        material.uv1_triplanar = true
    assert(home.projected_materials.size() >= 3, "Walls floor and ceiling did not acquire metric projection")
    if label == "baseline-triplanar":
        _set_projection(true)
        await super._measure("world-source")
    elif label == "uv-cost-probe-not-production-uvs":
        _set_projection(false)
        await super._measure("metric-uv-candidate")
        _compare("front-Z", "projection-world-source.png", "projection-metric-uv-candidate.png", Vector3(1.6, 2.6, 5.002))
    else:
        _set_projection(true)
        await super._measure("restored-world-source")
        await _axis_capture("side-X", Vector3(11, 2.3, 1.7), Vector3(6, 1.6, 1.7), Vector3(6.002, 2.6, 2))
        await _axis_capture("floor-Y", Vector3(0, 2.7, 2.9), Vector3(0, .18, 1), Vector3(0, .1802, 1.1))

func _set_projection(source: bool) -> void:
    for record: Dictionary in home.projected_materials.values():
        var mapped: StandardMaterial3D = record.mapped
        var original: StandardMaterial3D = record.source
        mapped.uv1_triplanar = source
        mapped.uv1_world_triplanar = source
        mapped.uv1_scale = original.uv1_scale if source else Vector3.ONE
        mapped.uv1_offset = original.uv1_offset if source else Vector3.ZERO

func _axis_capture(label: String, camera_point: Vector3, target: Vector3, sample: Vector3) -> void:
    review_camera.global_position = home.to_global(camera_point)
    review_camera.look_at(home.to_global(target), Vector3.UP)
    for source: bool in [true, false]:
        _set_projection(source)
        for frame in range(4): await RenderingServer.frame_post_draw
        var filename := "projection-" + label + ("-source.png" if source else "-metric.png")
        assert(root.get_texture().get_image().save_png("user://" + filename) == OK)
    _compare(label, "projection-" + label + "-source.png", "projection-" + label + "-metric.png", sample)
    _set_projection(true)

func _compare(label: String, original: String, mapped: String, local_point: Vector3) -> void:
    var reference := Image.load_from_file("user://" + original)
    var candidate := Image.load_from_file("user://" + mapped)
    assert(reference != null and candidate != null and reference.get_size() == candidate.get_size())
    var point := review_camera.unproject_position(home.to_global(local_point))
    var center := Vector2i(roundi(point.x), roundi(point.y))
    assert(center.x >= 10 and center.y >= 10 and center.x < reference.get_width() - 10 and center.y < reference.get_height() - 10,
        "Reference face sample is outside the actual camera")
    var sum := 0.0
    var maximum := 0.0
    var pixels := 0
    for x in range(center.x - 8, center.x + 9):
        for y in range(center.y - 8, center.y + 9):
            var before := reference.get_pixel(x, y)
            var after := candidate.get_pixel(x, y)
            var error := (absf(before.r - after.r) + absf(before.g - after.g) + absf(before.b - after.b)) / 3.0
            sum += error
            maximum = maxf(maximum, error)
            pixels += 1
    pixel_checks.append({"face": label, "center": center, "pixels": pixels,
        "mean_absolute_rgb_error": sum / pixels, "max_absolute_rgb_error": maximum,
        "source_file": original, "metric_file": mapped})
