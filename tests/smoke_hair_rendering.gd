extends Node3D

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color.BLACK
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = 0.4
    add_child(environment)
    var light := DirectionalLight3D.new()
    light.light_energy = 0.6
    add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.keep_aspect = Camera3D.KEEP_HEIGHT
    camera.size = 2.0
    camera.position.z = 3.0
    add_child(camera)
    camera.make_current()
    var image := Image.create(8, 1, false, Image.FORMAT_RGBA8)
    var swatches := [0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6, 0.9]
    for index in range(8):
        var value: float = swatches[index]
        image.set_pixel(index, 0, Color(value, value, value, 1))
    var material := ShaderMaterial.new()
    material.shader = preload("res://assets/shaders/characters/hair_tint.gdshader")
    material.set_shader_parameter("hair_texture", ImageTexture.create_from_image(image))
    material.set_shader_parameter("hair_color", Color(0.5, 0.4, 0.3, 1))
    var visual := MeshInstance3D.new()
    visual.mesh = QuadMesh.new()
    visual.mesh.size = Vector2(3.2, 0.8)
    visual.material_override = material
    add_child(visual)
    for frame in range(6):
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var actual := get_viewport().get_texture().get_image()
    var values: Array[float] = []
    for index in range(8):
        var x := int(float(actual.get_width()) * 0.5 + (float(index) - 3.5) * 0.4 * float(actual.get_height()) * 0.5)
        values.append(actual.get_pixel(x, actual.get_height() / 2).get_luminance())
    actual.save_png("user://hair-tonal-ramp.png")
    print("HAIR_RENDER_SAMPLES ", values)
    # Distinct authored highlights must survive the actual lit shader pipeline.
    if values[7] - values[3] < 0.02:
        push_error("Hair material flattens distinct mid/high strand values")
        get_tree().quit(1)
        return
    for index in range(1, 8):
        if values[index] < values[index - 1] - 0.005:
            push_error("Hair material reverses strand brightness")
            get_tree().quit(1)
            return
    print("HAIR_RENDERING_OK lit_bands=8 highlights=distinct monotonic=true")
    get_tree().quit(0)
