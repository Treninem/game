extends CharacterBody3D

@export var walk_speed := 5.0
@export var run_speed := 8.0
@export var acceleration := 22.0
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
var stuck_elapsed := 0.0
var last_horizontal_motion := Vector2.ZERO
var last_safe_position := Vector3.ZERO
var footstep_distance_accum := 0.0

func _ready() -> void:
    add_to_group("player")
    floor_snap_length = 0.45
    floor_max_angle = deg_to_rad(52.0)
    safe_margin = 0.045
    up_direction = Vector3.UP
    motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
    _apply_settings()
    SettingsManager.settings_changed.connect(_apply_settings)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    last_safe_position = global_position

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
        var spell_id := MagicSystem.selected_spell_id()
        if MagicSystem.cast_selected(self, camera):
            var cast_position := camera.global_position + (-camera.global_transform.basis.z) * 0.72
            ThirdPartyVFX.spawn_spell_cast(spell_id, cast_position, get_tree().current_scene, 0.82)
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
        last_horizontal_motion = Vector2.ZERO
        footstep_distance_accum = 0.0
        return

    var grounded_before := is_on_floor()
    if not grounded_before:
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var wants_sprint := Input.is_action_pressed("sprint") and input_vec.length() > 0.0 and grounded_before
    var can_sprint := wants_sprint and GameState.stamina > 1.0
    if can_sprint:
        GameState.stamina = maxf(0.0, GameState.stamina - sprint_stamina_per_second * delta)
        GameState.survival_changed.emit()

    var direction := (global_transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
    var target_speed := run_speed if can_sprint else walk_speed
    var target := direction * target_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

    var fall_speed_before_move := maxf(0.0, -velocity.y)
    var before := global_position
    move_and_slide()
    _enforce_world_bounds()
    _recover_to_terrain_if_needed(false)

    var moved := global_position - before
    last_horizontal_motion = Vector2(moved.x, moved.z)
    var grounded_after := is_on_floor()
    if last_horizontal_motion.length() > 0.002 and grounded_after:
        last_safe_position = global_position

    if not grounded_before and grounded_after and fall_speed_before_move > 3.4:
        footstep_distance_accum = 0.0
        WorldVFX.spawn_landing(global_position, fall_speed_before_move, "", -global_transform.basis.z)
        ScreenVFX.landing_feedback(fall_speed_before_move)
    elif grounded_after and input_vec.length() > 0.08:
        footstep_distance_accum += last_horizontal_motion.length()
        var step_distance := 1.75 if can_sprint else 2.35
        if footstep_distance_accum >= step_distance:
            footstep_distance_accum = 0.0
            WorldVFX.spawn_footstep(global_position, 1.10 if can_sprint else 0.72, "", -global_transform.basis.z)
    elif not grounded_after:
        footstep_distance_accum = 0.0

    if input_vec.length() > 0.15 and direction.length() > 0.1 and last_horizontal_motion.length() < 0.0015:
        stuck_elapsed += delta
        if stuck_elapsed >= 0.28:
            _attempt_unstick(direction, delta, target_speed)
            stuck_elapsed = 0.0
    else:
        stuck_elapsed = 0.0

func actual_horizontal_speed(delta: float = 1.0 / 60.0) -> float:
    return last_horizontal_motion.length() / maxf(delta, 0.0001)

func _attempt_unstick(direction: Vector3, delta: float, target_speed: float) -> void:
    # A streamed terrain collision can appear during the same frame in which the
    # player reaches a chunk seam. Recover upward first, then retry a small legal
    # horizontal step without ever phasing through a wall.
    var lift := Vector3.UP * 0.22
    if not test_move(global_transform, lift):
        global_position += lift

    var retry := direction.normalized() * minf(0.28, target_speed * maxf(delta, 1.0 / 60.0) * 2.0)
    if retry.length() > 0.001 and not test_move(global_transform, retry):
        global_position += retry
        velocity.x = direction.x * target_speed
        velocity.z = direction.z * target_speed
        return

    # If the body was spawned inside newly streamed terrain, move it onto the
    # authoritative height field instead of leaving an animated character stuck.
    var xz := Vector2(global_position.x, global_position.z)
    if WorldData.inside_world(xz):
        var terrain_y := WorldData.elevation_at(xz)
        if global_position.y < terrain_y + 0.15:
            global_position.y = terrain_y + 1.08
            velocity.y = 0.0

func _recover_to_terrain_if_needed(force_check: bool) -> void:
    if recovery_cooldown > 0.0 and not force_check:
        return
    recovery_cooldown = 0.25
    var xz := Vector2(global_position.x, global_position.z)
    if not WorldData.inside_world(xz):
        return
    var terrain_y := WorldData.elevation_at(xz)
    if global_position.y < terrain_y - 1.5:
        global_position.y = terrain_y + 1.08
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
    ThirdPartyVFX.spawn_slash(swing_position, get_tree().current_scene, 0.75)

    if not interaction_ray.is_colliding():
        return
    var collider = interaction_ray.get_collider()
    var hit_position := interaction_ray.get_collision_point()
    var hit_normal := interaction_ray.get_collision_normal()
    if collider != null and collider.has_method("take_damage"):
        VFXLibrary.spawn("hit_slash", hit_position, get_tree().current_scene, hit_normal, swing_direction, 1.0)
        ThirdPartyVFX.spawn_slash(hit_position, get_tree().current_scene, 0.55)
        ScreenVFX.shake(0.018, 0.08)
        collider.take_damage(attack_damage + InventorySystem.attack_bonus(), self)
    else:
        var surface := WorldVFX.surface_from_collider(collider, hit_position)
        WorldVFX.spawn_impact(surface, hit_position, hit_normal, swing_direction, 0.80)
        ScreenVFX.shake(0.010, 0.06)

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
