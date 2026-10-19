extends CharacterBody3D
const HUMANOID := preload("res://scripts/humanoid_visual.gd")

@export var enemy_id: String = ""
@export var max_health := 70.0
@export var move_speed := 3.2
@export var detection_range := 14.0
@export var attack_range := 1.8
@export var attack_damage := 8.0
@export var attack_interval := 1.25
@export var gravity := 18.0

var health := 70.0
var attack_elapsed := 0.0
var target: CharacterBody3D
var spawn_position := Vector3.ZERO
var statuses: Dictionary = {}
var status_tick_elapsed := 0.0
var track_distance_accum := 0.0
var ground_ready := false
var attack_windup := 0.0

func _ready() -> void:
    if enemy_id.is_empty():
        enemy_id = String(name)
    if bool(GameState.get_world_value("enemy:" + enemy_id, false)):
        queue_free()
        return
    health = max_health
    spawn_position = global_position
    add_to_group("hostile")
    floor_snap_length = 0.35
    if get_node_or_null("CollisionShape3D") == null:
        var collision := CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        collision.position.y = 0.9
        var capsule := CapsuleShape3D.new()
        capsule.height = 1.8
        capsule.radius = 0.35
        collision.shape = capsule
        add_child(collision)
    if get_node_or_null("Avatar") == null:
        var avatar := HUMANOID.new()
        avatar.name = "Avatar"
        avatar.primary_color = Color(0.28, 0.10, 0.07)
        avatar.secondary_color = Color(0.17, 0.14, 0.10)
        add_child(avatar)
    # Legacy spawners still provide primitive body meshes for their old
    # placeholders. Keep collision, but let the skinned human own appearance.
    for child in get_children():
        if child is MeshInstance3D and child.mesh is PrimitiveMesh:
            child.visible = false
    visible = false

func _physics_process(delta: float) -> void:
    if health <= 0.0:
        return
    if not ground_ready:
        var height := WorldData.elevation_at(Vector2(global_position.x, global_position.z))
        var query := PhysicsRayQueryParameters3D.create(Vector3(global_position.x, height + 2, global_position.z), Vector3(global_position.x, height - 2, global_position.z), 1, [get_rid()])
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if hit.is_empty() or not hit.collider is StaticBody3D:
            return
        global_position.y = Vector3(hit.position).y + 0.04
        ground_ready = true
        visible = true
    _update_statuses(delta)
    if health <= 0.0:
        return

    attack_elapsed = maxf(0.0, attack_elapsed - delta)
    if not is_on_floor():
        velocity.y -= gravity * delta

    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player") as CharacterBody3D

    if attack_windup > 0.0:
        attack_windup -= delta
        if attack_windup <= 0.0 and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range + 0.3 and _can_reach_target():
            var impact := (global_position - target.global_position).normalized()
            VFXLibrary.spawn("hit_blunt", target.global_position + Vector3.UP * 0.9, get_tree().current_scene, impact, -impact, 0.85)
            ScreenVFX.damage_feedback(attack_damage)
            GameState.apply_damage(attack_damage)

    if not is_instance_valid(target) or GameState.is_dead:
        _idle_return(delta)
        return

    var flat_to_player := target.global_position - global_position
    flat_to_player.y = 0.0
    var distance := flat_to_player.length()
    if distance > detection_range:
        _idle_return(delta)
        return

    var current_speed := move_speed * _status_speed_multiplier()
    if distance > attack_range:
        var direction := flat_to_player.normalized()
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
        if direction.length_squared() > 0.001:
            look_at(global_position + direction, Vector3.UP)
        _move_and_track(direction, 0.58, 2.35)
    else:
        velocity.x = move_toward(velocity.x, 0.0, current_speed * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, current_speed * 4.0 * delta)
        move_and_slide()
        track_distance_accum = 0.0
        if attack_elapsed <= 0.0:
            var interval_multiplier := 1.35 if statuses.has("shocked") else 1.0
            attack_elapsed = attack_interval * interval_multiplier
            attack_windup = 0.28

func _can_reach_target() -> bool:
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target.global_position + Vector3.UP, 1, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.collider == target

func _idle_return(delta: float) -> void:
    var flat_home := spawn_position - global_position
    flat_home.y = 0.0
    var current_speed := move_speed * _status_speed_multiplier()
    if flat_home.length() > 1.0:
        var direction := flat_home.normalized()
        velocity.x = direction.x * current_speed * 0.6
        velocity.z = direction.z * current_speed * 0.6
        _move_and_track(direction, 0.42, 2.8)
    else:
        velocity.x = move_toward(velocity.x, 0.0, current_speed * delta)
        velocity.z = move_toward(velocity.z, 0.0, current_speed * delta)
        move_and_slide()
        if Vector2(velocity.x, velocity.z).length() < 0.08:
            track_distance_accum = 0.0

func _move_and_track(forward: Vector3, strength: float, step_distance: float) -> void:
    var before := global_position
    move_and_slide()
    var moved := global_position - before
    moved.y = 0.0
    if moved.length() <= 0.002 or not is_on_floor():
        return

    track_distance_accum += moved.length()
    if track_distance_accum < maxf(step_distance, 0.8):
        return

    track_distance_accum = 0.0
    var resolved_forward := forward
    resolved_forward.y = 0.0
    if resolved_forward.length_squared() < 0.001:
        resolved_forward = -global_transform.basis.z
    WorldVFX.spawn_footstep(global_position, strength, "", resolved_forward.normalized())

func take_damage(amount: float, attacker: Node = null, silent: bool = false) -> void:
    if health <= 0.0:
        return
    if attacker is CharacterBody3D:
        target = attacker
    health = maxf(0.0, health - maxf(amount, 0.0))
    if not silent:
        GameState.notify("Попадание: %.0f урона. Враг: %.0f HP" % [amount, health])
    if health <= 0.0:
        _die()

func apply_status(status_name: String, duration: float, source: Node = null) -> void:
    if health <= 0.0 or status_name.is_empty() or duration <= 0.0:
        return
    var was_active := statuses.has(status_name)
    statuses[status_name] = maxf(float(statuses.get(status_name, 0.0)), duration)
    if source is CharacterBody3D:
        target = source
    if was_active:
        return
    match status_name:
        "burning":
            VFXLibrary.spawn("magic_fire", global_position + Vector3.UP * 0.8, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 0.65)
        "poisoned":
            VFXLibrary.spawn("magic_poison", global_position + Vector3.UP * 0.8, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 0.65)
        "frozen":
            VFXLibrary.spawn("magic_frost", global_position + Vector3.UP * 0.8, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 0.65)
        "shocked":
            VFXLibrary.spawn("magic_lightning", global_position + Vector3.UP * 0.8, get_tree().current_scene, Vector3.UP, Vector3.UP, 0.65)

func _update_statuses(delta: float) -> void:
    for status_name in statuses.keys():
        var remaining := maxf(0.0, float(statuses[status_name]) - delta)
        if remaining <= 0.0:
            statuses.erase(status_name)
        else:
            statuses[status_name] = remaining

    status_tick_elapsed += delta
    if status_tick_elapsed < 1.0:
        return
    status_tick_elapsed = 0.0

    if statuses.has("burning"):
        take_damage(5.0, null, true)
        if health > 0.0:
            VFXLibrary.spawn("magic_fire", global_position + Vector3.UP * 0.7, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 0.35)
    if health > 0.0 and statuses.has("poisoned"):
        take_damage(3.5, null, true)
        if health > 0.0:
            VFXLibrary.spawn("magic_poison", global_position + Vector3.UP * 0.7, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 0.30)

func _status_speed_multiplier() -> float:
    var multiplier := 1.0
    if statuses.has("frozen"):
        multiplier *= 0.48
    if statuses.has("shocked"):
        multiplier *= 0.72
    return multiplier

func _die() -> void:
    VFXLibrary.spawn("death_burst", global_position + Vector3.UP * 0.75, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 1.0)
    GameState.register_enemy_defeat(enemy_id, "coins", 3)
    set_physics_process(false)
    remove_from_group("hostile")
    var avatar := get_node_or_null("Avatar")
    if avatar != null:
        avatar.call("play_death")
    var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null:
        collision.set_deferred("disabled", true)
    get_tree().create_timer(8.0, false).timeout.connect(queue_free)
