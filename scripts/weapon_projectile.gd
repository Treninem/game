extends Node3D

const ARROW := preload("res://assets/production/weapons/woodland/Arrow.glb")
var source: CharacterBody3D
var velocity := Vector3.ZERO
var elapsed := 0.0

func setup(caster: CharacterBody3D, direction: Vector3) -> void:
    source = caster
    velocity = direction * 35.0
    add_to_group("weapon_projectile")
    var visual := ARROW.instantiate() as Node3D
    visual.rotation.x = -PI * 0.5
    add_child(visual)
    look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
    elapsed += delta
    if elapsed > 3.0 or not is_instance_valid(source):
        queue_free()
        return
    var target := global_position + velocity * delta
    var query := PhysicsRayQueryParameters3D.create(global_position, target, 1, [source.get_rid()])
    query.collide_with_areas = false
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var collider: Object = hit["collider"]
        if collider.has_method("take_damage"):
            collider.take_damage(20.0, source)
        WorldVFX.spawn_impact(WorldVFX.surface_from_collider(collider, hit["position"]), hit["position"], hit["normal"], velocity.normalized(), 0.4)
        queue_free()
        return
    global_position = target
    velocity.y -= 4.9 * delta
    look_at(global_position + velocity, Vector3.UP)
