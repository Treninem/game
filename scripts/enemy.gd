extends CharacterBody3D

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

func _ready() -> void:
    if enemy_id.is_empty():
        enemy_id = String(name)
    if bool(GameState.get_world_value("enemy:" + enemy_id, false)):
        queue_free()
        return
    health = max_health
    spawn_position = global_position
    add_to_group("hostile")

func _physics_process(delta: float) -> void:
    if health <= 0.0:
        return
    _update_statuses(delta)
    if health <= 0.0:
        return

    attack_elapsed = maxf(0.0, attack_elapsed - delta)
    if not is_on_floor():
        velocity.y -= gravity * delta

    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player") as CharacterBody3D

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
            var impact_direction := -flat_to_player.normalized() if flat_to_player.length_squared() > 0.001 else Vector3.UP
            VFXLibrary.spawn("hit_blunt", target.global_position + Vector3.UP * 0.9, get_tree().current_scene, impact_direction, flat_to_player.normalized(), 0.85)
            ScreenVFX.damage_feedback(attack_damage)
            GameState.apply_damage(attack_damage)

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
    GameState.register_enemy_defeat(enemy_id)
    set_physics_process(false)
    visible = false
    var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null:
        collision.set_deferred("disabled", true)
    queue_free()
