extends CharacterBody3D

@export var walk_speed := 5.0
@export var run_speed := 8.0
@export var acceleration := 18.0
@export var jump_velocity := 5.5
@export var gravity := 18.0
@export var attack_damage := 24.0
@export var attack_stamina_cost := 14.0
@export var sprint_stamina_per_second := 16.0
@export var attack_cooldown := 0.55

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

var attack_elapsed := 0.0

func _ready() -> void:
    add_to_group("player")
    _apply_settings()
    SettingsManager.settings_changed.connect(_apply_settings)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_settings() -> void:
    camera.fov = float(SettingsManager.get_value("gameplay", "camera_fov"))

func _unhandled_input(event: InputEvent) -> void:
    if DialogueManager.is_open:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var sensitivity := float(SettingsManager.get_value("gameplay", "mouse_sensitivity"))
        rotate_y(-event.relative.x * sensitivity)
        pivot.rotate_x(-event.relative.y * sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-60.0), deg_to_rad(45.0))
        return
    if event.is_action_pressed("attack"):
        _try_attack()
        return
    if event.is_action_pressed("jump") and is_on_floor() and GameState.consume_stamina(8.0):
        velocity.y = jump_velocity
    elif event.is_action_pressed("interact"):
        _try_interact()
    elif event.is_action_pressed("craft"):
        GameState.try_craft_building_kit()
    elif event.is_action_pressed("build"):
        _try_build_house()
    elif event.is_action_pressed("use_food"):
        GameState.use_consumable("berries")
    elif event.is_action_pressed("use_water"):
        GameState.use_consumable("water_flask")
    elif event.is_action_pressed("use_meat"):
        _use_meat_quick()
    elif event.is_action_pressed("quick_save"):
        if SaveManager.save_game(self):
            GameState.notify("Игра сохранена в слот %02d." % SaveManager.current_slot)
    elif event.is_action_pressed("quick_load"):
        if SaveManager.load_game(self):
            get_tree().call_group("world_root", "spawn_house_from_state")
            GameState.notify("Загружен слот %02d." % SaveManager.current_slot)

func _physics_process(delta: float) -> void:
    attack_elapsed = maxf(0.0, attack_elapsed - delta)
    if GameState.is_dead:
        velocity = Vector3.ZERO
        return
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var wants_sprint := Input.is_action_pressed("sprint") and input_vec.length() > 0.0 and is_on_floor()
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
    _enforce_world_bounds()

func _enforce_world_bounds() -> void:
    var limit := WorldData.WORLD_HALF_SIZE - 24.0
    var before := global_position
    global_position.x = clampf(global_position.x, -limit, limit)
    global_position.z = clampf(global_position.z, -limit, limit)
    if before.x != global_position.x or before.z != global_position.z:
        velocity.x = 0.0
        velocity.z = 0.0
        GameState.notify("Дальше начинается открытое море и граница текущего континента.")

func _use_meat_quick() -> void:
    if int(GameState.inventory.get("cooked_meat", 0)) > 0:
        if GameState.remove_item("cooked_meat", 1):
            GameState.hunger = minf(100.0, GameState.hunger + 45.0)
            GameState.health = minf(GameState.max_health, GameState.health + 5.0)
            GameState.survival_changed.emit()
            GameState.notify("Вы съели жареное мясо.")
        return
    if int(GameState.inventory.get("raw_meat", 0)) > 0:
        GameState.use_consumable("raw_meat")
        return
    GameState.notify("В быстром слоте нет еды.")

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
        collider.take_damage(attack_damage + InventorySystem.attack_bonus(), self)

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
    build_position.y = WorldData.elevation_at(Vector2(build_position.x, build_position.z))
    if GameState.try_mark_house_built(build_position):
        get_tree().call_group("world_root", "spawn_house_from_state")
