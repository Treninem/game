extends Node3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(40.0, true, false, true).timeout.connect(func(): get_tree().quit(99))
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
    var observed_snapshots: Array = []
    var nested_results: Array = []
    var on_inventory := func():
        observed_snapshots.append(JSON.parse_string(JSON.stringify(GameState.snapshot())))
        if nested_results.is_empty():
            # Signal callbacks must not repeat an in-flight withdrawal.
            nested_results.append(false)
            nested_results[0] = chest.transfer(actor, "wood", false, 200)
    GameState.inventory_changed.connect(on_inventory)
    var take_all := -1
    for index in range(DialogueManager.options.size()):
        var option: Dictionary = DialogueManager.options[index]
        if option.get("item") == "wood" and not option.get("deposit", false) and int(option.get("amount", 1)) == 200:
            take_all = index
    assert(take_all >= 0, "Actual storage UI has no bulk withdrawal")
    DialogueManager.choose(take_all)
    GameState.inventory_changed.disconnect(on_inventory)
    DialogueManager.close_dialogue()
    assert(int(GameState.inventory.wood) == total and int(chest.contents().get("wood", 0)) == 0, "Bulk UI does not conserve resources")
    assert(nested_results == [false], "Reentrant withdrawal duplicates resources")
    assert(observed_snapshots.size() == 1)
    GameState.load_snapshot(observed_snapshots[0])
    assert(int(GameState.inventory.wood) == total and int(chest.contents().get("wood", 0)) == 0, "Signal-time save duplicates transferred resources")
    var deposit_snapshots: Array = []
    var on_deposit := func(): deposit_snapshots.append(JSON.parse_string(JSON.stringify(GameState.snapshot())))
    GameState.inventory_changed.connect(on_deposit)
    assert(chest.transfer(actor, "wood", true, 100))
    GameState.inventory_changed.disconnect(on_deposit)
    assert(deposit_snapshots.size() == 1)
    GameState.load_snapshot(deposit_snapshots[0])
    assert(int(GameState.inventory.wood) == total - 100 and int(chest.contents().wood) == 100, "Signal-time deposit save loses resources")
    chest.open_storage(actor)
    var half_index := _choice("wood", false, 50)
    assert(half_index >= 0, "Storage UI has no half withdrawal")
    DialogueManager.choose(half_index)
    assert(int(chest.contents().wood) == 50 and int(GameState.inventory.wood) == total - 50)
    GameState.add_item("stone", 20)
    var stone_before := int(GameState.inventory.stone)
    chest.open_storage(actor)
    half_index = _choice("stone", true, stone_before / 2)
    assert(half_index >= 0, "Storage UI has no half deposit")
    DialogueManager.choose(half_index)
    assert(int(chest.contents().stone) == stone_before / 2 and int(GameState.inventory.stone) == stone_before - stone_before / 2)
    DialogueManager.close_dialogue()
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

func _choice(item: String, deposit: bool, amount: int) -> int:
    for index in range(DialogueManager.options.size()):
        var option: Dictionary = DialogueManager.options[index]
        if option.get("item") == item and option.get("deposit", false) == deposit and int(option.get("amount", 1)) == amount:
            return index
    return -1
