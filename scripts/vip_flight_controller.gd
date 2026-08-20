extends Node

const FLIGHT_SPEED := 11.0
const VERTICAL_SPEED := 7.0
const FLIGHT_ACCELERATION := 22.0

var player: CharacterBody3D
var flight_active := false

func _ready() -> void:
    process_priority = -20
    ProgressionSystem.vip_flight_changed.connect(_on_vip_flight_changed)
    call_deferred("_resolve_player")
    call_deferred("_sync_from_state")

func _exit_tree() -> void:
    if player != null and is_instance_valid(player):
        player.set_physics_process(true)

func _physics_process(delta: float) -> void:
    _resolve_player()
    if player == null:
        return
    var should_fly := bool(ProgressionSystem.vip_status().get("flight", false))
    if should_fly != flight_active:
        _set_flight_active(should_fly)
    if not flight_active:
        return

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var planar := (player.global_transform.basis * Vector3(input_vec.x, 0.0, input_vec.y))
    planar.y = 0.0
    if planar.length_squared() > 0.001:
        planar = planar.normalized()

    var vertical := 0.0
    if Input.is_action_pressed("jump"):
        vertical += 1.0
    if Input.is_key_pressed(KEY_CTRL):
        vertical -= 1.0

    var target := planar * FLIGHT_SPEED
    target.y = vertical * VERTICAL_SPEED
    player.velocity.x = move_toward(player.velocity.x, target.x, FLIGHT_ACCELERATION * delta)
    player.velocity.y = move_toward(player.velocity.y, target.y, FLIGHT_ACCELERATION * delta)
    player.velocity.z = move_toward(player.velocity.z, target.z, FLIGHT_ACCELERATION * delta)
    player.move_and_slide()

    var xz := Vector2(player.global_position.x, player.global_position.z)
    if not WorldData.inside_world(xz):
        ProgressionSystem.toggle_vip_flight()
        return
    var floor_y := WorldData.elevation_at(xz) + 0.9
    var ceiling_y := floor_y + 180.0
    player.global_position.y = clampf(player.global_position.y, floor_y, ceiling_y)

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _sync_from_state() -> void:
    _resolve_player()
    _set_flight_active(bool(ProgressionSystem.vip_status().get("flight", false)))

func _on_vip_flight_changed(active: bool) -> void:
    _resolve_player()
    _set_flight_active(active)

func _set_flight_active(active: bool) -> void:
    flight_active = active
    if player == null or not is_instance_valid(player):
        return
    player.set_physics_process(not active)
    player.velocity = Vector3.ZERO
    if not active:
        if player.has_method("prepare_for_streamed_surface"):
            player.call("prepare_for_streamed_surface", false)
        elif player.has_method("_begin_ground_guard"):
            player.call("_begin_ground_guard", false)
