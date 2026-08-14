extends Node

const VERSION := "0.1.0-stage1"
const AUTOSAVE_SECONDS := 30.0
const HOUSE_SCENE := preload("res://scenes/house.tscn")

@onready var player: CharacterBody3D = $World/Player
@onready var inventory_label: Label = $UI/Panel/VBox/Inventory
@onready var quest_label: Label = $UI/Panel/VBox/Quest
@onready var vitals_label: Label = $UI/Panel/VBox/Vitals
@onready var notice_label: Label = $UI/Notice

var autosave_elapsed := 0.0
var notice_elapsed := 0.0
var spawned_house: Node3D

func _ready() -> void:
    add_to_group("world_root")
    GameState.inventory_changed.connect(_refresh_hud)
    GameState.quest_changed.connect(_refresh_hud)
    GameState.survival_changed.connect(_refresh_vitals)
    GameState.notification_requested.connect(_show_notice)
    if not SaveManager.load_game(player):
        GameState.reset_new_game()
    spawn_house_from_state()
    _refresh_hud()
    _show_notice("WASD — движение | Shift — бег | E — взаимодействие | C — крафт | B — строительство | F5/F9 — сохранить/загрузить")

func _process(delta: float) -> void:
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
    inventory_label.text = "Инвентарь: дерево %d | камень %d | набор %d | топор %d" % [
        int(GameState.inventory.get("wood", 0)),
        int(GameState.inventory.get("stone", 0)),
        int(GameState.inventory.get("building_kit", 0)),
        int(GameState.inventory.get("starter_axe", 0))
    ]
    quest_label.text = "Задание: " + GameState.quest_text()
    _refresh_vitals()

func _refresh_vitals() -> void:
    var hour := int(GameState.world_minutes / 60.0)
    var minute := int(GameState.world_minutes) % 60
    vitals_label.text = "HP %.0f | голод %.0f | жажда %.0f | %02d:%02d" % [
        GameState.health, GameState.hunger, GameState.thirst, hour, minute
    ]

func _show_notice(message: String) -> void:
    notice_label.text = message
    notice_elapsed = 5.0

func spawn_house_from_state() -> void:
    if is_instance_valid(spawned_house):
        spawned_house.queue_free()
        spawned_house = null
    if not GameState.house_built:
        return
    spawned_house = HOUSE_SCENE.instantiate()
    $World.add_child(spawned_house)
    spawned_house.global_position = GameState.house_position
