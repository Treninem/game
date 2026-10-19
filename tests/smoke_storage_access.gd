extends Node3D

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    GameState.reset_new_game()
    var home := preload("res://scripts/enterable_building.gd").new()
    home.configure(Vector3(12, 3.2, 10))
    home.set_meta("household_owners", ["owner"])
    add_child(home)
    var chest := home.get_node("InteriorFurniture/GuestChest") as HouseholdFurniture
    var private_chest := home.get_node("InteriorFurniture/StorageChest") as HouseholdFurniture
    var actor := CharacterBody3D.new()
    actor.add_to_group("player")
    add_child(actor)
    actor.global_position = chest.approach_point()
    for frame in range(3):
        await get_tree().physics_frame
    GameState.add_item("wood", 1000)
    var total := int(GameState.inventory.wood)
    assert(chest.transfer(actor, "wood", true, 200), "Full-capacity bulk deposit failed")
    assert(chest.free_capacity() == 0 and int(chest.contents().wood) == 200)
    var before := GameState.inventory.duplicate(true)
    assert(not chest.transfer(actor, "wood", true) and before == GameState.inventory, "Full chest changes inventory")
    assert(not chest.transfer(actor, "wood", false, 201) and before == GameState.inventory, "Oversized withdrawal changes inventory")
    assert(not chest.transfer(actor, "wood", true, 0) and not chest.transfer(actor, "wood", false, -1))
    chest.open_storage(actor)
    var take_all := -1
    for index in range(DialogueManager.options.size()):
        var option: Dictionary = DialogueManager.options[index]
        if option.get("item") == "wood" and not option.get("deposit", false) and int(option.get("amount", 1)) == 200:
            take_all = index
    assert(take_all >= 0, "Actual storage UI has no bulk withdrawal")
    DialogueManager.choose(take_all)
    DialogueManager.close_dialogue()
    assert(int(GameState.inventory.wood) == total and int(chest.contents().get("wood", 0)) == 0, "Bulk UI does not conserve resources")
    actor.global_position = private_chest.approach_point()
    private_chest.open_storage(actor)
    assert(not DialogueManager.is_open and not private_chest.transfer(actor, "wood", true), "Private chest is writable by stranger")
    assert(private_chest.claim("owner"), "Owner cannot reserve its chest")
    var saved := JSON.parse_string(JSON.stringify(GameState.snapshot())) as Dictionary
    GameState.load_snapshot(saved)
    assert(not private_chest.allows("player") and private_chest.allows("owner") and chest.allows("player"), "Access rights lost through JSON save")
    private_chest.release("owner")
    print("STORAGE_ACCESS_OK bulk=200 actual_UI=true capacity=atomic ownership=saved")
    get_tree().quit(0)
