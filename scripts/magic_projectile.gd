extends Node3D

var spell_id: String = ""
var element: String = "arcane"
var damage := 0.0
var speed := 18.0
var lifetime := 3.0
var status_name: String = ""
var status_duration := 0.0
var explosion_radius := 0.0
var caster: Node3D
var direction := Vector3.FORWARD
var elapsed := 0.0
var trail_elapsed := 0.0

func setup(data: Dictionary, source: Node3D, cast_direction: Vector3) -> void:
    spell_id = String(data.get("id", "arcane_bolt"))
    element = String(data.get("element", "arcane"))
    damage = float(data.get("damage", 0.0))
    speed = float(data.get("speed", 18.0))
    lifetime = float(data.get("lifetime", 3.0))
    status_name = String(data.get("status", ""))
    status_duration = float(data.get("status_duration", 0.0))
    explosion_radius = float(data.get("explosion_radius", 0.0))
    caster = source
    direction = cast_direction.normalized() if cast_direction.length_squared() > 0.001 else Vector3.FORWARD
    _build_visual(data)

func _physics_process(delta: float) -> void:
    elapsed += delta
    trail_elapsed += delta
    if elapsed >= lifetime:
        _finish(global_position, -direction)
        return

    var from := global_position
    var to := from + direction * speed * delta
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    if caster is CollisionObject3D:
        query.exclude = [caster.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var collider = hit.get("collider")
        var hit_position: Vector3 = hit.get("position", to)
        var hit_normal: Vector3 = hit.get("normal", -direction)
        MagicSystem.resolve_projectile_hit(spell_id, element, damage, status_name, status_duration, explosion_radius, collider, hit_position, hit_normal, caster)
        _finish(hit_position, hit_normal)
        return

    global_position = to
    if trail_elapsed >= 0.18:
        trail_elapsed = 0.0
        VFXLibrary.spawn_magic(element, global_position, get_tree().current_scene, 0.28)

func _finish(position: Vector3, normal: Vector3) -> void:
    VFXLibrary.spawn_magic(element, position, get_tree().current_scene, 0.70)
    if element == "fire":
        VFXLibrary.spawn_explosion(position, "small", get_tree().current_scene, 0.55)
    elif element == "frost":
        VFXLibrary.spawn("magic_frost", position, get_tree().current_scene, normal, direction, 0.75)
    queue_free()

func _build_visual(data: Dictionary) -> void:
    var color: Color = data.get("color", Color(0.45, 0.18, 1.0, 1.0))
    var radius := float(data.get("visual_radius", 0.14))

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "SpellOrb"
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    sphere.radial_segments = 12
    sphere.rings = 6
    mesh_instance.mesh = sphere

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 3.5
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var light := OmniLight3D.new()
    light.name = "SpellLight"
    light.light_color = color
    light.light_energy = 1.8
    light.omni_range = 2.4
    light.shadow_enabled = false
    add_child(light)
