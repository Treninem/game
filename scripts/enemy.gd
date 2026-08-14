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

    if distance > attack_range:
        var direction := flat_to_player.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        if direction.length_squared() > 0.001:
            look_at(global_position + direction, Vector3.UP)
        move_and_slide()
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)
        move_and_slide()
        if attack_elapsed <= 0.0:
            attack_elapsed = attack_interval
            GameState.apply_damage(attack_damage)

func _idle_return(delta: float) -> void:
    var flat_home := spawn_position - global_position
    flat_home.y = 0.0
    if flat_home.length() > 1.0:
        var direction := flat_home.normalized()
        velocity.x = direction.x * move_speed * 0.6
        velocity.z = direction.z * move_speed * 0.6
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
    move_and_slide()

func take_damage(amount: float, attacker: Node = null) -> void:
    if health <= 0.0:
        return
    if attacker is CharacterBody3D:
        target = attacker
    health = maxf(0.0, health - maxf(amount, 0.0))
    GameState.notify("Попадание: %.0f урона. Враг: %.0f HP" % [amount, health])
    if health <= 0.0:
        _die()

func _die() -> void:
    GameState.register_enemy_defeat(enemy_id)
    set_physics_process(false)
    visible = false
    var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null:
        collision.set_deferred("disabled", true)
    queue_free()
