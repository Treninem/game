extends Node3D

@export var persistent_id: String = ""
@export var resource_id: String = "wood"
@export var display_name: String = "ресурс"
@export var amount_per_use: int = 1
@export var uses: int = 4

func _ready() -> void:
    if persistent_id.is_empty():
        persistent_id = String(name)
    var saved_uses = GameState.get_world_value("resource:" + persistent_id, uses)
    uses = maxi(0, int(saved_uses))
    _apply_depleted_state()

func interact(_player: Node) -> void:
    if uses <= 0:
        GameState.notify("Здесь больше нечего добывать.")
        return
    GameState.add_item(resource_id, amount_per_use)
    uses -= 1
    GameState.set_world_value("resource:" + persistent_id, uses)
    GameState.notify("Получено: %s +%d" % [display_name, amount_per_use])
    _apply_depleted_state()

func _apply_depleted_state() -> void:
    if uses > 0:
        visible = true
        set_deferred("use_collision", true)
        return
    visible = false
    set_deferred("use_collision", false)
