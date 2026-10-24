extends SceneTree
var player:CharacterBody3D
func _initialize()->void:call_deferred("_run")
func _run()->void:
    assert(root.get_node("SaveManager").prepare_load(8),"Requires the real native canal home save, not a minted arrival fixture")
    var file:=FileAccess.open("user://save_slot_08.json",FileAccess.READ);var payload:Dictionary=JSON.parse_string(file.get_as_text());file.close()
    var expected_position:=Vector3(payload.player.position[0],payload.player.position[1],payload.player.position[2])
    change_scene_to_file("res://scenes/world_loading.tscn")
    var deadline:=Time.get_ticks_msec()+120000
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or not bool(current_scene.get("startup_state_ready")) or player.ground_guard_active:
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec()>deadline:push_error("Saved canal home failed real process/bootstrap load");quit(1);return
    current_scene.set_process(false)
    for frame in range(40):await physics_frame
    assert(player.is_on_floor() and not player.ground_guard_active and player.global_position.distance_to(expected_position)<.08)
    var state:=root.get_node("GameState")
    var expected_inventory:Dictionary={}
    for item:String in payload.game_state.inventory:expected_inventory[item]=int(payload.game_state.inventory[item])
    assert(state.inventory==expected_inventory and state.coins==int(payload.game_state.coins))
    var household:Node3D=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i(7,-1)].get_node("CanalHousehold")
    var trader:Node=household.get_node("CanalTrader")
    assert(trader._shop_stock()==payload.game_state.world_state["shop:capital:canal:provisions"])
    assert(household.get_node("SquareHome").front_door.opened)
    print("CANAL_SAVED_HOME_OK real_native_save=true separate_process_bootstrap=true physical_floor=true door_stock_inventory_money_preserved=true driver_position_assignments=0")
    quit(0)
