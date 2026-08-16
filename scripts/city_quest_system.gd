extends Node

const REQUIREMENTS := {"stone": 6, "wood": 4}
const REWARD_COINS := 35
const REWARD_REPUTATION := 5

func _ready() -> void:
    call_deferred("_sync_from_save")

func _sync_from_save() -> void:
    var saved_stage := int(GameState.get_world_value("city_quest_stage", GameState.city_quest_stage))
    var saved_rep := int(GameState.get_world_value("city_reputation", GameState.city_reputation))
    GameState.city_quest_stage = clampi(saved_stage, 0, 2)
    GameState.city_reputation = maxi(saved_rep, GameState.city_reputation)

func start_city_quest() -> bool:
    var stage := _stage()
    if stage != 0:
        return false
    GameState.city_quest_stage = 1
    GameState.set_world_value("city_quest_stage", 1)
    GameState.set_world_value("city_quest_id", "south_gate_repair")
    GameState.quest_changed.emit()
    GameState.notify("Получено поручение кузнеца: 6 камня и 4 древесины для ремонта Южных ворот.")
    return true

func complete_city_quest() -> bool:
    if _stage() != 1 or not GameState.has_items(REQUIREMENTS):
        return false
    for item_id in REQUIREMENTS:
        if not GameState.remove_item(item_id, int(REQUIREMENTS[item_id])):
            return false
    GameState.city_quest_stage = 2
    GameState.city_reputation += REWARD_REPUTATION
    GameState.coins += REWARD_COINS
    GameState.set_world_value("city_quest_stage", 2)
    GameState.set_world_value("city_reputation", GameState.city_reputation)
    GameState.set_world_value("south_gate_repaired", true)
    GameState.set_world_value("city_quest_reward_claimed", true)
    GameState.quest_changed.emit()
    GameState.notify("Южные ворота отремонтированы. Получено 35 монет и +5 репутации Люменграда.")
    return true

func current_stage() -> int:
    return _stage()

func _stage() -> int:
    return clampi(int(GameState.get_world_value("city_quest_stage", GameState.city_quest_stage)), 0, 2)
