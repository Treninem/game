extends Node

# Lightweight project-owned VFX library for Godot 4.7 / GL Compatibility.
# Effects are procedural so the game has usable combat/magic feedback even
# before optional third-party sprite packs are physically imported.

const FX_LIFETIME_MAX := 3.0

const COLORS := {
    "arcane": Color(0.45, 0.18, 1.0, 1.0),
    "fire": Color(1.0, 0.24, 0.04, 1.0),
    "fire_hot": Color(1.0, 0.72, 0.12, 1.0),
    "frost": Color(0.25, 0.82, 1.0, 1.0),
    "lightning": Color(0.56, 0.82, 1.0, 1.0),
    "poison": Color(0.32, 0.95, 0.24, 1.0),
    "heal": Color(0.25, 1.0, 0.58, 1.0),
    "holy": Color(1.0, 0.88, 0.38, 1.0),
    "dark": Color(0.26, 0.04, 0.42, 1.0),
    "bloodless_hit": Color(1.0, 0.68, 0.25, 1.0),
    "metal": Color(0.78, 0.88, 1.0, 1.0),
    "stone": Color(0.52, 0.50, 0.46, 1.0),
    "wood": Color(0.55, 0.30, 0.12, 1.0),
    "dirt": Color(0.43, 0.27, 0.12, 1.0),
    "glass": Color(0.68, 0.95, 1.0, 1.0),
    "water": Color(0.16, 0.60, 1.0, 1.0),
    "smoke": Color(0.20, 0.21, 0.24, 0.72),
}

func spawn(
        kind: StringName,
        world_position: Vector3,
        parent: Node = null,
        normal: Vector3 = Vector3.UP,
        direction: Vector3 = Vector3.ZERO,
        strength: float = 1.0
    ) -> Node3D:
    var host := parent if parent != null else get_tree().current_scene
    if host == null:
        return null

    var root := Node3D.new()
    root.name = "VFX_%s" % String(kind)
    host.add_child(root)
    root.global_position = world_position

    var s := clampf(strength, 0.25, 4.0)
    match String(kind):
        "magic_arcane":
            _magic_arcane(root, s)
        "magic_fire":
            _magic_fire(root, s)
        "magic_frost":
            _magic_frost(root, s)
        "magic_lightning":
            _magic_lightning(root, s, direction)
        "magic_poison":
            _magic_poison(root, s)
        "magic_heal":
            _magic_heal(root, s)
        "magic_holy":
            _magic_holy(root, s)
        "magic_dark":
            _magic_dark(root, s)
        "magic_portal":
            _magic_portal(root, s)
        "magic_shield":
            _magic_shield(root, s)
        "melee_swing":
            _melee_swing(root, s, direction)
        "hit_slash":
            _hit_slash(root, s, normal)
        "hit_blunt":
            _hit_blunt(root, s, normal)
        "hit_block":
            _hit_block(root, s)
        "hit_critical":
            _hit_critical(root, s, normal)
        "explosion_small":
            _explosion(root, 0.65 * s)
        "explosion_medium":
            _explosion(root, 1.0 * s)
        "explosion_large":
            _explosion(root, 1.65 * s)
        "collision_metal":
            _collision(root, COLORS.metal, 18, 5.0 * s, normal)
        "collision_stone":
            _collision(root, COLORS.stone, 15, 3.2 * s, normal)
        "collision_wood":
            _collision(root, COLORS.wood, 13, 2.7 * s, normal)
        "collision_dirt":
            _collision(root, COLORS.dirt, 16, 2.2 * s, normal)
        "collision_glass":
            _collision(root, COLORS.glass, 24, 5.5 * s, normal)
        "collision_water":
            _collision_water(root, s)
        "death_burst":
            _death_burst(root, s)
        _:
            _burst(root, 12, COLORS.arcane, 0.05 * s, 0.8, 2.8 * s, Vector3(0, -2.0, 0), 0.75)

    _expire(root, FX_LIFETIME_MAX)
    return root

func spawn_magic(element: String, world_position: Vector3, parent: Node = null, strength: float = 1.0) -> Node3D:
    return spawn(StringName("magic_" + element.to_lower()), world_position, parent, Vector3.UP, Vector3.ZERO, strength)

func spawn_explosion(world_position: Vector3, size: String = "medium", parent: Node = null, strength: float = 1.0) -> Node3D:
    var safe_size := size.to_lower()
    if safe_size not in ["small", "medium", "large"]:
        safe_size = "medium"
    return spawn(StringName("explosion_" + safe_size), world_position, parent, Vector3.UP, Vector3.ZERO, strength)

func spawn_collision(material_type: String, world_position: Vector3, normal: Vector3 = Vector3.UP, parent: Node = null, strength: float = 1.0) -> Node3D:
    var safe_type := material_type.to_lower()
    if safe_type not in ["metal", "stone", "wood", "dirt", "glass", "water"]:
        safe_type = "stone"
    return spawn(StringName("collision_" + safe_type), world_position, parent, normal, Vector3.ZERO, strength)

func _magic_arcane(root: Node3D, s: float) -> void:
    _flash(root, COLORS.arcane, 2.0 * s, 4.5 * s, 0.22)
    _burst(root, 28, COLORS.arcane, 0.12 * s, 1.3, 5.2 * s, Vector3(0, -1.2, 0), 0.95)
    _burst(root, 14, COLORS.lightning, 0.05 * s, 0.9, 2.6 * s, Vector3.ZERO, 0.75)
    _shockwave(root, COLORS.arcane, 2.8 * s, 0.42)

func _magic_fire(root: Node3D, s: float) -> void:
    _flash(root, COLORS.fire_hot, 3.0 * s, 5.2 * s, 0.20)
    _burst(root, 30, COLORS.fire, 0.13 * s, 1.0, 5.8 * s, Vector3(0, 1.8, 0), 0.95)
    _burst(root, 16, COLORS.fire_hot, 0.07 * s, 0.7, 3.7 * s, Vector3(0, 1.2, 0), 0.70)
    _smoke(root, 12, 0.16 * s, 1.7 * s, 1.6)

func _magic_frost(root: Node3D, s: float) -> void:
    _flash(root, COLORS.frost, 1.8 * s, 4.0 * s, 0.18)
    _burst(root, 26, COLORS.frost, 0.07 * s, 1.1, 4.8 * s, Vector3(0, -0.8, 0), 0.95)
    _burst(root, 12, Color.WHITE, 0.035 * s, 0.8, 3.0 * s, Vector3(0, -1.5, 0), 0.75)
    _shockwave(root, COLORS.frost, 2.4 * s, 0.38)

func _magic_lightning(root: Node3D, s: float, direction: Vector3) -> void:
    var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector3.UP
    _flash(root, Color.WHITE, 4.5 * s, 5.5 * s, 0.12)
    _burst(root, 34, COLORS.lightning, 0.035 * s, 0.55, 8.5 * s, Vector3.ZERO, 0.62, dir)
    _burst(root, 14, Color.WHITE, 0.025 * s, 0.40, 6.0 * s, Vector3.ZERO, 0.50, dir)

func _magic_poison(root: Node3D, s: float) -> void:
    _burst(root, 20, COLORS.poison, 0.10 * s, 1.6, 2.4 * s, Vector3(0, 0.7, 0), 0.85)
    _smoke(root, 18, 0.14 * s, 1.2 * s, 1.9, Color(0.18, 0.52, 0.12, 0.62))
    _shockwave(root, COLORS.poison, 1.8 * s, 0.48)

func _magic_heal(root: Node3D, s: float) -> void:
    _flash(root, COLORS.heal, 1.3 * s, 3.8 * s, 0.30)
    _burst(root, 24, COLORS.heal, 0.055 * s, 1.5, 2.2 * s, Vector3(0, 2.4, 0), 1.15, Vector3.UP, 28.0)
    _burst(root, 10, COLORS.holy, 0.035 * s, 1.1, 1.5 * s, Vector3(0, 1.8, 0), 0.90, Vector3.UP, 20.0)

func _magic_holy(root: Node3D, s: float) -> void:
    _flash(root, COLORS.holy, 3.3 * s, 5.0 * s, 0.24)
    _burst(root, 30, COLORS.holy, 0.06 * s, 1.0, 5.0 * s, Vector3(0, -0.5, 0), 0.85)
    _burst(root, 18, Color.WHITE, 0.035 * s, 0.8, 3.2 * s, Vector3(0, 0.8, 0), 0.65)
    _shockwave(root, COLORS.holy, 3.0 * s, 0.40)

func _magic_dark(root: Node3D, s: float) -> void:
    _burst(root, 28, COLORS.dark, 0.13 * s, 1.5, 3.7 * s, Vector3(0, 0.3, 0), 1.0)
    _burst(root, 10, COLORS.arcane, 0.04 * s, 0.8, 2.0 * s, Vector3.ZERO, 0.65)
    _shockwave(root, COLORS.dark, 2.6 * s, 0.55)

func _magic_portal(root: Node3D, s: float) -> void:
    _flash(root, COLORS.arcane, 1.1 * s, 3.0 * s, 0.30)
    _shockwave(root, COLORS.arcane, 2.4 * s, 0.85)
    _shockwave(root, COLORS.lightning, 1.7 * s, 0.60)
    _burst(root, 34, COLORS.arcane, 0.045 * s, 1.8, 1.5 * s, Vector3(0, 0.25, 0), 1.2)

func _magic_shield(root: Node3D, s: float) -> void:
    _flash(root, COLORS.lightning, 1.2 * s, 2.8 * s, 0.18)
    _shockwave(root, Color(0.32, 0.68, 1.0, 0.45), 1.7 * s, 0.65)
    _burst(root, 16, COLORS.lightning, 0.035 * s, 0.75, 1.4 * s, Vector3.ZERO, 0.55)

func _melee_swing(root: Node3D, s: float, direction: Vector3) -> void:
    var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector3.FORWARD
    _slash_mesh(root, Color(0.78, 0.88, 1.0, 0.58), dir, 1.15 * s, 0.15)
    _burst(root, 5, COLORS.metal, 0.025 * s, 0.30, 1.3 * s, Vector3.ZERO, 0.28, dir, 30.0)

func _hit_slash(root: Node3D, s: float, normal: Vector3) -> void:
    _flash(root, COLORS.bloodless_hit, 1.3 * s, 2.5 * s, 0.10)
    _burst(root, 18, COLORS.bloodless_hit, 0.035 * s, 0.45, 5.5 * s, Vector3(0, -3.0, 0), 0.50, normal, 65.0)
    _slash_mesh(root, Color(1.0, 0.84, 0.44, 0.72), normal, 0.75 * s, 0.12)

func _hit_blunt(root: Node3D, s: float, normal: Vector3) -> void:
    _flash(root, Color.WHITE, 0.8 * s, 2.2 * s, 0.10)
    _burst(root, 12, COLORS.stone, 0.045 * s, 0.40, 3.3 * s, Vector3(0, -3.8, 0), 0.48, normal, 85.0)
    _shockwave(root, Color(0.85, 0.82, 0.72, 0.45), 0.8 * s, 0.18)

func _hit_block(root: Node3D, s: float) -> void:
    _flash(root, COLORS.metal, 1.0 * s, 2.6 * s, 0.10)
    _burst(root, 24, COLORS.metal, 0.022 * s, 0.38, 6.5 * s, Vector3(0, -4.0, 0), 0.45)
    _shockwave(root, Color(0.55, 0.75, 1.0, 0.50), 0.9 * s, 0.20)

func _hit_critical(root: Node3D, s: float, normal: Vector3) -> void:
    _flash(root, COLORS.holy, 2.7 * s, 4.0 * s, 0.14)
    _burst(root, 38, COLORS.holy, 0.035 * s, 0.65, 8.0 * s, Vector3(0, -4.2, 0), 0.62, normal, 90.0)
    _shockwave(root, COLORS.holy, 1.7 * s, 0.24)

func _explosion(root: Node3D, s: float) -> void:
    _flash(root, COLORS.fire_hot, 5.0 * s, 7.0 * s, 0.16)
    _burst(root, int(34 * s + 10), COLORS.fire_hot, 0.07 * s, 0.8, 7.5 * s, Vector3(0, -4.5, 0), 0.72)
    _burst(root, int(26 * s + 8), COLORS.fire, 0.10 * s, 1.0, 5.0 * s, Vector3(0, 0.8, 0), 0.90)
    _burst(root, int(18 * s + 6), COLORS.stone, 0.04 * s, 0.9, 7.2 * s, Vector3(0, -9.5, 0), 0.90)
    _smoke(root, int(18 * s + 8), 0.14 * s, 2.0 * s, 2.0)
    _shockwave(root, Color(1.0, 0.55, 0.12, 0.52), 3.4 * s, 0.34)

func _collision(root: Node3D, color: Color, count: int, speed: float, normal: Vector3) -> void:
    _burst(root, count, color, 0.032, 0.55, speed, Vector3(0, -6.5, 0), 0.58, normal, 85.0)
    if color == COLORS.stone or color == COLORS.dirt:
        _smoke(root, 7, 0.07, 0.75, 0.85, Color(color.r * 0.65, color.g * 0.65, color.b * 0.65, 0.55))

func _collision_water(root: Node3D, s: float) -> void:
    _burst(root, 24, COLORS.water, 0.028 * s, 0.75, 4.6 * s, Vector3(0, -8.0, 0), 0.65, Vector3.UP, 62.0)
    _shockwave(root, Color(0.20, 0.68, 1.0, 0.42), 1.35 * s, 0.45)

func _death_burst(root: Node3D, s: float) -> void:
    _burst(root, 22, Color(0.52, 0.12, 0.08, 1.0), 0.055 * s, 0.8, 3.8 * s, Vector3(0, -4.0, 0), 0.68)
    _burst(root, 10, COLORS.smoke, 0.10 * s, 1.2, 1.8 * s, Vector3(0, 0.8, 0), 0.95)

func _burst(
        root: Node3D,
        count: int,
        color: Color,
        particle_size: float,
        lifetime: float,
        speed: float,
        gravity: Vector3,
        radius: float,
        direction: Vector3 = Vector3.UP,
        spread: float = 180.0
    ) -> void:
    var particles := GPUParticles3D.new()
    particles.amount = clampi(count, 1, 160)
    particles.lifetime = maxf(lifetime, 0.08)
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.randomness = 0.72
    particles.local_coords = false
    particles.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius = maxf(radius * 0.12, 0.01)
    process.direction = direction.normalized() if direction.length_squared() > 0.001 else Vector3.UP
    process.spread = clampf(spread, 0.0, 180.0)
    process.initial_velocity_min = speed * 0.55
    process.initial_velocity_max = speed
    process.gravity = gravity
    process.scale_min = 0.70
    process.scale_max = 1.35
    process.color = color
    particles.process_material = process

    var mesh := SphereMesh.new()
    mesh.radius = maxf(particle_size, 0.008)
    mesh.height = mesh.radius * 2.0
    mesh.radial_segments = 6
    mesh.rings = 3
    mesh.material = _material(color, 2.3, color.a)
    particles.draw_pass_1 = mesh

    root.add_child(particles)
    particles.emitting = true

func _smoke(root: Node3D, count: int, particle_size: float, speed: float, lifetime: float, color: Color = Color(0.20, 0.21, 0.24, 0.58)) -> void:
    _burst(root, count, color, particle_size, lifetime, speed, Vector3(0, 0.9, 0), 0.85, Vector3.UP, 110.0)

func _flash(root: Node3D, color: Color, energy: float, radius: float, duration: float) -> void:
    var light := OmniLight3D.new()
    light.light_color = Color(color.r, color.g, color.b, 1.0)
    light.light_energy = maxf(energy, 0.1)
    light.omni_range = maxf(radius, 0.5)
    light.shadow_enabled = false
    root.add_child(light)

    var glow := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.10
    sphere.height = 0.20
    sphere.radial_segments = 8
    sphere.rings = 4
    sphere.material = _material(Color(color.r, color.g, color.b, 0.85), 4.0, 0.85)
    glow.mesh = sphere
    root.add_child(glow)

    var tween := root.create_tween().set_parallel(true)
    tween.tween_property(light, "light_energy", 0.0, maxf(duration, 0.05))
    tween.tween_property(glow, "scale", Vector3.ONE * maxf(radius * 0.22, 0.4), maxf(duration, 0.05))
    _expire(light, duration + 0.03)
    _expire(glow, duration + 0.03)

func _shockwave(root: Node3D, color: Color, radius: float, duration: float) -> void:
    var wave := MeshInstance3D.new()
    var disc := CylinderMesh.new()
    disc.top_radius = 1.0
    disc.bottom_radius = 1.0
    disc.height = 0.025
    disc.radial_segments = 32
    disc.material = _material(Color(color.r, color.g, color.b, minf(color.a, 0.48)), 2.4, minf(color.a, 0.48))
    wave.mesh = disc
    wave.scale = Vector3(0.12, 1.0, 0.12)
    root.add_child(wave)
    root.create_tween().tween_property(wave, "scale", Vector3(maxf(radius, 0.2), 1.0, maxf(radius, 0.2)), maxf(duration, 0.08))
    _expire(wave, duration + 0.04)

func _slash_mesh(root: Node3D, color: Color, direction: Vector3, length: float, duration: float) -> void:
    var slash := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.055, 0.36, maxf(length, 0.2))
    box.material = _material(color, 3.0, color.a)
    slash.mesh = box
    root.add_child(slash)
    var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector3.FORWARD
    slash.look_at(root.global_position + dir, Vector3.UP)
    slash.rotation.z = deg_to_rad(32.0)
    slash.scale = Vector3(0.25, 0.25, 0.25)
    root.create_tween().tween_property(slash, "scale", Vector3.ONE, maxf(duration, 0.06))
    _expire(slash, duration + 0.04)

func _material(color: Color, emission_energy: float = 2.0, alpha: float = 1.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    var c := Color(color.r, color.g, color.b, clampf(alpha, 0.02, 1.0))
    material.albedo_color = c
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = Color(color.r, color.g, color.b, 1.0)
    material.emission_energy_multiplier = maxf(emission_energy, 0.0)
    if c.a < 0.999:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

func _expire(node: Node, delay: float) -> void:
    if node == null or not is_instance_valid(node):
        return
    get_tree().create_timer(maxf(delay, 0.02)).timeout.connect(_free_if_valid.bind(node))

func _free_if_valid(node: Node) -> void:
    if is_instance_valid(node):
        node.queue_free()
