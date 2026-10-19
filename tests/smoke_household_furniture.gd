extends Node3D

var errors: Array[String] = []
var home: EnterableBuilding
var residents: Array[SettlementNPC] = []
var advance_clock := false

func _physics_process(delta: float) -> void:
    if advance_clock:
        GameState.advance_survival(delta)

func _ready() -> void:
    get_tree().create_timer(130).timeout.connect(func():
        push_error("Household fixture watchdog expired")
        get_tree().quit(1))
    call_deferred("_run")

func frames(count: int) -> void:
    for frame in range(count):
        await get_tree().physics_frame

func build_home() -> void:
    home = preload("res://scripts/enterable_building.gd").new()
    home.name = "SquareHome"
    home.configure(Vector3(12, 3.2, 10))
    home.set_meta("household_owners", ["household:test:0", "household:test:1"])
    add_child(home)

func build_residents() -> void:
    residents.clear()
    for index in range(2):
        var npc := preload("res://scripts/settlement_npc.gd").new()
        npc.name = "Resident%d" % index
        npc.configure("Тестовый житель", "trader" if index == 0 else "craftsman", index, [])
        npc.autonomous = true
        npc.set_meta("citizen_id", "household:test:%d" % index)
        npc.set_meta("home_building", "SquareHome")
        npc.set_meta("routine_places", {"home": Vector3(0, 0, 1), "work": Vector3(-1 if index == 0 else 1, 0, 1)})
        npc.position = Vector3(-1 if index == 0 else 1, 0.22, 1)
        add_child(npc)
        residents.append(npc)

func _run() -> void:
    GameState.reset_new_game()
    # A bounded physical interior fixture; this does not claim a world journey.
    position = Vector3(CapitalData.CENTER.x, 0, CapitalData.CENTER.y)
    build_home()
    build_residents()
    GameState.world_minutes = 21 * 60
    advance_clock = true
    for frame in range(2400):
        await frames(1)
        if GameState.get_world_value("household:household:test:0", {}).get("stored", false) and GameState.get_world_value("household:household:test:1", {}).get("stored", false):
            break
    var chest := home.get_node("InteriorFurniture/StorageChest") as HouseholdFurniture
    if int(chest.contents().get("berries", 0)) != 2:
        errors.append("Residents did not physically visit and store their finite personal belongings: %s %s" % [chest.contents(), residents.map(func(n): return [n.position, n.activity])])
    var clearing_snapshot := JSON.parse_string(JSON.stringify(GameState.snapshot())) as Dictionary
    GameState.load_snapshot(clearing_snapshot)
    await frames(3)
    if int(chest.contents().get("berries", 0)) != 2:
        errors.append("Loading during chest departure loses or duplicates personal belongings")
    GameState.world_minutes = 21.5 * 60
    for frame in range(1200):
        await frames(1)
        if residents.all(func(n): return n.get_meta("activity") == "sit"):
            break
    var seated := false
    for npc in residents:
        if npc.get_meta("activity") == "sit" and npc.visual.top_level:
            seated = true
    if not seated or not residents.all(func(n): return n.get_meta("activity") == "sit"):
        errors.append("Both residents must physically use their individual benches: %s" % [residents.map(func(n): return [n.position, n.activity, n._household_state()])])
    var seated_snapshot := JSON.parse_string(JSON.stringify(GameState.snapshot())) as Dictionary
    GameState.load_snapshot(seated_snapshot)
    await frames(90)
    if not residents.any(func(n): return n.get_meta("activity") == "sit"):
        errors.append("Save restore loses occupied bench pose")
    GameState.world_minutes = 22 * 60
    for frame in range(1800):
        await frames(1)
        if residents.all(func(n): return n.get_meta("activity") == "sleep"):
            break
    for npc in residents:
        if npc.get_meta("activity") != "sleep" or not npc.visual.top_level or not npc.is_on_floor():
            errors.append("Resident did not reach its own supported bed: %s %s" % [npc.position, npc.activity])
        elif absf(npc.visual.global_basis.y.dot(Vector3.UP)) > 0.1:
            errors.append("Sleeping resident remains upright")
    advance_clock = false
    var saved := JSON.parse_string(JSON.stringify(GameState.snapshot())) as Dictionary
    var occupied := chest.contents()
    for npc in residents:
        npc.free()
    home.free()
    build_home()
    build_residents()
    await frames(120)
    if not residents.all(func(n): return n.get_meta("activity") == "sleep"):
        errors.append("Streaming recreation loses sleeping residents")
    chest = home.get_node("InteriorFurniture/StorageChest") as HouseholdFurniture
    if chest.contents() != occupied:
        errors.append("Streaming recreation duplicates or loses belongings")
    GameState.world_minutes = 9 * 60
    await frames(10)
    GameState.load_snapshot(saved)
    await frames(120)
    if not residents.all(func(n): return n.get_meta("activity") == "sleep"):
        errors.append("In-place save restore loses sleeping poses")
    GameState.world_minutes = 9 * 60
    await frames(4)
    GameState.world_minutes = 21 * 60
    for frame in range(1800):
        await frames(1)
        if residents.all(func(n): return n.get_meta("activity") == "sit"):
            break
    if not residents.all(func(n): return n.get_meta("activity") == "sit"):
        errors.append("Simultaneous wake and evening return deadlocks the two bench approaches: %s" % [residents.map(func(n): return [n.position, n.activity, n._household_state()])])
    GameState.world_minutes = 9 * 60
    await frames(240)
    for npc in residents:
        if npc.visual.top_level or npc.get_meta("activity") in ["sleep", "sit"]:
            errors.append("Resident cannot wake and leave furniture")
    for furniture in get_tree().get_nodes_in_group("household_furniture"):
        if not furniture.occupant.is_empty():
            errors.append("Waking leaves a stale furniture reservation: " + furniture.furniture_id)
    GameState.world_minutes = 21 * 60
    await frames(420)
    if chest.contents() != occupied:
        errors.append("Repeated household cycle creates additional goods")
    GameState.world_minutes = 9 * 60
    await frames(5)
    for npc in residents:
        npc.free()
    var private_chest := chest
    chest = home.get_node("InteriorFurniture/GuestChest") as HouseholdFurniture
    var actor := CharacterBody3D.new()
    actor.name = "StorageTestPlayer"
    actor.add_to_group("player")
    actor.position = to_local(chest.approach_point())
    actor.position.y = 0.2
    add_child(actor)
    await frames(3)
    actor.global_position = private_chest.approach_point()
    var protected_items := private_chest.contents()
    if private_chest.transfer(actor, "berries", false) or private_chest.contents() != protected_items or private_chest.claim("player"):
        errors.append("Private storage allows unauthorized player access")
    actor.global_position = chest.approach_point()
    GameState.add_item("wood", 3)
    GameState.add_item("starter_axe", 1)
    var total := int(GameState.inventory.get("wood", 0)) + int(chest.contents().get("wood", 0))
    chest.interact(actor)
    var deposit_index := -1
    for index in range(DialogueManager.options.size()):
        var choice: Dictionary = DialogueManager.options[index]
        if choice.get("item") == "wood" and choice.get("deposit", false):
            deposit_index = index
            break
    if deposit_index < 0:
        errors.append("Actual chest dialogue has no deposit action")
    else:
        DialogueManager.choose(deposit_index)
    if int(chest.contents().get("wood", 0)) != 1 or total != int(GameState.inventory.get("wood", 0)) + int(chest.contents().get("wood", 0)):
        errors.append("UI chest deposit does not conserve real inventory")
    DialogueManager.close_dialogue()
    InventorySystem.equip("starter_axe")
    if chest.transfer(actor, "starter_axe", true):
        errors.append("Chest removes equipped equipment")
    InventorySystem.unequip(InventorySystem.SLOT_WEAPON)
    if not chest.transfer(actor, "starter_axe", true) or not chest.transfer(actor, "starter_axe", false):
        errors.append("Unequipped equipment cannot be stored and recovered")
    var batch := int(GameState.inventory.get("wood", 0))
    if not chest.transfer(actor, "wood", true, batch) or int(chest.contents().get("wood", 0)) != total:
        errors.append("Bulk deposit loses resources")
    if not chest.transfer(actor, "wood", false, batch) or int(chest.contents().get("wood", 0)) != 1:
        errors.append("Bulk withdrawal loses resources")
    var untouched := GameState.inventory.duplicate(true)
    if chest.transfer(actor, "wood", true, 201) or untouched != GameState.inventory:
        errors.append("Capacity failure changes player inventory")
    if not SaveManager.save_game(actor, 4):
        errors.append("Actual disk save of chest failed")
    var disk_items := chest.contents()
    chest.transfer(actor, "wood", false)
    if not SaveManager.load_game(actor, 4) or chest.contents() != disk_items or private_chest.allows("player") or not chest.allows("player"):
        errors.append("Actual disk load loses chest contents")
    actor.position.x -= 7
    var before := GameState.inventory.duplicate(true)
    if chest.transfer(actor, "wood", false) or before != GameState.inventory:
        errors.append("Chest allows remote transfer or changes inventory on failure")
    var bed := home.get_node("InteriorFurniture/Bed") as HouseholdFurniture
    if not bed.claim("one") or bed.claim("two"):
        errors.append("Bed allows simultaneous occupants")
    bed.release("one")
    for error in errors:
        push_error(error)
    if errors.is_empty():
        print("HOUSEHOLD_FURNITURE_OK chest=finite_actual_transfers bench=occupied beds=two_supported_poses streaming=restored save=JSON_round_trip wake=reservations_released")
    get_tree().quit(0 if errors.is_empty() else 1)
