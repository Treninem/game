extends Node

func _ready() -> void:
    await get_tree().process_frame
    GameState.reset_new_game()

    var failures: Array[String] = []
    if CityQuestSystem.current_stage() != 0:
        failures.append("new game city quest did not start at stage 0")

    if not CityQuestSystem.start_city_quest():
        failures.append("South Gate quest could not be started")
    if CityQuestSystem.current_stage() != 1:
        failures.append("South Gate quest did not enter active stage")
    if int(GameState.get_world_value("city_quest_stage", -1)) != 1:
        failures.append("active quest stage was not persisted into world_state")

    GameState.add_item("stone", 6)
    GameState.add_item("wood", 4)
    var coins_before := GameState.coins
    var reputation_before := GameState.city_reputation
    if not CityQuestSystem.complete_city_quest():
        failures.append("South Gate quest did not complete with required materials")
    if CityQuestSystem.current_stage() != 2:
        failures.append("completed quest did not enter stage 2")
    if GameState.coins != coins_before + 35:
        failures.append("quest reward did not add 35 coins")
    if GameState.city_reputation != reputation_before + 5:
        failures.append("quest reward did not add 5 reputation")
    if int(GameState.inventory.get("stone", 0)) != 0 or int(GameState.inventory.get("wood", 0)) != 0:
        failures.append("quest materials were not consumed")
    if not bool(GameState.get_world_value("south_gate_repaired", false)):
        failures.append("south_gate_repaired world flag was not set")

    if CityQuestSystem.start_city_quest():
        failures.append("completed South Gate quest became startable again")

    if not failures.is_empty():
        for failure in failures:
            push_error("City quest smoke: " + failure)
        get_tree().quit(1)
        return

    print("CITY_QUEST_SMOKE_CHECKPOINT: passed")
    get_tree().quit(0)
