extends Node

const VERSION := "0.6.0-stage6"
const HOUSE_SCENE := preload("res://scenes/house.tscn")
const RESPAWN_POSITION := Vector3(0, 1, 8)

@onready var player: CharacterBody3D = $World/Player

var autosave_elapsed := 0.0
var spawned_house: Node3D
var respawning := false

func _ready() -> void:
    add_to_group("world_root")
    GameState.player_died.connect(_on_player_died)
    if SaveManager.consume_new_game_request():
        GameState.reset_new_game()
    elif not SaveManager.load_game(player):
        GameState.reset_new_game()
    elif GameState.is_dead:
        GameState.revive()
        player.global_position = RESPAWN_POSITION
    spawn_house_from_state()
    GameState.notify("Южный квартал Люменграда открыт • Esc — меню • E — взаимодействие")

func _process(delta: float) -> void:
    if not GameState.is_dead:
        GameState.advance_survival(delta)
    autosave_elapsed += delta
    var autosave_seconds := maxf(30.0, float(SettingsManager.get_value("gameplay", "autosave_seconds")))
    if autosave_elapsed >= autosave_seconds:
        autosave_elapsed = 0.0
        SaveManager.save_game(player)

func _on_player_died() -> void:
    if respawning:
        return
    respawning = true
    await get_tree().create_timer(2.5).timeout
    player.global_position = RESPAWN_POSITION
    player.velocity = Vector3.ZERO
    GameState.revive()
    respawning = false
    GameState.notify("Вы возродились у окраин Люменграда. Часть потребностей восстановлена.")

func spawn_house_from_state() -> void:
    if is_instance_valid(spawned_house):
        spawned_house.queue_free()
        spawned_house = null
    if not GameState.house_built:
        return
    spawned_house = HOUSE_SCENE.instantiate()
    $World.add_child(spawned_house)
    spawned_house.global_position = GameState.house_position
