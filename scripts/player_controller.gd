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

const GROUND_CLEARANCE := 0.08
const AXE_MELEE_REACH := 1.4
const SURFACE_READY_REQUIRED_FRAMES := 2
const VOID_RECOVERY_DEPTH := 1.25
const SAFE_RECOVERY_XZ_RADIUS := 96.0
const SURFACE_RAY_UP := 1.25
const SURFACE_RAY_BELOW_TERRAIN := 2.5

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

var attack_elapsed := 0.0
var pending_bow_elapsed := 0.0
var pending_bow_revision := -1
var pending_axe_elapsed := 0.0
var pending_axe_revision := -1
var pending_axe_target: WeakRef
var cast_elapsed := 0.0
var recovery_cooldown := 0.0
var stuck_elapsed := 0.0
var last_horizontal_motion := Vector2.ZERO
var last_safe_position := Vector3.ZERO
var has_safe_position := false
var ground_guard_active := false
var instanced_world_mode := false
var surface_ready_frames := 0
var footstep_distance_accum := 0.0
var landing_elapsed := 0.0
var landing_strength := 0.0
var appearance_height_cm := 180.0
var character_dimensions_initialized := false
var character_base_radius := 0.45
var character_base_pivot_height := 1.35

func apply_character_dimensions(height_cm: float) -> void:
    var appearance := preload("res://scripts/character_appearance.gd")
    var bounded := clampf(height_cm, appearance.MIN_HEIGHT_CM, appearance.MAX_HEIGHT_CM) if is_finite(height_cm) else appearance.DEFAULT_HEIGHT_CM
    if character_dimensions_initialized and is_equal_approx(appearance_height_cm, bounded):
        return
    var collider := get_node_or_null("CollisionShape3D") as CollisionShape3D
    var camera_pivot := get_node_or_null("CameraPivot") as Node3D
    if collider == null or camera_pivot == null or not collider.shape is CapsuleShape3D:
        return
    var capsule := collider.shape as CapsuleShape3D
    if not character_dimensions_initialized:
        capsule = capsule.duplicate() as CapsuleShape3D
        collider.shape = capsule
        character_base_radius = capsule.radius
        character_base_pivot_height = camera_pivot.position.y
    var ratio := bounded / appearance.DEFAULT_HEIGHT_CM
    capsule.height = bounded / 100.0
    capsule.radius = character_base_radius * ratio
    # Resize from the feet, keeping the physical root on its saved surface.
    collider.position.y = bounded / 200.0
    camera_pivot.position.y = character_base_pivot_height * ratio
    appearance_height_cm = bounded
    character_dimensions_initialized = true

func _ready() -> void:
    add_to_group("player")
    floor_snap_length = 0.45
    floor_max_angle = deg_to_rad(52.0)
    safe_margin = 0.045
    up_direction = Vector3.UP
    motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
    interaction_ray.add_exception(self)
    interaction_ray.set_collision_mask_value(2, true)
    _apply_settings()
    SettingsManager.settings_changed.connect(_apply_settings)
    MagicSystem.spell_cast.connect(_on_spell_cast)
    if not SaveManager.game_loaded.is_connected(_on_game_loaded):
        SaveManager.game_loaded.connect(_on_game_loaded)
    SettingsManager.capture_gameplay_mouse()
    # Never let gravity race ahead of streamed terrain. The guard releases only
    # after the physics server reports a real surface below the player's feet on
    # two consecutive physics frames.
    _begin_ground_guard(true)

func _apply_settings() -> void:
    camera.fov = float(SettingsManager.get_value("gameplay", "camera_fov"))

func _on_spell_cast(_spell_id: String) -> void:
    cast_elapsed = 0.45

func _on_game_loaded(_slot: int) -> void:
    var loaded_instanced := ProgressionSystem.is_in_dungeon() or String(GameState.get_world_value("current_realm", "main")) != "main"
    _set_instanced_world_mode(loaded_instanced)
    if not loaded_instanced:
        _recover_to_terrain_if_needed(true)

func _input(event: InputEvent) -> void:
    if DialogueManager.is_open or get_tree().paused:
        return
    if event is InputEventMouseButton and event.pressed and not SettingsManager.is_gameplay_mouse_captured():
        # Restore capture after the window loses focus. This first click must
        # never also attack or cast a spell.
        SettingsManager.capture_gameplay_mouse()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseMotion and SettingsManager.is_gameplay_mouse_captured():
        if SettingsManager.ignore_recapture_motion():
            get_viewport().set_input_as_handled()
            return
        if SettingsManager.uses_compatible_mouse() and event.position.distance_squared_to(get_viewport().get_visible_rect().get_center()) < 1.0:
            # Windows reports the recenter warp as the opposite movement.
            # Applying it would cancel every real camera turn immediately.
            get_viewport().set_input_as_handled()
            return
        # Read camera motion before GUI hit testing; HUD panels can consume
        # unhandled motion. Screen-relative motion stays stable at any UI scale.
        var motion: Vector2 = event.screen_relative
        if SettingsManager.uses_compatible_mouse():
            # Absolute pointing devices can report positions with both relative
            # fields empty. Read displacement from the recentered cursor instead.
            var viewport_size := get_viewport().get_visible_rect().size
            motion = (event.position - viewport_size * 0.5) * Vector2(DisplayServer.window_get_size()) / viewport_size
        if motion.is_zero_approx():
            motion = event.relative
        if motion.is_zero_approx():
            return
        var sensitivity := float(SettingsManager.get_value("gameplay", "mouse_sensitivity"))
        rotate_y(-motion.x * sensitivity)
        pivot.rotate_x(-motion.y * sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-60.0), deg_to_rad(45.0))
        SettingsManager.recenter_gameplay_mouse()
        get_viewport().set_input_as_handled()
        return

func _unhandled_input(event: InputEvent) -> void:
    if DialogueManager.is_open or get_tree().paused:
        return
    if event.is_action_pressed("attack"):
        _try_attack()
        return
    if event.is_action_pressed("cast_magic"):
        _leave_furniture_rest()
        var spell_id := MagicSystem.selected_spell_id()
        if MagicSystem.cast_selected(self, camera):
            var cast_position: Vector3 = projectile_aim()["origin"]
            ThirdPartyVFX.spawn_spell_cast(spell_id, cast_position, get_tree().current_scene, 0.82)
        return
    if event.is_action_pressed("next_spell"):
        MagicSystem.select_next()
        return
    if event.is_action_pressed("jump") and is_on_floor() and GameState.consume_stamina(8.0):
        _leave_furniture_rest()
        landing_elapsed = 0.0
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
            # Old saves can contain a position captured before the streamed world
            # existed. Repair only positions below terrain; legitimate elevated
            # positions remain untouched, but still wait for a physical surface.
            _begin_ground_guard(false)
            _recover_to_terrain_if_needed(true)
            GameState.notify("Загружен слот %02d." % SaveManager.current_slot)

func _physics_process(delta: float) -> void:
    landing_elapsed = maxf(0.0, landing_elapsed - delta)
    _update_bow_shot(delta)
    _update_axe_hit(delta)
    attack_elapsed = maxf(0.0, attack_elapsed - delta)
    cast_elapsed = maxf(0.0, cast_elapsed - delta)
    recovery_cooldown = maxf(0.0, recovery_cooldown - delta)
    if GameState.is_dead:
        landing_elapsed = 0.0
        _furniture_rest_step(0)
        velocity = Vector3.ZERO
        last_horizontal_motion = Vector2.ZERO
        footstep_distance_accum = 0.0
        return

    if ground_guard_active:
        _hold_until_physical_surface_ready()
        return

    if _furniture_rest_step(delta):
        landing_elapsed = 0.0
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
    if instanced_world_mode:
        if _recover_instanced_fall_if_needed():
            return
    else:
        _enforce_world_bounds()
        _recover_to_terrain_if_needed(false)

    var moved := global_position - before
    last_horizontal_motion = Vector2(moved.x, moved.z)
    var grounded_after := is_on_floor()
    if grounded_after:
        last_safe_position = global_position
        has_safe_position = true

    if not grounded_before and grounded_after and fall_speed_before_move > 3.4:
        landing_elapsed = 0.24
        landing_strength = clampf(fall_speed_before_move / 7.0, 0.35, 1.0)
        footstep_distance_accum = 0.0
        var contact := _foot_contact()
        WorldVFX.spawn_landing(contact.position, fall_speed_before_move, contact.surface, -global_transform.basis.z, contact.normal)
        _play_footstep_audio(clampf(fall_speed_before_move / 5.5, 0.75, 1.35), contact)
        ScreenVFX.landing_feedback(fall_speed_before_move)
    elif grounded_after and input_vec.length() > 0.08:
        footstep_distance_accum += last_horizontal_motion.length()
        var step_distance := 1.75 if can_sprint else 2.35
        if footstep_distance_accum >= step_distance:
            footstep_distance_accum = 0.0
            var footstep_strength := 1.10 if can_sprint else 0.72
            var contact := _foot_contact()
            WorldVFX.spawn_footstep(contact.position, footstep_strength, contact.surface, -global_transform.basis.z, contact.normal)
            _play_footstep_audio(footstep_strength, contact)
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

func _foot_contact() -> Dictionary:
    # Resolve once per audible/visible step, never once per frame. Collider
    # metadata wins over the map so interiors and bridges retain their material.
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3,
        global_position - Vector3.UP * 0.6, collision_mask, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    var point: Vector3 = hit.get("position", global_position)
    var surface := WorldVFX.surface_from_collider(hit.get("collider"), point)
    if surface == "water":
        point.y = maxf(point.y, WorldData.water_level_at(Vector2(point.x, point.z)))
    return {"position":point, "normal":hit.get("normal", Vector3.UP), "surface":surface}

func _play_footstep_audio(intensity: float, contact: Dictionary = {}) -> void:
    if contact.is_empty():
        contact = _foot_contact()
    var world_audio := get_tree().get_first_node_in_group("world_audio")
    if world_audio != null and world_audio.has_method("play_footstep"):
        var hint := "wood" if contact.surface == "wood" else ("wet" if contact.surface in ["water", "mud"] else "ground")
        world_audio.call("play_footstep", contact.position, hint, intensity)

func set_dungeon_mode(active: bool) -> void:
    _set_instanced_world_mode(active)

func set_realm_mode(active: bool) -> void:
    _set_instanced_world_mode(active)

func prepare_for_streamed_surface(force_snap_to_terrain: bool = false) -> void:
    _begin_ground_guard(force_snap_to_terrain)

func _set_instanced_world_mode(active: bool) -> void:
    landing_elapsed = 0.0
    landing_strength = 0.0
    instanced_world_mode = active
    ground_guard_active = false
    surface_ready_frames = 0
    recovery_cooldown = 0.0
    velocity = Vector3.ZERO
    last_horizontal_motion = Vector2.ZERO
    footstep_distance_accum = 0.0
    if active:
        last_safe_position = global_position
        has_safe_position = true
    else:
        _begin_ground_guard(false)

func _recover_instanced_fall_if_needed() -> bool:
    if not instanced_world_mode:
        return false
    if not has_safe_position:
        last_safe_position = global_position
        has_safe_position = true
        return false
    if global_position.y >= last_safe_position.y - 24.0:
        return false
    global_position = last_safe_position + Vector3.UP * 0.08
    velocity = Vector3.ZERO
    last_horizontal_motion = Vector2.ZERO
    footstep_distance_accum = 0.0
    return true

func _begin_ground_guard(force_snap_to_terrain: bool) -> void:
    landing_elapsed = 0.0
    if instanced_world_mode:
        ground_guard_active = false
        surface_ready_frames = 0
        velocity = Vector3.ZERO
        return
    var xz := Vector2(global_position.x, global_position.z)
    if WorldData.inside_world(xz):
        var terrain_y := WorldData.elevation_at(xz)
        if force_snap_to_terrain or global_position.y < terrain_y - 0.20:
            global_position.y = terrain_y + GROUND_CLEARANCE
    velocity = Vector3.ZERO
    last_horizontal_motion = Vector2.ZERO
    ground_guard_active = true
    surface_ready_frames = 0
    if force_snap_to_terrain:
        has_safe_position = false

func _hold_until_physical_surface_ready() -> void:
    velocity = Vector3.ZERO
    last_horizontal_motion = Vector2.ZERO
    var xz := Vector2(global_position.x, global_position.z)
    if not WorldData.inside_world(xz):
        surface_ready_frames = 0
        return

    var terrain_y := WorldData.elevation_at(xz)
    if global_position.y < terrain_y + GROUND_CLEARANCE:
        global_position.y = terrain_y + GROUND_CLEARANCE

    if _physical_surface_exists_below(terrain_y):
        surface_ready_frames += 1
    else:
        surface_ready_frames = 0

    if surface_ready_frames < SURFACE_READY_REQUIRED_FRAMES:
        return

    ground_guard_active = false
    surface_ready_frames = 0
    last_safe_position = global_position
    has_safe_position = true

func _physical_surface_exists_below(terrain_y: float) -> bool:
    var world := get_world_3d()
    if world == null:
        return false
    var from := global_position + Vector3.UP * SURFACE_RAY_UP
    var ray_end_y := minf(global_position.y - 0.20, terrain_y - SURFACE_RAY_BELOW_TERRAIN)
    var to := Vector3(global_position.x, ray_end_y, global_position.z)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = false
    var hit := world.direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return false
    var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
    # At spawn/recovery we need a walking surface, not an unrelated roof or
    # ceiling high above the authoritative terrain.
    return hit_position.y >= terrain_y - 1.0 and hit_position.y <= terrain_y + 1.5

func _attempt_unstick(direction: Vector3, delta: float, target_speed: float) -> void:
    if not is_on_floor():
        return
    # Raise the capsule only onto an actual low walking surface. Blind upward
    # nudges at a wall made the character bounce above the ground indefinitely.
    var ahead := global_position + direction.normalized() * 0.45
    var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.34, ahead + Vector3.DOWN * 0.10, 1, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP) < cos(floor_max_angle):
        return
    var rise := Vector3(hit.position).y - global_position.y
    if rise <= 0.02 or rise > 0.30:
        return
    var lift := Vector3.UP * (rise + 0.025)
    if test_move(global_transform, lift):
        return
    var retry := direction.normalized() * minf(0.28, target_speed * maxf(delta, 1.0 / 60.0) * 2.0)
    if retry.length() > 0.001 and not test_move(global_transform.translated(lift), retry):
        global_position += lift + retry
        velocity.y = 0.0
        velocity.x = direction.x * target_speed
        velocity.z = direction.z * target_speed

func _recover_to_terrain_if_needed(force_check: bool) -> void:
    if instanced_world_mode:
        return
    if recovery_cooldown > 0.0 and not force_check:
        return
    recovery_cooldown = 0.25
    var xz := Vector2(global_position.x, global_position.z)
    if not WorldData.inside_world(xz):
        if has_safe_position:
            global_position = last_safe_position
            velocity = Vector3.ZERO
            _begin_ground_guard(false)
        return

    var terrain_y := WorldData.elevation_at(xz)
    if global_position.y >= terrain_y - VOID_RECOVERY_DEPTH:
        return

    # Prefer the most recent genuinely grounded point. If no nearby safe point
    # exists, restore current XZ directly onto the authoritative height field.
    var recovery_position := Vector3(global_position.x, terrain_y + GROUND_CLEARANCE, global_position.z)
    if has_safe_position:
        var safe_xz := Vector2(last_safe_position.x, last_safe_position.z)
        if WorldData.inside_world(safe_xz) and safe_xz.distance_to(xz) <= SAFE_RECOVERY_XZ_RADIUS:
            recovery_position = last_safe_position
            var safe_terrain_y := WorldData.elevation_at(safe_xz)
            recovery_position.y = maxf(recovery_position.y, safe_terrain_y + GROUND_CLEARANCE)

    global_position = recovery_position
    velocity = Vector3.ZERO
    last_horizontal_motion = Vector2.ZERO
    footstep_distance_accum = 0.0
    last_safe_position = recovery_position
    has_safe_position = true
    _begin_ground_guard(false)

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
    _leave_furniture_rest()
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == "short_bow":
        _try_shoot()
        return
    if not GameState.consume_stamina(attack_stamina_cost):
        GameState.notify("Недостаточно выносливости.")
        return
    attack_elapsed = attack_cooldown
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == "starter_axe":
        var avatar := get_node_or_null("Avatar")
        if avatar != null and avatar.has_method("begin_axe_stroke"):
            avatar.begin_axe_stroke()

    var swing_direction := -camera.global_transform.basis.z
    var swing_position := global_position + Vector3.UP * 1.1 + swing_direction * 0.9
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != "starter_axe":
        VFXLibrary.spawn("melee_swing", swing_position, get_tree().current_scene, Vector3.UP, swing_direction, 1.0)
        ThirdPartyVFX.spawn_slash(swing_position, get_tree().current_scene, 0.75)

    if not interaction_ray.is_colliding():
        return
    var collider = interaction_ray.get_collider()
    var hit_position := interaction_ray.get_collision_point()
    var hit_normal := interaction_ray.get_collision_normal()
    if not _reachable_hit(collider, hit_position, 3.0):
        return
    if collider != null and collider.has_method("receive_melee_hit"):
        collider.receive_melee_hit(self)
    elif collider != null and collider.has_method("take_damage"):
        if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == "starter_axe":
            pending_axe_elapsed = 0.22
            pending_axe_revision = GameState.state_revision
            pending_axe_target = weakref(collider)
        else:
            _apply_melee_damage(collider, hit_position, hit_normal, swing_direction)
    else:
        var surface := WorldVFX.surface_from_collider(collider, hit_position)
        WorldVFX.spawn_impact(surface, hit_position, hit_normal, swing_direction, 0.80)
        ScreenVFX.shake(0.010, 0.06)

func _apply_melee_damage(collider: Object, point: Vector3, normal: Vector3, direction: Vector3) -> void:
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == "starter_axe":
        WorldVFX.spawn_impact(WorldVFX.surface_from_collider(collider, point), point, normal, direction, 0.45)
    else:
        VFXLibrary.spawn("hit_slash", point, get_tree().current_scene, normal, direction, 1.0)
        ThirdPartyVFX.spawn_slash(point, get_tree().current_scene, 0.55)
    ScreenVFX.shake(0.018, 0.08)
    collider.take_damage(attack_damage + InventorySystem.attack_bonus(), self)

func _update_axe_hit(delta: float) -> void:
    if pending_axe_elapsed <= 0.0:
        return
    if GameState.is_dead or pending_axe_revision != GameState.state_revision or ground_guard_active or cast_elapsed > 0 or InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != "starter_axe":
        pending_axe_elapsed = 0.0
        attack_elapsed = 0.0
        pending_axe_target = null
        return
    pending_axe_elapsed = maxf(0.0, pending_axe_elapsed - delta)
    if pending_axe_elapsed > 0.0:
        return
    var target: Object = pending_axe_target.get_ref() if pending_axe_target != null else null
    pending_axe_target = null
    if not is_instance_valid(target):
        return
    interaction_ray.force_raycast_update()
    if interaction_ray.get_collider() != target:
        return
    var point := interaction_ray.get_collision_point()
    if _reachable_hit(target, point, AXE_MELEE_REACH):
        _apply_melee_damage(target, point, interaction_ray.get_collision_normal(), -camera.global_basis.z)

func _try_shoot() -> void:
    if int(GameState.inventory.get("arrow", 0)) <= 0:
        GameState.notify("Нет стрел. Их можно изготовить в меню крафта (K).")
        return
    if not GameState.consume_stamina(5.0):
        GameState.notify("Недостаточно выносливости.")
        return
    pending_bow_elapsed = 0.22
    pending_bow_revision = GameState.state_revision
    attack_elapsed = 0.7

func _update_bow_shot(delta: float) -> void:
    if pending_bow_elapsed <= 0.0:
        return
    if GameState.is_dead or pending_bow_revision != GameState.state_revision or ground_guard_active or cast_elapsed > 0 or InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != "short_bow":
        pending_bow_elapsed = 0.0
        attack_elapsed = 0.0
        return
    pending_bow_elapsed = maxf(0.0, pending_bow_elapsed - delta)
    if pending_bow_elapsed > 0.0:
        return
    if not GameState.remove_item("arrow", 1):
        attack_elapsed = 0.0
        return
    var aim := projectile_aim(70.0)
    var arrow := preload("res://scripts/weapon_projectile.gd").new()
    get_tree().current_scene.add_child(arrow)
    var origin: Vector3 = aim["origin"]
    var avatar := get_node_or_null("Avatar")
    if avatar != null and avatar.has_method("arrow_release_point"):
        var release: Vector3 = avatar.arrow_release_point()
        if release.is_finite() and release.distance_to(global_position) < 2.5 and release.distance_to(global_position) > 0.2:
            origin = release
    var target: Vector3 = aim["origin"] + aim["direction"] * 70.0
    arrow.global_position = origin
    arrow.setup(self, (target - origin).normalized())

func projectile_aim(max_range: float = 60.0) -> Dictionary:
    var direction := -camera.global_transform.basis.z
    var origin := global_position + Vector3.UP * 1.35 + direction * 0.30
    var aim := origin + direction * max_range
    var query := PhysicsRayQueryParameters3D.create(camera.global_position, aim, 1, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        aim = hit["position"]
    # A wall between the camera and hero must not make the hero shoot backward.
    if (aim - origin).dot(direction) <= 0.0:
        aim = origin + direction * max_range
    return {"origin": origin, "direction": (aim - origin).normalized()}

func _try_interact() -> void:
    if GameState.is_dead:
        return
    if _try_collect_fallen_wood():
        return
    if not interaction_ray.is_colliding():
        GameState.notify("Рядом нет объекта для взаимодействия.")
        return
    var collider = interaction_ray.get_collider()
    if not _reachable_hit(collider, interaction_ray.get_collision_point(), 3.0):
        GameState.notify("Подойдите ближе: цель должна быть перед вами и без преграды.")
        return
    if collider != null and collider.has_method("interact"):
        collider.interact(self)
    else:
        GameState.notify("С этим объектом пока нельзя взаимодействовать.")

func _try_collect_fallen_wood() -> bool:
    var nearest: Node3D = null
    var nearest_distance := 2.3
    for node in get_tree().get_nodes_in_group("map_resource"):
        if node.get_script() != preload("res://scripts/streamed_resource.gd"):
            continue
        if node.resource_id != "wood" or not node.fallen or node.falling or node.uses <= 0:
            continue
        var point: Vector3 = node.global_position + Vector3.UP * 0.22
        var distance := (global_position + Vector3.UP * 1.1).distance_to(point)
        if distance < nearest_distance and _reachable_hit(node, point, 2.3):
            nearest = node
            nearest_distance = distance
    if nearest != null:
        nearest.interact(self)
        return true
    return false

func _reachable_hit(collider: Object, point: Vector3, reach: float) -> bool:
    var origin := global_position + Vector3.UP * 1.1
    var direction := point - origin
    if direction.length() > reach or direction.dot(-camera.global_basis.z) < -0.05:
        return false
    var end := point + direction.normalized() * 0.02
    var query := PhysicsRayQueryParameters3D.create(origin, end, interaction_ray.collision_mask, [get_rid()])
    query.collide_with_areas = interaction_ray.collide_with_areas
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.collider == collider

func _furniture_rest_step(delta: float) -> bool:
    var saved: Variant = GameState.get_world_value("player:rest_furniture", "")
    var id := String(saved) if saved is String else ""
    var model := get_node_or_null("Avatar") as Node3D
    if model == null:
        return false
    if id.is_empty() and not model.top_level:
        return false
    var furniture: HouseholdFurniture
    for candidate in get_tree().get_nodes_in_group("household_furniture"):
        if candidate.furniture_id == id:
            furniture = candidate
            break
    var moving := Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0 or Input.is_action_pressed("jump") or attack_elapsed > 0 or cast_elapsed > 0
    if id.is_empty() or furniture == null or moving or not furniture._reachable(self) or not furniture.claim("player"):
        _leave_furniture_rest()
        return false
    furniture.apply_rest_pose(self, model)
    velocity = Vector3(0, -0.15, 0)
    move_and_slide()
    GameState.restore_stamina(delta * 8)
    return true

func _leave_furniture_rest() -> void:
    var model := get_node_or_null("Avatar") as Node3D
    var saved: Variant = GameState.get_world_value("player:rest_furniture", "")
    if (not saved is String or String(saved).is_empty()) and (model == null or not model.top_level) and String(get_meta("rest_furniture", "")).is_empty():
        return
    # Input actions must release the supported visual before they start, rather
    # than waiting for the following physics tick to notice an attack/cast timer.
    for furniture in get_tree().get_nodes_in_group("household_furniture"):
        furniture.release("player")
    if saved is String and not String(saved).is_empty():
        GameState.set_world_value("player:rest_furniture", "")
    set_meta("rest_furniture", "")
    if model != null and model.top_level:
        HouseholdFurniture.clear_pose(self, model)
