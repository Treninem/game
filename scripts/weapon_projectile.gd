extends Node3D

const ARROW := preload("res://scripts/weapon_model_catalog.gd").ARROW
const SHAFT_LENGTH := 0.70
var source: CharacterBody3D
var velocity := Vector3.ZERO
var elapsed := 0.0
var first_sweep := true

func setup(caster: CharacterBody3D, direction: Vector3) -> void:
    source = caster
    var heading := direction.normalized()
    if heading.is_zero_approx():
        heading = -caster.global_basis.orthonormalized().z
    velocity = heading * 35.0
    first_sweep = true
    add_to_group("weapon_projectile")
    var visual := Node3D.new()
    visual.name = "ArrowVisual"
    visual.rotation.x = -PI * 0.5
    visual.position.z = -SHAFT_LENGTH * 0.5
    visual.add_child(ARROW.instantiate())
    add_child(visual)
    global_basis = _flight_basis(heading)

func _flight_basis(heading: Vector3) -> Basis:
    # Exact vertical shots need an up axis distinct from the flight axis.
    var up := Vector3.FORWARD if absf(heading.dot(Vector3.UP)) > 0.999 else Vector3.UP
    return Basis.looking_at(heading, up)

func _physics_process(delta: float) -> void:
    elapsed += delta
    if elapsed > 3.0 or not is_instance_valid(source):
        queue_free()
        return
    var target := global_position + velocity * delta
    var next_velocity := velocity + Vector3.DOWN * 4.9 * delta
    var next_basis := _flight_basis(next_velocity.normalized())
    # The projectile origin is its tail/launch point. Sweep the rendered tip,
    # including its rotation under gravity, rather than the trailing origin.
    # On launch cover the initial shaft span too, so a nearby wall cannot be
    # skipped merely because the first rendered tip already lies beyond it.
    var from := global_position if first_sweep else global_position - global_basis.z * SHAFT_LENGTH
    var to := target - next_basis.z * SHAFT_LENGTH
    var query := PhysicsRayQueryParameters3D.create(from, to, 1, [source.get_rid()])
    query.collide_with_areas = false
    query.hit_from_inside = true
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var collider: Object = hit["collider"]
        if collider.has_method("take_damage"):
            collider.take_damage(20.0, source)
        WorldVFX.spawn_impact(WorldVFX.surface_from_collider(collider, hit["position"]), hit["position"], hit["normal"], velocity.normalized(), 0.4)
        queue_free()
        return
    first_sweep = false
    global_position = target
    velocity = next_velocity
    global_basis = next_basis
