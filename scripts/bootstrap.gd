extends Node

const VERSION := "0.10.0-stage10"
const RESPAWN_POSITION := Vector3(0, 2.0, 8)

@onready var player: CharacterBody3D = $World/Player

var autosave_elapsed := 0.0
var respawning := false

func _ready() -> void:
    add_to_group("world_root")
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    GameState.player_died.connect(_on_player_died)

    if SaveManager.consume_new_game_request():
        GameState.reset_new_game()
        _place_player_safely(RESPAWN_POSITION)
    elif not SaveManager.load_game(player):
        GameState.reset_new_game()
        _place_player_safely(RESPAWN_POSITION)
    else:
        GameState.migrate_to_world_foundation()
        _recover_loaded_player_position()

    if GameState.is_dead:
        GameState.revive()
        _place_player_safely(RESPAWN_POSITION)

    GameState.notify("Мир ImPuls • ЛКМ — оружие • ПКМ — магия • Q — следующее заклинание • I/M/K/J — игровые панели")

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
        player.global_position.y = terrain_y + 1.2
        player.velocity = Vector3.ZERO

func _place_player_safely(position: Vector3) -> void:
    var xz := Vector2(position.x, position.z)
    player.global_position = Vector3(position.x, WorldData.elevation_at(xz) + 1.2, position.z)
    player.velocity = Vector3.ZERO

func _on_player_died() -> void:
    if respawning:
        return
    respawning = true
    await get_tree().create_timer(2.5).timeout
    _place_player_safely(RESPAWN_POSITION)
    GameState.revive()
    respawning = false
    GameState.notify("Вы возродились в безопасной зоне столицы.")

# Compatibility entry point for older controller/save code. Stage 10 deliberately
# does not instantiate the prototype shelter.
func spawn_house_from_state() -> void:
    pass
