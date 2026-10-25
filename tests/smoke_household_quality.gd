extends Node3D

func _ready() -> void:
    get_tree().create_timer(15).timeout.connect(func(): get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    position = Vector3(CapitalData.CENTER.x, 0, CapitalData.CENTER.y)
    var square := preload("res://scripts/capital_square_life.gd").new()
    add_child(square)
    var light := square.get_node("HomeLanternLight") as SpotLight3D
    assert(light != null)
    var trader := square.get_node("SquareTrader") as SettlementNPC
    var artisan := square.get_node("SquareArtisan") as SettlementNPC
    assert(trader.visual.current_profile.sex == "female", "Marta did not get her authored female body")
    assert(artisan.visual.current_profile.sex == "male", "Marek did not get his authored male body")
    assert(trader.display_name == "Марта" and artisan.display_name == "Марек", "Citizen names have corrupt text encoding")
    assert(trader.citizen_id == "capital:square:provisions" and artisan.citizen_id == "capital:square:fletcher", "Display name repair changed saved citizen identities")
    assert(square.get_node("SquareHome").building_label == "Дом Марты и Марека", "Home name has corrupt text encoding")
    for citizen: SettlementNPC in [trader, artisan]:
        citizen.interact(null)
        assert(DialogueManager.speaker == citizen.display_name, "Actual dialogue lost the citizen name")
        DialogueManager.close_dialogue()
    for resident in get_tree().get_nodes_in_group("settlement_npc"):
        assert(resident.find_children("*", "Label3D", true, false).is_empty(), "Resident has floating labels")
    var manager := preload("res://scripts/dungeon_manager_npc.gd").new()
    add_child(manager)
    assert(manager.find_children("*", "Label3D", true, false).is_empty(), "Manager has a floating label")
    assert(not manager.find_children("*", "Skeleton3D", true, false).is_empty(), "Manager still uses primitive geometry")
    var old := int(SettingsManager.get_value("graphics", "quality_preset"))
    for preset in [0, 1, 2, 3, 0]:
        SettingsManager.set_quality_preset(preset)
        assert(light.shadow_enabled == (preset > 0), "Indoor shadow ignores graphics preset")
    SettingsManager.set_quality_preset(old)
    print("HOUSEHOLD_QUALITY_OK presets=low_medium_high_ultra low_indoor_shadow=off runtime_switch=ok")
    get_tree().quit(0)
