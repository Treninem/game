extends Node3D

@export var resource_id: String = "wood"
@export var display_name: String = "ресурс"
@export var amount_per_use: int = 1
@export var uses: int = 4

func interact(_player: Node) -> void:
    if uses <= 0:
        GameState.notify("Здесь больше нечего добывать.")
        return
    GameState.add_item(resource_id, amount_per_use)
    uses -= 1
    GameState.notify("Получено: %s +%d" % [display_name, amount_per_use])
    if uses <= 0:
        visible = false
        if "use_collision" in self:
            set_deferred("use_collision", false)
