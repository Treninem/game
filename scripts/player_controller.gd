extends CharacterBody3D

@export var walk_speed := 5.0
@export var run_speed := 8.0
@export var acceleration := 18.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.0025
@export var gravity := 18.0
@export var attack_damage := 24.0
@export var attack_stamina_cost := 14.0
@export var sprint_stamina_per_second := 16.0
@export var attack_cooldown := 0.55

@onready var pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

var attack_elapsed := 0.0

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-60.0), deg_to_rad(45.0))
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _try_attack()
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_ESCAPE:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
            KEY_SPACE:
                if is_on_floor() and GameState.consume_stamina(8.0):
                    velocity.y = jump_velocity
            KEY_E:
                _try_interact()
            KEY_C:
                GameState.try_craft_building_kit()
            KEY_B:
                _try_build_house()
            KEY_1:
                GameState.use_consumable("berries")
            KEY_2:
                GameState.use_consumable("water_flask")
            KEY_3:
                GameState.use_consumable("raw_meat")
            KEY_F5:
                if SaveManager.save_game(self):
                    GameState.notify("Игра сохранена.")
            KEY_F9:
                if SaveManager.load_game(self):
                    get_tree().call_group("world_root", "spawn_house_from_state")
                    GameState.notify("Сохранение загружено.")

func _physics_process(delta: float) -> void:
    attack_elapsed = maxf(0.0, attack_elapsed - delta)
    if GameState.is_dead:
        velocity = Vector3.ZERO
        return
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_vec := Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_A):
        input_vec.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D):
        input_vec.x += 1.0
    if Input.is_physical_key_pressed(KEY_W):
        input_vec.y -= 1.0
    if Input.is_physical_key_pressed(KEY_S):
        input_vec.y += 1.0
    input_vec = input_vec.normalized()

    var wants_sprint := Input.is_physical_key_pressed(KEY_SHIFT) and input_vec.length() > 0.0 and is_on_floor()
    var can_sprint := wants_sprint and GameState.stamina > 1.0
    if can_sprint:
        GameState.stamina = maxf(0.0, GameState.stamina - sprint_stamina_per_second * delta)
        GameState.survival_changed.emit()

    var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
    var target_speed := run_speed if can_sprint else walk_speed
    var target := direction * target_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    move_and_slide()

func _try_attack() -> void:
    if GameState.is_dead or attack_elapsed > 0.0:
        return
    if not GameState.consume_stamina(attack_stamina_cost):
        GameState.notify("Недостаточно выносливости.")
        return
    attack_elapsed = attack_cooldown
    if not interaction_ray.is_colliding():
        return
    var collider = interaction_ray.get_collider()
    if collider != null and collider.has_method("take_damage"):
        var bonus := 8.0 if int(GameState.inventory.get("starter_axe", 0)) > 0 else 0.0
        collider.take_damage(attack_damage + bonus, self)

func _try_interact() -> void:
    if GameState.is_dead:
        return
    if not interaction_ray.is_colliding():
        GameState.notify("Рядом нет объекта для взаимодействия.")
        return
    var collider = interaction_ray.get_collider()
    if collider != null and collider.has_method("interact"):
        collider.interact(self)
    else:
        GameState.notify("С этим объектом пока нельзя взаимодействовать.")

func _try_build_house() -> void:
    if GameState.is_dead:
        return
    var forward := -global_transform.basis.z
    var build_position := global_position + Vector3(forward.x, 0.0, forward.z).normalized() * 5.0
    build_position.y = 0.0
    if GameState.try_mark_house_built(build_position):
        get_tree().call_group("world_root", "spawn_house_from_state")
