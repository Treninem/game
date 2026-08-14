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
var recovery_cooldown := 0.0

func _ready() -> void:
    add_to_group("player")
    _apply_settings()
    SettingsManager.settings_changed.connect(_apply_settings)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_settings() -> void:
    camera.fov = float(SettingsManager.get_value("gameplay", "camera_fov"))

func _unhandled_input(event: InputEvent) -> void:
    if DialogueManager.is_open or get_tree().paused:
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
    if event.is_action_pressed("cast_magic"):
        MagicSystem.cast_selected(self, camera)
        return
    if event.is_action_pressed("next_spell"):
        MagicSystem.select_next()
        return
    if event.is_action_pressed("jump") and is_on_floor() and GameState.consume_stamina(8.0):
        velocity.y = jump_velocity
    elif event.is_action_pressed("interact"):
        _try_interact()
    elif event.is_action_pressed("use_food"):
        GameState.use_consumable("berries")
    elif event.is_action_pressed("use_water"):
        GameState.use_consumable("water_flask")
    elif event.is_action_pressed("quick_save"):
        if SaveManager.save_game(self):
            GameState.notify("Игра сохранена в слот %02d." % SaveManager.current_slot)
    elif event.is_action_pressed("quick_load"):
        if SaveManager.load_game(self):
            GameState.migrate_to_world_foundation()
            _recover_to_terrain_if_needed(true)
            GameState.notify("Загружен слот %02d." % SaveManager.current_slot)

func _physics_process(delta: float) -> void:
    attack_elapsed = maxf(0.0, attack_elapsed - delta)
    recovery_cooldown = maxf(0.0, recovery_cooldown - delta)
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
    _recover_to_terrain_if_needed(false)

func _recover_to_terrain_if_needed(force_check: bool) -> void:
    if recovery_cooldown > 0.0 and not force_check:
        return
    recovery_cooldown = 0.25
    var xz := Vector2(global_position.x, global_position.z)
    if not WorldData.inside_world(xz):
        return
    var terrain_y := WorldData.elevation_at(xz)
    # Streaming collisions are intentionally local. If a frame reaches new
    # terrain before its collision body is ready, never let the player fall away.
    if global_position.y < terrain_y - 1.5:
        global_position.y = terrain_y + 1.15
        velocity.y = 0.0

func _enforce_world_bounds() -> void:
    var limit := WorldData.WORLD_HALF_SIZE - 24.0
    var before := global_position
    global_position.x = clampf(global_position.x, -limit, limit)
    global_position.z = clampf(global_position.z, -limit, limit)
    if before.x != global_position.x or before.z != global_position.z:
        velocity.x = 0.0
        velocity.z = 0.0
        GameState.notify("Дальше начинается граница текущего континента.")

func _try_attack() -> void:
    if GameState.is_dead or attack_elapsed > 0.0:
        return
    if not GameState.consume_stamina(attack_stamina_cost):
        GameState.notify("Недостаточно выносливости.")
        return
    attack_elapsed = attack_cooldown

    var swing_direction := -camera.global_transform.basis.z
    var swing_position := camera.global_position + swing_direction * 1.35
    VFXLibrary.spawn("melee_swing", swing_position, get_tree().current_scene, Vector3.UP, swing_direction, 1.0)

    if not interaction_ray.is_colliding():
        return
    var collider = interaction_ray.get_collider()
    var hit_position := interaction_ray.get_collision_point()
    var hit_normal := interaction_ray.get_collision_normal()
    if collider != null and collider.has_method("take_damage"):
        VFXLibrary.spawn("hit_slash", hit_position, get_tree().current_scene, hit_normal, swing_direction, 1.0)
        collider.take_damage(attack_damage + InventorySystem.attack_bonus(), self)
    else:
        VFXLibrary.spawn_collision("stone", hit_position, hit_normal, get_tree().current_scene, 0.70)

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
