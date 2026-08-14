extends Node

# Local ambient biome effects. Emitters only exist around the player so the
# 64x64 km world does not pay for particles outside the active streaming area.

var root: Node3D
var mote_particles: GPUParticles3D
var firefly_particles: GPUParticles3D
var ash_particles: GPUParticles3D
var update_elapsed := 0.0
var ashen_peak_position := Vector2(14200.0, -12200.0)

func _ready() -> void:
    for poi in WorldData.poi_catalog():
        if String(poi.get("id", "")) == "ashen_peak":
            ashen_peak_position = poi.get("pos", ashen_peak_position)
            break
    set_process(true)

func _process(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    _ensure_emitters()
    if root == null:
        return
    root.global_position = player.global_position + Vector3.UP * 2.5
    update_elapsed += delta
    if update_elapsed >= 0.40:
        update_elapsed = 0.0
        _sync_ambience(player.global_position)

func _ensure_emitters() -> void:
    if root != null and is_instance_valid(root):
        return
    var host := get_tree().current_scene
    if host == null:
        return
    root = Node3D.new()
    root.name = "LocalAmbientVFX"
    host.add_child(root)
    mote_particles = _make_motes()
    firefly_particles = _make_fireflies()
    ash_particles = _make_ash()
    root.add_child(mote_particles)
    root.add_child(firefly_particles)
    root.add_child(ash_particles)

func _sync_ambience(player_position: Vector3) -> void:
    if mote_particles == null:
        return
    var underwater := EnvironmentState.is_underwater
    var xz := Vector2(player_position.x, player_position.z)
    var biome := WorldData.biome_at(xz)
    var hour := int(GameState.world_minutes / 60.0) % 24
    var night := hour >= 20 or hour < 5
    var calm_enough := EnvironmentState.rain_intensity < 0.28 and EnvironmentState.snow_intensity < 0.15

    mote_particles.emitting = not underwater and calm_enough and biome in ["forest", "plains", "taiga", "marsh"]
    firefly_particles.emitting = not underwater and night and EnvironmentState.temperature_c > 5.0 and EnvironmentState.rain_intensity < 0.40 and biome in ["forest", "marsh"]
    ash_particles.emitting = not underwater and xz.distance_to(ashen_peak_position) < 3600.0

    mote_particles.amount = 75 if biome in ["forest", "marsh"] else 48
    firefly_particles.amount = 46 if biome == "marsh" else 34
    var ash_distance := xz.distance_to(ashen_peak_position)
    ash_particles.amount = maxi(20, int(125.0 * clampf(1.0 - ash_distance / 3600.0, 0.0, 1.0)))

    var motes_process := mote_particles.process_material as ParticleProcessMaterial
    if motes_process != null:
        motes_process.direction = Vector3(EnvironmentState.wind_direction.x * 0.35, 0.12, EnvironmentState.wind_direction.z * 0.35).normalized()
        motes_process.initial_velocity_max = 0.28 + EnvironmentState.wind_strength * 0.75
    var firefly_process := firefly_particles.process_material as ParticleProcessMaterial
    if firefly_process != null:
        firefly_process.direction = Vector3(EnvironmentState.wind_direction.x * 0.12, 0.18, EnvironmentState.wind_direction.z * 0.12).normalized()
    var ash_process := ash_particles.process_material as ParticleProcessMaterial
    if ash_process != null:
        ash_process.direction = Vector3(EnvironmentState.wind_direction.x * 0.65, -0.45, EnvironmentState.wind_direction.z * 0.65).normalized()
        ash_process.initial_velocity_max = 0.7 + EnvironmentState.wind_strength * 1.5

func _make_motes() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "BiomeMotes"
    particles.amount = 60
    particles.lifetime = 5.0
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-12, -8, -12), Vector3(24, 16, 24))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(9.0, 3.0, 9.0)
    process.direction = Vector3(0.2, 0.15, 0.1).normalized()
    process.spread = 150.0
    process.initial_velocity_min = 0.05
    process.initial_velocity_max = 0.35
    process.gravity = Vector3.ZERO
    process.scale_min = 0.45
    process.scale_max = 1.35
    process.color = Color(0.84, 0.88, 0.58, 0.38)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.026, 0.026)
    quad.material = _particle_material(Color(0.84, 0.88, 0.58, 0.38), true, 0.35)
    particles.draw_pass_1 = quad
    return particles

func _make_fireflies() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "Fireflies"
    particles.amount = 36
    particles.lifetime = 4.2
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-10, -7, -10), Vector3(20, 14, 20))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(7.0, 2.5, 7.0)
    process.direction = Vector3.UP
    process.spread = 170.0
    process.initial_velocity_min = 0.03
    process.initial_velocity_max = 0.22
    process.gravity = Vector3.ZERO
    process.scale_min = 0.60
    process.scale_max = 1.45
    process.color = Color(0.80, 1.0, 0.36, 0.92)
    particles.process_material = process

    var sphere := SphereMesh.new()
    sphere.radius = 0.022
    sphere.height = 0.044
    sphere.radial_segments = 6
    sphere.rings = 3
    sphere.material = _particle_material(Color(0.80, 1.0, 0.36, 0.92), false, 3.4)
    particles.draw_pass_1 = sphere
    return particles

func _make_ash() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "VolcanicAsh"
    particles.amount = 75
    particles.lifetime = 5.8
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-16, -12, -16), Vector3(32, 24, 32))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(12.0, 5.0, 12.0)
    process.direction = Vector3(0.3, -0.6, 0.1).normalized()
    process.spread = 58.0
    process.initial_velocity_min = 0.12
    process.initial_velocity_max = 0.85
    process.gravity = Vector3(0.0, -0.10, 0.0)
    process.scale_min = 0.55
    process.scale_max = 1.80
    process.color = Color(0.28, 0.27, 0.25, 0.56)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.045, 0.045)
    quad.material = _particle_material(Color(0.28, 0.27, 0.25, 0.56), true, 0.0)
    particles.draw_pass_1 = quad
    return particles

func _particle_material(color: Color, billboard: bool, emission_energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if billboard:
        material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = Color(color.r, color.g, color.b, 1.0)
        material.emission_energy_multiplier = emission_energy
    return material
