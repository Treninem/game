extends Node

# Camera/local weather VFX. Emitters follow the player but keep spawned particles
# in world coordinates so large-world streaming does not need global weather nodes.

var root: Node3D
var rain_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var dust_particles: GPUParticles3D
var bubble_particles: GPUParticles3D
var splash_elapsed := 0.0
var update_elapsed := 0.0
var storm_elapsed := 0.0
var next_storm_flash := 6.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    _ensure_emitters()
    if root == null:
        return

    root.global_position = player.global_position + Vector3.UP * 8.0
    splash_elapsed += delta
    update_elapsed += delta
    if update_elapsed >= 0.20:
        update_elapsed = 0.0
        _sync_weather()

    if EnvironmentState.rain_intensity > 0.20 and not EnvironmentState.is_underwater:
        var interval := lerpf(0.42, 0.07, EnvironmentState.rain_intensity)
        if splash_elapsed >= interval:
            splash_elapsed = 0.0
            _spawn_rain_splash(player.global_position)

    _update_storm(delta)

func _update_storm(delta: float) -> void:
    if EnvironmentState.is_underwater or EnvironmentState.storm_intensity <= 0.12:
        storm_elapsed = 0.0
        return
    storm_elapsed += delta
    if storm_elapsed < next_storm_flash:
        return
    storm_elapsed = 0.0
    var storm := clampf(EnvironmentState.storm_intensity, 0.12, 1.0)
    next_storm_flash = randf_range(3.2, 9.0) / maxf(storm, 0.35)
    ScreenVFX.lightning_flash(0.55 + storm * 0.75)

func _ensure_emitters() -> void:
    if root != null and is_instance_valid(root):
        return
    var host := get_tree().current_scene
    if host == null:
        return
    root = Node3D.new()
    root.name = "LocalWeatherVFX"
    host.add_child(root)
    rain_particles = _make_rain()
    snow_particles = _make_snow()
    dust_particles = _make_dust()
    bubble_particles = _make_bubbles()
    root.add_child(rain_particles)
    root.add_child(snow_particles)
    root.add_child(dust_particles)
    root.add_child(bubble_particles)
    _sync_weather()

func _sync_weather() -> void:
    if rain_particles == null:
        return
    var underwater := EnvironmentState.is_underwater
    rain_particles.emitting = EnvironmentState.rain_intensity > 0.03 and not underwater
    snow_particles.emitting = EnvironmentState.snow_intensity > 0.03 and not underwater
    dust_particles.emitting = EnvironmentState.dust_amount > 0.08 and EnvironmentState.rain_intensity < 0.10 and not underwater
    bubble_particles.emitting = underwater

    rain_particles.amount = maxi(24, int(90.0 + 360.0 * EnvironmentState.rain_intensity))
    snow_particles.amount = maxi(18, int(60.0 + 240.0 * EnvironmentState.snow_intensity))
    dust_particles.amount = maxi(12, int(35.0 + 130.0 * EnvironmentState.dust_amount))
    bubble_particles.amount = 80 if underwater else 1

    var rain_process := rain_particles.process_material as ParticleProcessMaterial
    if rain_process != null:
        rain_process.direction = Vector3(EnvironmentState.wind_direction.x * EnvironmentState.wind_strength * 0.20, -1.0, EnvironmentState.wind_direction.z * EnvironmentState.wind_strength * 0.20).normalized()
    var snow_process := snow_particles.process_material as ParticleProcessMaterial
    if snow_process != null:
        snow_process.direction = Vector3(EnvironmentState.wind_direction.x * EnvironmentState.wind_strength * 0.75, -0.55, EnvironmentState.wind_direction.z * EnvironmentState.wind_strength * 0.75).normalized()
    var dust_process := dust_particles.process_material as ParticleProcessMaterial
    if dust_process != null:
        dust_process.direction = Vector3(EnvironmentState.wind_direction.x, 0.16, EnvironmentState.wind_direction.z).normalized()

func _make_rain() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "Rain"
    particles.amount = 180
    particles.lifetime = 1.25
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-18, -16, -18), Vector3(36, 32, 36))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(13.0, 1.0, 13.0)
    process.direction = Vector3.DOWN
    process.spread = 4.0
    process.initial_velocity_min = 18.0
    process.initial_velocity_max = 25.0
    process.gravity = Vector3(0.0, -7.0, 0.0)
    process.scale_min = 0.75
    process.scale_max = 1.15
    process.color = Color(0.62, 0.78, 0.92, 0.62)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.026, 0.62)
    quad.material = _particle_material(Color(0.62, 0.78, 0.92, 0.62), false)
    particles.draw_pass_1 = quad
    return particles

func _make_snow() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "Snow"
    particles.amount = 120
    particles.lifetime = 4.5
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-18, -18, -18), Vector3(36, 36, 36))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(13.0, 2.0, 13.0)
    process.direction = Vector3(0.0, -0.8, 0.0)
    process.spread = 38.0
    process.initial_velocity_min = 0.7
    process.initial_velocity_max = 1.8
    process.gravity = Vector3(0.0, -0.55, 0.0)
    process.scale_min = 0.55
    process.scale_max = 1.35
    process.color = Color(0.96, 0.98, 1.0, 0.86)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.095, 0.095)
    quad.material = _particle_material(Color(0.96, 0.98, 1.0, 0.86), true)
    particles.draw_pass_1 = quad
    return particles

func _make_dust() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "Dust"
    particles.amount = 60
    particles.lifetime = 3.4
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-20, -10, -20), Vector3(40, 20, 40))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(14.0, 2.5, 14.0)
    process.direction = Vector3(1.0, 0.15, 0.0)
    process.spread = 32.0
    process.initial_velocity_min = 0.5
    process.initial_velocity_max = 2.2
    process.gravity = Vector3(0.0, 0.04, 0.0)
    process.scale_min = 0.45
    process.scale_max = 1.8
    process.color = Color(0.69, 0.58, 0.39, 0.32)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.16, 0.16)
    quad.material = _particle_material(Color(0.69, 0.58, 0.39, 0.32), true)
    particles.draw_pass_1 = quad
    return particles

func _make_bubbles() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "UnderwaterBubbles"
    particles.amount = 80
    particles.lifetime = 3.1
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(6.0, 2.0, 6.0)
    process.direction = Vector3.UP
    process.spread = 28.0
    process.initial_velocity_min = 0.4
    process.initial_velocity_max = 1.5
    process.gravity = Vector3(0.0, 0.45, 0.0)
    process.scale_min = 0.30
    process.scale_max = 1.10
    process.color = Color(0.72, 0.92, 1.0, 0.52)
    particles.process_material = process

    var sphere := SphereMesh.new()
    sphere.radius = 0.025
    sphere.height = 0.05
    sphere.radial_segments = 6
    sphere.rings = 3
    sphere.material = _particle_material(Color(0.72, 0.92, 1.0, 0.52), false)
    particles.draw_pass_1 = sphere
    return particles

func _spawn_rain_splash(player_position: Vector3) -> void:
    var angle := randf() * TAU
    var distance := randf_range(1.5, 10.0)
    var sample := player_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
    var xz := Vector2(sample.x, sample.z)
    if not WorldData.inside_world(xz):
        return
    var terrain_y := WorldData.elevation_at(xz)
    var point := Vector3(sample.x, terrain_y + 0.05, sample.z)
    var surface := WorldVFX.surface_at(point)
    if surface in ["water", "mud"]:
        WorldVFX.spawn_environment_effect("splash", point, 0.30 + EnvironmentState.rain_intensity * 0.35)
    elif EnvironmentState.rain_intensity > 0.55:
        VFXLibrary.spawn_collision("water", point, Vector3.UP, get_tree().current_scene, 0.18 + EnvironmentState.rain_intensity * 0.18)

func _particle_material(color: Color, billboard: bool) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if billboard:
        material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    return material
