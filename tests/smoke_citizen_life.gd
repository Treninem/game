extends Node

const CITIZEN := preload("res://scripts/settlement_npc.gd")
var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _make_citizen(parent: Node3D, role: String, stable_id: String, offset: Vector3) -> CharacterBody3D:
    var citizen := CITIZEN.new()
    citizen.name = "CityResident_1"
    citizen.autonomous = true
    citizen.position = offset
    citizen.set_meta("citizen_id", stable_id)
    citizen.configure("Проверочный торговец" if role == "trader" else "Путник", role, 0, [])
    parent.add_child(citizen)
    return citizen

func _run() -> void:
    GameState.reset_new_game()
    var world := Node3D.new()
    world.position = Vector3(65, 0, 48)
    add_child(world)
    var height := WorldData.elevation_at(Vector2(65, 48))
    var floor := StaticBody3D.new()
    floor.position.y = height - 0.5
    world.add_child(floor)
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(100, 1, 100)
    collision.shape = box
    floor.add_child(collision)
    var merchant := _make_citizen(world, "trader", "test_merchant", Vector3(-12, height + 0.1, -12))
    var traveler := _make_citizen(world, "traveler", "test_traveler", Vector3(12, height + 0.1, 12))
    if merchant.routine_plan(9 * 60).target == merchant.routine_plan(23 * 60).target:
        failures.append("Merchant has the same destination at work and at home")
    if traveler.routine_plan(9 * 60).target == traveler.routine_plan(15 * 60).target:
        failures.append("Traveler has no outbound and return destinations")
    GameState.world_minutes = 9 * 60
    for frame in range(120):
        await get_tree().physics_frame
    var before := traveler.global_position
    merchant.interact(self)
    for frame in range(120):
        await get_tree().physics_frame
    if traveler.global_position.distance_to(before) < 1.0:
        failures.append("An unrelated citizen stops merely because another is in dialogue")
    DialogueManager.close_dialogue()
    var coins := GameState.coins
    var berries := int(GameState.inventory.get("berries", 0))
    if not merchant.complete_trade("berries", false) or GameState.coins != coins - 2 or int(GameState.inventory.get("berries", 0)) != berries + 1:
        failures.append("Purchase does not exchange coins for exactly one item")
    GameState.coins = 0
    berries = int(GameState.inventory.get("berries", 0))
    if merchant.complete_trade("berries", false) or int(GameState.inventory.get("berries", 0)) != berries:
        failures.append("Merchant gives items without payment")
    GameState.add_item("wood", 1)
    if not merchant.complete_trade("wood", true) or GameState.coins != 1:
        failures.append("Selling a resource does not pay the agreed price")
    var stock: Dictionary = merchant._shop_stock()
    stock.berries = 0
    GameState.set_world_value("shop:test_merchant", stock)
    GameState.coins = 20
    if merchant.complete_trade("berries", false):
        failures.append("Merchant sells out-of-stock goods")
    merchant.queue_free()
    await get_tree().process_frame
    merchant = _make_citizen(world, "trader", "test_merchant", Vector3(-12, height + 0.1, -12))
    if int(merchant._shop_stock().berries) != 0:
        failures.append("Unloading a merchant restores exhausted stock")
    merchant.free()
    traveler.free()
    var walker := CITIZEN.new()
    walker.name = "CityResident_1"
    walker.configure("Прохожий", "trader", 0, [Vector3(-12, 0, -12), Vector3(12, 0, 12)])
    walker.position = Vector3(-12, height + 0.1, -12)
    world.add_child(walker)
    if not walker.autonomous:
        failures.append("Legacy civilian still patrols four corners")
    var wall := StaticBody3D.new()
    wall.position = Vector3(-1, height + 1.5, -12)
    var wall_shape := CollisionShape3D.new()
    var wall_box := BoxShape3D.new()
    wall_box.size = Vector3(1, 3, 8)
    wall_shape.shape = wall_box
    wall.add_child(wall_shape)
    world.add_child(wall)
    GameState.world_minutes = 9 * 60
    for frame in range(1800):
        await get_tree().physics_frame
    var destination: Vector3 = world.to_global(walker.routine_plan(9 * 60).target)
    if Vector2(walker.global_position.x, walker.global_position.z).distance_to(Vector2(destination.x, destination.z)) > 1.2:
        failures.append("Civilian cannot reach its work destination around a wall")
    if failures.is_empty():
        print("CITIZEN_LIFE_OK schedules=day_night travel=outbound_return conversations=local trade=paid stock=persistent legacy_civilians=schedules obstacle=walked_around")
    for failure in failures:
        push_error(failure)
    get_tree().quit(0 if failures.is_empty() else 1)
