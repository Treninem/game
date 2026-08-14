extends Node

# Missing hail layer for the shared WeatherVFX stack. Uses a fixed particle budget
# and amount_ratio so intensity changes do not constantly restart the emitter.

var root: Node3D
var hail_particles: GPUParticles3D
var update_elapsed := 0.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    _ensure_emitter()
    if root == null or hail_particles == null:
        return

    root.global_position = player.global_position + Vector3.UP * 8.0
    update_elapsed += delta
    if update_elapsed >= 0.20:
        update_elapsed = 0.0
        _sync_hail()

func _ensure_emitter() -> void:
    if root != null and is_instance_valid(root):
        return
    var host := get_tree().current_scene
    if host == null:
        return

    root = Node3D.new()
    root.name = "LocalHailVFX"
    host.add_child(root)

    hail_particles = GPUParticles3D.new()
    hail_particles.name = "Hail"
    hail_particles.amount = 180
    hail_particles.amount_ratio = 0.0
    hail_particles.lifetime = 2.0
    hail_particles.local_coords = false
    hail_particles.fixed_fps = 30
    hail_particles.visibility_aabb = AABB(Vector3(-18, -18, -18), Vector3(36, 36, 36))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(13.0, 1.5, 13.0)
    process.direction = Vector3.DOWN
    process.spread = 9.0
    process.initial_velocity_min = 9.0
    process.initial_velocity_max = 14.0
    process.gravity = Vector3(0.0, -4.0, 0.0)
    process.scale_min = 0.70
    process.scale_max = 1.25
    process.color = Color(0.78, 0.90, 1.0, 0.88)
    hail_particles.process_material = process

    var sphere := SphereMesh.new()
    sphere.radius = 0.028
    sphere.height = 0.056
    sphere.radial_segments = 6
    sphere.rings = 3

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.78, 0.90, 1.0, 0.88)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    sphere.material = material
    hail_particles.draw_pass_1 = sphere

    root.add_child(hail_particles)
    _sync_hail()

func _sync_hail() -> void:
    if hail_particles == null:
        return

    var temperature_ok := EnvironmentState.temperature_c > -2.0 and EnvironmentState.temperature_c < 12.0
    var exposure := clampf(EnvironmentState.local_exposure, 0.0, 1.0)
    var intensity := minf(EnvironmentState.rain_intensity, EnvironmentState.storm_intensity) * exposure
    var active := not EnvironmentState.is_underwater and exposure > 0.03 and temperature_ok and EnvironmentState.storm_intensity >= 0.82 and EnvironmentState.rain_intensity >= 0.28

    hail_particles.emitting = active
    hail_particles.amount_ratio = clampf(intensity, 0.0, 1.0) if active else 0.0

    var process := hail_particles.process_material as ParticleProcessMaterial
    if process != null:
        process.direction = Vector3(
            EnvironmentState.wind_direction.x * EnvironmentState.wind_strength * 0.34,
            -1.0,
            EnvironmentState.wind_direction.z * EnvironmentState.wind_strength * 0.34
        ).normalized()
