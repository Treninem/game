extends Node

const VERSION := "0.10.7-stable"
const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const PLAYER_GROUND_CLEARANCE := 0.08
const RESPAWN_POSITION := Vector3(GEOGRAPHY.START_SPAWN.x, PLAYER_GROUND_CLEARANCE, GEOGRAPHY.START_SPAWN.y)

@onready var player: CharacterBody3D = $World/Player

var autosave_elapsed := 0.0
var respawning := false
var startup_state_ready := false

func _ready() -> void:
    startup_state_ready = false
    add_to_group("world_root")
    get_tree().paused = false
    if not bool(get_meta("loading_gate_active", false)):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    GameState.player_died.connect(_on_player_died)

    if SaveManager.consume_new_game_request():
        GameState.reset_new_game()
        _place_player_safely(RESPAWN_POSITION)
        SaveManager.save_game(player)
    elif SaveManager.consume_load_request():
        if SaveManager.load_game(player):
            GameState.migrate_to_world_foundation()
            _recover_loaded_player_position()
        else:
            GameState.reset_new_game()
            _place_player_safely(RESPAWN_POSITION)
    else:
        # Entering the world without an explicit menu load must never silently
        # restore whichever slot happened to be selected previously. This keeps
        # direct world startup deterministic and prevents stale saves from moving
        # a fresh story start away from the canonical Asterna river spawn.
        GameState.reset_new_game()
        _place_player_safely(RESPAWN_POSITION)

    if GameState.is_dead:
        GameState.revive()
        _place_player_safely(RESPAWN_POSITION)

    # The loading gate may reveal the world only after the save/new-game state
    # and a safe player position have actually been applied.
    startup_state_ready = true
    GameState.notify("Мир ImPuls • WASD — движение • Shift — бег • E — взаимодействие • I/M/K/J — игровые панели")

func _process(delta: float) -> void:
    if not GameState.is_dead:
        GameState.advance_survival(delta)
    autosave_elapsed += delta
    var autosave_seconds := maxf(30.0, float(SettingsManager.get_value("gameplay", "autosave_seconds")))
    if autosave_elapsed >= autosave_seconds:
        autosave_elapsed = 0.0
        SaveManager.save_game(player)

func _recover_loaded_player_position() -> void:
    var xz := Vector2(player.global_position.x, player.global_position.z)
    if not WorldData.inside_world(xz):
        _place_player_safely(RESPAWN_POSITION)
        return
    var terrain_y := WorldData.elevation_at(xz)
    if player.global_position.y < terrain_y - 2.0 or player.global_position.y > terrain_y + 250.0:
        player.global_position.y = terrain_y + PLAYER_GROUND_CLEARANCE
        player.velocity = Vector3.ZERO
    _arm_player_surface_guard(false)

func _place_player_safely(position: Vector3) -> void:
    var xz := Vector2(position.x, position.z)
    player.global_position = Vector3(position.x, WorldData.elevation_at(xz) + PLAYER_GROUND_CLEARANCE, position.z)
    player.velocity = Vector3.ZERO
    _arm_player_surface_guard(true)

func _arm_player_surface_guard(force_snap_to_terrain: bool) -> void:
    if player.has_method("prepare_for_streamed_surface"):
        player.call("prepare_for_streamed_surface", force_snap_to_terrain)
    elif player.has_method("_begin_ground_guard"):
        player.call("_begin_ground_guard", force_snap_to_terrain)

func _on_player_died() -> void:
    if respawning:
        return
    respawning = true
    await get_tree().create_timer(2.5).timeout
    _place_player_safely(RESPAWN_POSITION)
    GameState.revive()
    respawning = false
    GameState.notify("Вы пришли в себя у лесной реки.")
