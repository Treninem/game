extends Node

# Local nature phenomena beyond rain/snow: ground mist, wind-blown leaves,
# sea spray and visible cold breath. Everything follows the active player.

var root: Node3D
var mist_particles: GPUParticles3D
var leaf_particles: GPUParticles3D
var spray_particles: GPUParticles3D
var update_elapsed := 0.0
var breath_elapsed := 0.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    _ensure_emitters()
    if root == null:
        return

    root.global_position = player.global_position + Vector3.UP * 1.2
    update_elapsed += delta
    breath_elapsed += delta
    if update_elapsed >= 0.35:
        update_elapsed = 0.0
        _sync_nature(player.global_position)

    if not EnvironmentState.is_underwater and EnvironmentState.temperature_c <= 1.5 and breath_elapsed >= 2.4:
        breath_elapsed = 0.0
        _spawn_cold_breath(player)

func _ensure_emitters() -> void:
    if root != null and is_instance_valid(root):
        return
    var host := get_tree().current_scene
    if host == null:
        return
    root = Node3D.new()
    root.name = "LocalNatureVFX"
    host.add_child(root)
    mist_particles = _make_mist()
    leaf_particles = _make_leaves()
    spray_particles = _make_sea_spray()
    root.add_child(mist_particles)
    root.add_child(leaf_particles)
    root.add_child(spray_particles)

func _sync_nature(player_position: Vector3) -> void:
    if mist_particles == null:
        return
    var xz := Vector2(player_position.x, player_position.z)
    var biome := WorldData.biome_at(xz)
    var underwater := EnvironmentState.is_underwater
    var wind := EnvironmentState.wind_strength

    var mist_biome := biome in ["marsh", "forest", "taiga"]
    mist_particles.emitting = not underwater and mist_biome and (EnvironmentState.fog_density > 0.06 or EnvironmentState.wetness > 0.42)
    var mist_factor := maxf(EnvironmentState.fog_density, EnvironmentState.wetness * 0.55)
    mist_particles.amount = maxi(18, int(35.0 + 95.0 * mist_factor))

    leaf_particles.emitting = not underwater and biome in ["forest", "taiga"] and wind > 0.22 and EnvironmentState.rain_intensity < 0.60
    leaf_particles.amount = maxi(16, int(28.0 + 95.0 * wind))

    var near_sea := biome == "ocean" and absf(player_position.y - WorldData.SEA_LEVEL) < 8.0
    spray_particles.emitting = not underwater and near_sea and wind > 0.18
    spray_particles.amount = maxi(18, int(32.0 + 120.0 * wind + 70.0 * EnvironmentState.storm_intensity))

    var mist_process := mist_particles.process_material as ParticleProcessMaterial
    if mist_process != null:
        mist_process.direction = Vector3(EnvironmentState.wind_direction.x * 0.50, 0.05, EnvironmentState.wind_direction.z * 0.50).normalized()
        mist_process.initial_velocity_max = 0.18 + wind * 0.75

    var leaf_process := leaf_particles.process_material as ParticleProcessMaterial
    if leaf_process != null:
        leaf_process.direction = Vector3(EnvironmentState.wind_direction.x, 0.12, EnvironmentState.wind_direction.z).normalized()
        leaf_process.initial_velocity_min = 0.8 + wind * 1.3
        leaf_process.initial_velocity_max = 1.8 + wind * 3.4

    var spray_process := spray_particles.process_material as ParticleProcessMaterial
    if spray_process != null:
        spray_process.direction = Vector3(EnvironmentState.wind_direction.x * 0.65, 0.85, EnvironmentState.wind_direction.z * 0.65).normalized()
        spray_process.initial_velocity_max = 2.0 + wind * 3.0 + EnvironmentState.storm_intensity * 2.5

func _make_mist() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "GroundMist"
    particles.amount = 70
    particles.lifetime = 5.5
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-16, -5, -16), Vector3(32, 10, 32))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(11.0, 0.55, 11.0)
    process.direction = Vector3(0.4, 0.04, 0.1).normalized()
    process.spread = 80.0
    process.initial_velocity_min = 0.03
    process.initial_velocity_max = 0.35
    process.gravity = Vector3.ZERO
    process.scale_min = 1.0
    process.scale_max = 3.4
    process.color = Color(0.76, 0.82, 0.80, 0.11)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(1.25, 0.46)
    quad.material = _material(Color(0.76, 0.82, 0.80, 0.11), true)
    particles.draw_pass_1 = quad
    return particles

func _make_leaves() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "WindLeaves"
    particles.amount = 55
    particles.lifetime = 3.6
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-15, -8, -15), Vector3(30, 16, 30))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(10.0, 3.0, 10.0)
    process.direction = Vector3.RIGHT
    process.spread = 30.0
    process.initial_velocity_min = 1.0
    process.initial_velocity_max = 3.2
    process.gravity = Vector3(0.0, -0.55, 0.0)
    process.scale_min = 0.60
    process.scale_max = 1.35
    process.color = Color(0.42, 0.56, 0.18, 0.74)
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.095, 0.045)
    quad.material = _material(Color(0.42, 0.56, 0.18, 0.74), true)
    particles.draw_pass_1 = quad
    return particles

func _make_sea_spray() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "SeaSpray"
    particles.amount = 65
    particles.lifetime = 1.5
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-14, -7, -14), Vector3(28, 14, 28))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(9.0, 0.6, 9.0)
    process.direction = Vector3(0.1, 0.95, 0.1).normalized()
    process.spread = 48.0
    process.initial_velocity_min = 0.8
    process.initial_velocity_max = 3.2
    process.gravity = Vector3(0.0, -2.5, 0.0)
    process.scale_min = 0.45
    process.scale_max = 1.25
    process.color = Color(0.78, 0.91, 1.0, 0.48)
    particles.process_material = process

    var sphere := SphereMesh.new()
    sphere.radius = 0.028
    sphere.height = 0.056
    sphere.radial_segments = 6
    sphere.rings = 3
    sphere.material = _material(Color(0.78, 0.91, 1.0, 0.48), false)
    particles.draw_pass_1 = sphere
    return particles

func _spawn_cold_breath(player: Node3D) -> void:
    var host := get_tree().current_scene
    if host == null:
        return
    var forward := -player.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() < 0.001:
        forward = Vector3.FORWARD
    var point := player.global_position + Vector3.UP * 1.55 + forward.normalized() * 0.35
    WorldVFX.spawn_environment_effect("steam", point, 0.30)

func _material(color: Color, billboard: bool) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if billboard:
        material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    return material
