extends Node

var errors: Array[String] = []
var player: CharacterBody3D
var walked := 0.0

func _ready() -> void:
    get_tree().create_timer(240).timeout.connect(func():
        push_error("Square home/life watchdog expired")
        get_tree().quit(1)
    )
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await get_tree().physics_frame

func _walk(offset: Vector2) -> void:
    var target := CapitalData.CENTER + offset
    for frame in range(1200):
        var point := Vector2(player.global_position.x, player.global_position.z)
        if point.distance_to(target) < 0.35:
            Input.action_release("move_forward")
            await _frames(8)
            return
        var direction := target - point
        player.rotation.y = atan2(-direction.x, -direction.y)
        var before := player.global_position
        Input.action_press("move_forward")
        await get_tree().physics_frame
        walked += before.distance_to(player.global_position)
    Input.action_release("move_forward")
    errors.append("Player could not physically walk to %s; ended %s" % [offset, player.global_position])

func _capture(label: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("user://home-" + label + ".png")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    await _frames(100)
    world.set_process(false)
    GameState.world_minutes = 9 * 60
    player = world.get_node("World/Player")
    # Isolated interaction fixture, not a fresh forest-to-capital journey.
    player.global_position = Vector3(CapitalData.CENTER.x - 45, 0.08, CapitalData.CENTER.y - 21)
    player.call("_begin_ground_guard", true)
    await _frames(240)
    var cell: Node3D = world.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO]
    var square := cell.get_node("CapitalSquareLife")
    var home := square.get_node("SquareHome") as EnterableBuilding
    var trader := square.get_node("SquareTrader") as SettlementNPC
    var artisan := square.get_node("SquareArtisan") as SettlementNPC
    if not home.get_meta("real_furniture_visuals", false):
        errors.append("Live capital home does not reuse the authored bed/table decorator")
    if not home.has_node("SharedRoofGables"):
        errors.append("Live home roof still has an open attic triangle")
    var floor_top := home.global_position.y + home.floor_thickness
    if floor_top < WorldData.elevation_at(CapitalData.CENTER) + 0.045:
        errors.append("Home floor is coplanar with the city paving")
    for prop_name in ["Bed", "Table"]:
        var textured := false
        for mesh: MeshInstance3D in home.get_node("InteriorFurniture/" + prop_name).find_children("*", "MeshInstance3D", true, false):
            for surface in range(mesh.mesh.get_surface_count()):
                var material := mesh.get_active_material(surface) as StandardMaterial3D
                if material != null and material.albedo_texture != null:
                    textured = true
        if not textured:
            errors.append("Authored furniture lost its restored wood material: " + prop_name)
    var door := home.front_door
    var origin := home.to_global(Vector3(0, 1.2, 8))
    var end := home.to_global(Vector3(0, 1.2, 0))
    var query := PhysicsRayQueryParameters3D.create(origin, end, 1, [player.get_rid()])
    if get_viewport().world_3d.direct_space_state.intersect_ray(query).get("collider") != door:
        errors.append("Closed live home door does not block its actual opening")
    door.interact(player)
    await _frames(50)
    if not bool(GameState.get_world_value("door:capital:square:home", false)):
        errors.append("Opening the live home door is not retained in world state")
    if not get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty():
        errors.append("Opened live home passage is blocked: %s" % get_viewport().world_3d.direct_space_state.intersect_ray(query).get("collider"))
    await _walk(Vector2(-45, -29))
    if not player.is_on_floor() or absf(player.global_position.y - 0.025) > 0.08:
        errors.append("Player floats or drops while entering the home")
    await _capture("inside")
    await _walk(Vector2(-45, -21))
    await _walk(Vector2(-35, -21))
    door.interact(player)
    await _frames(50)
    if door.opened:
        errors.append("Door cannot be closed after leaving the room")
    if bool(GameState.get_world_value("door:capital:square:home", true)):
        errors.append("Closing the live home door is not retained in world state")
    await _walk(Vector2(-45, -23))
    var observer := preload("res://scripts/settlement_npc.gd").new()
    observer.configure("Свидетель за дверью", "resident", 0, [])
    observer.set_meta("citizen_id", "test:home:occluded")
    observer.position = Vector3(-45, 0.08, -29)
    square.add_child(observer)
    await _frames(5)
    MagicSystem.selected_index = MagicSystem.SPELL_ORDER.find("shield")
    if not MagicSystem.cast_selected(player, player.camera):
        errors.append("Occluded witness fixture could not cast a real shield")
    if GameState.get_world_value("memory:test:home:occluded", {}).has("spell"):
        errors.append("Resident sees magic through the closed physical door")
    if GameState.get_world_value("memory:" + trader.citizen_id, {}).has("spell"):
        errors.append("Distant trader sees magic outside the observation radius")
    observer.free()
    await _walk(Vector2(-35, -21))
    GameState.world_minutes = 22 * 60
    var streamed_mid_door := false
    for frame in range(5400):
        await get_tree().physics_frame
        if not streamed_mid_door and (trader.home_crossing or artisan.home_crossing):
            var trader_point := trader.position
            var artisan_point := artisan.position
            GameState.snapshot()
            square.free()
            square = preload("res://scripts/capital_square_life.gd").new()
            square.name = "CapitalSquareLife"
            cell.add_child(square)
            trader = square.get_node("SquareTrader") as SettlementNPC
            artisan = square.get_node("SquareArtisan") as SettlementNPC
            home = square.get_node("SquareHome") as EnterableBuilding
            door = home.front_door
            if trader.position.distance_to(trader_point) > 0.02 or artisan.position.distance_to(artisan_point) > 0.02:
                errors.append("Reloading the real square during doorway transit resets resident positions")
            streamed_mid_door = true
        if frame % 600 == 0:
            print("HOME_PROGRESS frame=", frame, " trader=", square.to_local(trader.global_position), " artisan=", square.to_local(artisan.global_position))
        if trader.activity == "Отдыхает дома" and artisan.activity == "Отдыхает дома":
            break
    for npc in [trader, artisan]:
        var local := home.to_local(npc.global_position)
        if local.z > 4 or absf(local.x) > 5.5 or npc.activity != "Отдыхает дома":
            errors.append("Resident did not return through the real doorway: %s %s %s" % [npc.display_name, local, npc.activity])
    if not streamed_mid_door:
        errors.append("Home streaming fixture never exercised a real doorway transition")
    await _capture("residents-evening")
    trader.interact(player)
    if "Лавка закрыта" not in DialogueManager.text or trader.complete_trade("arrow", false):
        errors.append("Home schedule still exposes all-night trading")
    DialogueManager.close_dialogue()
    GameState.world_minutes = 9 * 60
    for frame in range(5400):
        await get_tree().physics_frame
        if frame % 600 == 0:
            print("WORK_PROGRESS frame=", frame, " trader=", square.to_local(trader.global_position), " artisan=", square.to_local(artisan.global_position))
        if trader.activity == "Торгует" and artisan.activity == "Ждёт материалы у верстака":
            break
    if trader.activity != "Торгует" or artisan.activity != "Ждёт материалы у верстака":
        errors.append("Residents could not leave home and resume their actual workplaces")
    # Real trade, finite purses, failed transactions and persistent memory.
    GameState.coins = 0
    var stock := trader._shop_stock().duplicate(true)
    stock.coins = 0
    GameState.set_world_value("shop:" + trader.citizen_id, stock)
    GameState.add_item("wood", 2)
    var before_inventory := GameState.inventory.duplicate(true)
    if trader.complete_trade("wood", true) or trader.complete_trade("starter_axe", false):
        errors.append("Trade succeeds despite an empty buyer purse")
    if before_inventory != GameState.inventory or GameState.coins != 0:
        errors.append("Failed trade consumes goods or changes player money")
    stock.coins = 20
    GameState.set_world_value("shop:" + trader.citizen_id, stock)
    if not trader.complete_trade("wood", true) or GameState.coins != 1 or int(trader._shop_stock().coins) != 19:
        errors.append("Successful supply sale does not conserve the two purses")
    trader.interact(player)
    if "Спасибо за материалы" not in DialogueManager.text:
        errors.append("Trader does not remember a real supply sale")
    DialogueManager.close_dialogue()
    GameState.coins = 12
    var total := GameState.coins + int(trader._shop_stock().coins)
    if not trader.complete_trade("starter_axe", false) or GameState.coins != 0 or total != GameState.coins + int(trader._shop_stock().coins):
        errors.append("Weapon purchase does not transfer exactly twelve coins")
    if not InventorySystem.equip("starter_axe"):
        errors.append("Purchased axe cannot be equipped")
    InventorySystem.unequip(InventorySystem.SLOT_WEAPON)
    # Cast the actual shield through MagicSystem while physically approaching
    # the trader; observation must originate from the successful cast signal.
    await _walk(Vector2(-16, -5))
    MagicSystem.selected_index = MagicSystem.SPELL_ORDER.find("shield")
    if not MagicSystem.cast_selected(player, player.camera):
        errors.append("Actual shield cast failed")
    trader.interact(player)
    if "Магический щит" not in DialogueManager.text:
        errors.append("Nearby trader did not remember the visible successful spell")
    await _capture("merchant-memory")
    DialogueManager.close_dialogue()
    MagicSystem.selected_index = MagicSystem.SPELL_ORDER.find("fireball")
    player.camera.look_at(player.camera.global_position + Vector3(0, 0, 20), Vector3.UP)
    if not MagicSystem.cast_selected(player, player.camera):
        errors.append("Actual nearby dangerous spell cast failed")
    await _frames(2)
    if trader.witnessed_pause <= 0 or "Не колдуйте" not in trader.activity:
        errors.append("Nearby dangerous magic does not interrupt resident activity")
    var saved := GameState.snapshot()
    var remembered := trader._context_line()
    var purse := int(trader._shop_stock().coins)
    GameState.reset_new_game()
    GameState.load_snapshot(saved)
    if trader._context_line() != remembered or int(trader._shop_stock().coins) != purse:
        errors.append("World save round trip loses merchant purse or personal memory")
    await _frames(380)
    if trader.witnessed_pause > 0 or trader.activity != "Торгует":
        errors.append("Resident does not resume its real schedule after the reaction expires")
    for error in errors:
        push_error(error)
    if errors.is_empty():
        print("SQUARE_HOME_LIFE_OK player_walk_m=", walked, " door=physical_round_trip residents=home_and_work streaming=mid_door_resumed money=conserved memory=supply_and_real_spell")
    world.queue_free()
    await get_tree().process_frame
    get_tree().quit(0 if errors.is_empty() else 1)
