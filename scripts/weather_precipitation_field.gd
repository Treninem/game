extends GPUParticles3D

enum Mode {
    AUTO,
    RAIN,
    SNOW,
    HAIL
}

@export var mode: Mode = Mode.AUTO
@export var follow_camera: bool = true
@export var emitter_height: float = 6.0
@export var emitter_extents: Vector3 = Vector3(11.0, 5.0, 11.0)
@export var rain_particles: int = 420
@export var snow_particles: int = 260
@export var hail_particles: int = 180

var _active_mode: Mode = Mode.RAIN
var _particle_process: ParticleProcessMaterial

func _ready() -> void:
    local_coords = false
    one_shot = false
    randomness = 0.55
    fixed_fps = 30
    visibility_aabb = AABB(Vector3(-14.0, -10.0, -14.0), Vector3(28.0, 22.0, 28.0))
    _particle_process = ParticleProcessMaterial.new()
    _particle_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    _particle_process.emission_box_extents = emitter_extents
    _particle_process.gravity = Vector3.ZERO
    process_material = _particle_process
    _apply_mode(_resolve_mode(), true)

func _process(_delta: float) -> void:
    if follow_camera:
        var camera := get_viewport().get_camera_3d()
        if camera != null:
            global_position = camera.global_position + Vector3.UP * emitter_height

    var resolved := _resolve_mode()
    if resolved != _active_mode:
        _apply_mode(resolved, false)

    var intensity := _resolve_intensity(_active_mode)
    amount_ratio = clampf(intensity, 0.0, 1.0)
    emitting = intensity > 0.015

    var wind := EnvironmentState.wind_direction * EnvironmentState.wind_strength
    var down_force := 0.18 if _active_mode == Mode.SNOW else 0.48
    _particle_process.direction = (Vector3.DOWN + wind * down_force).normalized()

func _resolve_mode() -> Mode:
    if mode != Mode.AUTO:
        return mode
    if EnvironmentState.storm_intensity > 0.90 and EnvironmentState.rain_intensity > 0.35 and EnvironmentState.temperature_c > -2.0 and EnvironmentState.temperature_c < 12.0:
        return Mode.HAIL
    if EnvironmentState.snow_intensity > EnvironmentState.rain_intensity or EnvironmentState.temperature_c <= 0.5:
        return Mode.SNOW
    return Mode.RAIN

func _resolve_intensity(resolved: Mode) -> float:
    match resolved:
        Mode.SNOW:
            return EnvironmentState.snow_intensity
        Mode.HAIL:
            return minf(EnvironmentState.rain_intensity, EnvironmentState.storm_intensity)
        _:
            return EnvironmentState.rain_intensity

func _apply_mode(resolved: Mode, first_setup: bool) -> void:
    _active_mode = resolved
    _particle_process.emission_box_extents = emitter_extents

    match resolved:
        Mode.SNOW:
            amount = maxi(snow_particles, 1)
            lifetime = 8.0
            preprocess = 5.0 if first_setup else 0.0
            _particle_process.spread = 24.0
            _particle_process.initial_velocity_min = 0.65
            _particle_process.initial_velocity_max = 1.55
            _particle_process.turbulence_enabled = false
            draw_pass_1 = _make_sphere_mesh(0.035, Color(0.94, 0.97, 1.0, 0.78))
        Mode.HAIL:
            amount = maxi(hail_particles, 1)
            lifetime = 2.2
            preprocess = 1.0 if first_setup else 0.0
            _particle_process.spread = 9.0
            _particle_process.initial_velocity_min = 8.0
            _particle_process.initial_velocity_max = 13.0
            _particle_process.turbulence_enabled = false
            draw_pass_1 = _make_sphere_mesh(0.028, Color(0.78, 0.90, 1.0, 0.86))
        _:
            amount = maxi(rain_particles, 1)
            lifetime = 1.75
            preprocess = 1.0 if first_setup else 0.0
            _particle_process.spread = 5.0
            _particle_process.initial_velocity_min = 10.0
            _particle_process.initial_velocity_max = 17.0
            _particle_process.turbulence_enabled = false
            draw_pass_1 = _make_rain_mesh()

    restart()

func _make_rain_mesh() -> Mesh:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.012, 0.52, 0.012)
    var mat := StandardMaterial3D.new()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.58, 0.77, 0.92, 0.48)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material = mat
    return mesh

func _make_sphere_mesh(radius: float, color: Color) -> Mesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 6
    mesh.rings = 3
    var mat := StandardMaterial3D.new()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material = mat
    return mesh
