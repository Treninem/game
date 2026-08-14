extends GPUParticles3D

@export var bubble_count: int = 72
@export var box_extents: Vector3 = Vector3(5.0, 1.8, 5.0)
@export var rise_speed_min: float = 0.22
@export var rise_speed_max: float = 0.72
@export var bubble_size_min: float = 0.018
@export var bubble_size_max: float = 0.055
@export var field_lifetime: float = 5.0

func _ready() -> void:
    amount = maxi(bubble_count, 1)
    lifetime = maxf(field_lifetime, 0.5)
    preprocess = lifetime
    randomness = 0.75
    local_coords = false
    emitting = true

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = box_extents
    process.direction = Vector3.UP
    process.spread = 16.0
    process.initial_velocity_min = rise_speed_min
    process.initial_velocity_max = rise_speed_max
    process.gravity = Vector3.ZERO
    process.scale_min = bubble_size_min
    process.scale_max = bubble_size_max
    process.turbulence_enabled = true
    process.turbulence_noise_strength = 0.32
    process.turbulence_noise_scale = 2.2
    process.turbulence_influence_min = 0.08
    process.turbulence_influence_max = 0.26
    process_material = process

    var bubble := SphereMesh.new()
    bubble.radius = 0.5
    bubble.height = 1.0
    bubble.radial_segments = 8
    bubble.rings = 4

    var mat := StandardMaterial3D.new()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.62, 0.86, 1.0, 0.18)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    bubble.material = mat
    draw_pass_1 = bubble

func set_density(value: float) -> void:
    var density := clampf(value, 0.0, 1.0)
    amount = maxi(int(round(float(bubble_count) * density)), 1)
    emitting = density > 0.01

func set_current(direction: Vector3, strength: float) -> void:
    var process := process_material as ParticleProcessMaterial
    if process == null:
        return
    var current := direction
    current.y = maxf(current.y, 0.0)
    if current.length_squared() > 0.0001:
        current = current.normalized()
    process.direction = (Vector3.UP + current * clampf(strength, 0.0, 1.0) * 0.65).normalized()
