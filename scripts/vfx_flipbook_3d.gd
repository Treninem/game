extends Node3D

var frames: Array[Texture2D] = []
var frame_time := 0.065
var loop_count := 1
var elapsed := 0.0
var total_elapsed := 0.0
var current_frame := -1
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

func setup(paths: Array[String], size: float, tint: Color = Color.WHITE, seconds_per_frame: float = 0.065, loops: int = 1) -> bool:
    frames.clear()
    for path in paths:
        if not ResourceLoader.exists(path):
            continue
        var texture := load(path) as Texture2D
        if texture != null:
            frames.append(texture)
    if frames.is_empty():
        queue_free()
        return false

    frame_time = maxf(0.025, seconds_per_frame)
    loop_count = maxi(1, loops)

    mesh_instance = MeshInstance3D.new()
    mesh_instance.name = "FlipbookBillboard"
    var quad := QuadMesh.new()
    quad.size = Vector2(size, size)
    mesh_instance.mesh = quad

    material = StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.albedo_color = tint
    material.emission_enabled = true
    material.emission = Color(tint.r, tint.g, tint.b, 1.0)
    material.emission_energy_multiplier = 1.8
    mesh_instance.material_override = material
    add_child(mesh_instance)
    _show_frame(0)
    return true

func _process(delta: float) -> void:
    if frames.is_empty() or material == null:
        return
    elapsed += delta
    total_elapsed += delta
    var frame_index := int(floor(elapsed / frame_time))
    var total_frames := frames.size() * loop_count
    if frame_index >= total_frames:
        queue_free()
        return
    _show_frame(frame_index % frames.size())
    if mesh_instance != null:
        mesh_instance.rotation.z += delta * 0.65
        var life_ratio := clampf(float(frame_index) / maxf(float(total_frames - 1), 1.0), 0.0, 1.0)
        var pulse := 1.0 + sin(total_elapsed * 12.0) * 0.04
        var fade := 1.0 - maxf(0.0, (life_ratio - 0.72) / 0.28)
        mesh_instance.scale = Vector3.ONE * pulse
        material.albedo_color.a = clampf(fade, 0.0, 1.0)

func _show_frame(index: int) -> void:
    if index == current_frame or index < 0 or index >= frames.size():
        return
    current_frame = index
    material.albedo_texture = frames[index]
