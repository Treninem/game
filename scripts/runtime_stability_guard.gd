extends Node

const SURFACE_FALLBACK_DELAY := 2.0
const FALLBACK_SIZE := Vector3(36.0, 0.20, 36.0)

var player: CharacterBody3D
var guard_elapsed := 0.0
var fallback_floor: StaticBody3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = -100
    _ensure_essential_input_actions()
    call_deferred("_resolve_player")

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and (key_event.physical_keycode == KEY_ESCAPE or key_event.keycode == KEY_ESCAPE):
            if DialogueManager.is_open:
                return
            var menu := get_tree().get_first_node_in_group("game_menu") as Control
            var panels := get_tree().get_first_node_in_group("gameplay_panels") as Control
            if menu == null:
                return
            if panels != null and panels.visible:
                panels.call("close_panel")
            if menu.visible:
                menu.call("close_menu")
            else:
                menu.call("open_menu", "main")
            var viewport := get_viewport()
            if viewport != null:
                viewport.set_input_as_handled()

func _process(delta: float) -> void:
    _resolve_player()
    _repair_accidental_pause()
    if player == null:
        return

    var guard_active := bool(player.get("ground_guard_active"))
    if guard_active:
        guard_elapsed += delta
        if guard_elapsed >= SURFACE_FALLBACK_DELAY and fallback_floor == null:
            _create_fallback_surface()
    else:
        guard_elapsed = 0.0
        if fallback_floor != null and _real_surface_exists():
            fallback_floor.queue_free()
            fallback_floor = null

    if fallback_floor != null:
        var xz := Vector2(player.global_position.x, player.global_position.z)
        var terrain_y := WorldData.elevation_at(xz)
        fallback_floor.global_position = Vector3(player.global_position.x, terrain_y - FALLBACK_SIZE.y * 0.5, player.global_position.z)

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _repair_accidental_pause() -> void:
    var tree := get_tree()
    if not tree.paused:
        return
    if DialogueManager.is_open:
        return
    var menu := tree.get_first_node_in_group("game_menu") as Control
    var panels := tree.get_first_node_in_group("gameplay_panels") as Control
    var legitimate_pause := (menu != null and menu.visible) or (panels != null and panels.visible)
    if not legitimate_pause:
        tree.paused = false
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_fallback_surface() -> void:
    if player == null or not is_instance_valid(player):
        return
    var world_parent := player.get_parent()
    if world_parent == null:
        return
    var xz := Vector2(player.global_position.x, player.global_position.z)
    if not WorldData.inside_world(xz):
        return
    var terrain_y := WorldData.elevation_at(xz)

    fallback_floor = StaticBody3D.new()
    fallback_floor.name = "EmergencyStreamSurface"
    fallback_floor.collision_layer = 1
    fallback_floor.collision_mask = 1
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = FALLBACK_SIZE
    collision.shape = shape
    fallback_floor.add_child(collision)
    world_parent.add_child(fallback_floor)
    fallback_floor.global_position = Vector3(player.global_position.x, terrain_y - FALLBACK_SIZE.y * 0.5, player.global_position.z)

func _real_surface_exists() -> bool:
    if player == null or not is_instance_valid(player):
        return false
    var world := player.get_world_3d()
    if world == null:
        return false
    var xz := Vector2(player.global_position.x, player.global_position.z)
    var terrain_y := WorldData.elevation_at(xz)
    var from := Vector3(player.global_position.x, terrain_y + 2.0, player.global_position.z)
    var to := Vector3(player.global_position.x, terrain_y - 3.0, player.global_position.z)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player.get_rid(), fallback_floor.get_rid()] if fallback_floor != null else [player.get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = false
    var hit := world.direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return false
    var collider := hit.get("collider") as Node
    return collider != null and collider.name != "EmergencyStreamSurface"

func _ensure_essential_input_actions() -> void:
    _ensure_key_action("move_forward", KEY_W)
    _ensure_key_action("move_back", KEY_S)
    _ensure_key_action("move_left", KEY_A)
    _ensure_key_action("move_right", KEY_D)
    _ensure_key_action("sprint", KEY_SHIFT)
    _ensure_key_action("jump", KEY_SPACE)
    _ensure_key_action("interact", KEY_E)
    _ensure_key_action("next_spell", KEY_Q)
    _ensure_key_action("open_inventory", KEY_I)
    _ensure_key_action("open_map", KEY_M)
    _ensure_key_action("open_journal", KEY_J)
    _ensure_key_action("open_crafting", KEY_K)
    _ensure_key_action("quick_save", KEY_F5)
    _ensure_key_action("quick_load", KEY_F9)
    _ensure_key_action("pause_menu", KEY_ESCAPE)
    _ensure_key_action("use_food", KEY_1)
    _ensure_key_action("use_water", KEY_2)
    _ensure_mouse_action("attack", MOUSE_BUTTON_LEFT)
    _ensure_mouse_action("cast_magic", MOUSE_BUTTON_RIGHT)

func _ensure_key_action(action: StringName, physical_key: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    if not InputMap.action_get_events(action).is_empty():
        return
    var key_event := InputEventKey.new()
    key_event.physical_keycode = physical_key
    InputMap.action_add_event(action, key_event)

func _ensure_mouse_action(action: StringName, button: MouseButton) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    if not InputMap.action_get_events(action).is_empty():
        return
    var mouse_event := InputEventMouseButton.new()
    mouse_event.button_index = button
    InputMap.action_add_event(action, mouse_event)
