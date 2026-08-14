extends Node

const VERSION := "0.2.0-stage2"
const AUTOSAVE_SECONDS := 30.0
const HOUSE_SCENE := preload("res://scenes/house.tscn")
const RESPAWN_POSITION := Vector3(0, 1, 8)

@onready var player: CharacterBody3D = $World/Player
@onready var inventory_label: Label = $UI/Panel/VBox/Inventory
@onready var quest_label: Label = $UI/Panel/VBox/Quest
@onready var vitals_label: Label = $UI/Panel/VBox/Vitals
@onready var combat_label: Label = $UI/Panel/VBox/Combat
@onready var notice_label: Label = $UI/Notice

var autosave_elapsed := 0.0
var notice_elapsed := 0.0
var spawned_house: Node3D
var respawning := false

func _ready() -> void:
    add_to_group("world_root")
    GameState.inventory_changed.connect(_refresh_hud)
    GameState.quest_changed.connect(_refresh_hud)
    GameState.survival_changed.connect(_refresh_vitals)
    GameState.notification_requested.connect(_show_notice)
    GameState.player_died.connect(_on_player_died)
    if not SaveManager.load_game(player):
        GameState.reset_new_game()
    elif GameState.is_dead:
        GameState.revive()
        player.global_position = RESPAWN_POSITION
    spawn_house_from_state()
    _refresh_hud()
    _show_notice("WASD движение | Shift бег | ЛКМ атака | E действие | 1 ягоды | 2 вода | 3 мясо | C крафт | B стройка | F5/F9")

func _process(delta: float) -> void:
    if not GameState.is_dead:
        GameState.advance_survival(delta)
    autosave_elapsed += delta
    if autosave_elapsed >= AUTOSAVE_SECONDS:
        autosave_elapsed = 0.0
        SaveManager.save_game(player)
    if notice_elapsed > 0.0:
        notice_elapsed -= delta
        if notice_elapsed <= 0.0:
            notice_label.text = ""

func _exit_tree() -> void:
    if is_instance_valid(player):
        SaveManager.save_game(player)

func _refresh_hud() -> void:
    inventory_label.text = "Ресурсы: дерево %d | камень %d | набор %d | топор %d | ягоды %d | вода %d | мясо %d" % [
        int(GameState.inventory.get("wood", 0)),
        int(GameState.inventory.get("stone", 0)),
        int(GameState.inventory.get("building_kit", 0)),
        int(GameState.inventory.get("starter_axe", 0)),
        int(GameState.inventory.get("berries", 0)),
        int(GameState.inventory.get("water_flask", 0)),
        int(GameState.inventory.get("raw_meat", 0))
    ]
    quest_label.text = "Задание: " + GameState.quest_text()
    combat_label.text = "Побеждено существ: %d | оружие: %s" % [
        GameState.enemies_defeated,
        "стартовый топор" if int(GameState.inventory.get("starter_axe", 0)) > 0 else "без оружия"
    ]
    _refresh_vitals()

func _refresh_vitals() -> void:
    var hour := int(GameState.world_minutes / 60.0)
    var minute := int(GameState.world_minutes) % 60
    vitals_label.text = "HP %.0f/%.0f | stamina %.0f | голод %.0f | жажда %.0f | t %.1f°C | %02d:%02d" % [
        GameState.health, GameState.max_health, GameState.stamina,
        GameState.hunger, GameState.thirst, GameState.temperature, hour, minute
    ]

func _show_notice(message: String) -> void:
    notice_label.text = message
    notice_elapsed = 5.0

func _on_player_died() -> void:
    if respawning:
        return
    respawning = true
    await get_tree().create_timer(2.5).timeout
    player.global_position = RESPAWN_POSITION
    player.velocity = Vector3.ZERO
    GameState.revive()
    respawning = false
    _show_notice("Вы возродились. Часть потребностей восстановлена.")

func spawn_house_from_state() -> void:
    if is_instance_valid(spawned_house):
        spawned_house.queue_free()
        spawned_house = null
    if not GameState.house_built:
        return
    spawned_house = HOUSE_SCENE.instantiate()
    $World.add_child(spawned_house)
    spawned_house.global_position = GameState.house_position
