extends SceneTree
const DATA:=preload("res://scripts/capital_canal_data.gd")
var life:Node3D
var residents:Array[CharacterBody3D]=[]
var player:CharacterBody3D
var previous:Dictionary={}
var distances:Dictionary={}
var wet_samples:=0
var arrivals:Dictionary={}
var expected_phase:="work"
var guard_material_transit:=false
var transit_arrow_count:=0

func _initialize()->void:call_deferred("_run")
func _world_ready()->bool:
    if current_scene==null or current_scene.name!="Bootstrap":return false
    player=get_first_node_in_group("player") as CharacterBody3D
    return player!=null and bool(current_scene.startup_state_ready) and not player.ground_guard_active
func _load(slot:int)->void:
    Engine.time_scale=1;Engine.physics_ticks_per_second=60
    if slot==5:assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self))
    else:assert(root.get_node("SaveManager").prepare_load(slot))
    change_scene_to_file("res://scenes/world_loading.tscn")
    var deadline:=Time.get_ticks_msec()+120000
    while not _world_ready():
        await physics_frame
        if Time.get_ticks_msec()>deadline:push_error("Canal household real load timeout");quit(1);return
    life=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i(7,-1)].get_node("CanalHousehold")
    residents.assign([life.get_node("CanalTrader"),life.get_node("CanalFletcher")]);previous.clear()
    # Four times simulation with the same 1/60 physical step, not faster walking.
    Engine.physics_ticks_per_second=240;Engine.time_scale=4
    assert(absf(Engine.time_scale/Engine.physics_ticks_per_second-1./60)<.00001)
func _trace()->void:
    for actor:CharacterBody3D in residents:
        var id:String=actor.citizen_id
        if previous.has(id):distances[id]=float(distances.get(id,0))+Vector2(actor.global_position.x-Vector3(previous[id]).x,actor.global_position.z-Vector3(previous[id]).z).length()
        previous[id]=actor.global_position
        var point:=Vector2(actor.global_position.x,actor.global_position.z)
        if DATA.wet_at(point):
            var bridge:=DATA.bridge_at(point)
            assert(not is_inf(bridge.x),"Resident walked into the canal instead of choosing a bridge")
            assert(absf(actor.global_position.y-DATA.deck_height(point.x-bridge.x))<.15,"Resident walked below/above the actual bridge")
            wet_samples+=1
    if guard_material_transit:
        var artisan:CharacterBody3D=residents[1]
        var destination:Vector3=life.to_global(artisan.get_meta("routine_places").work)
        if Vector2(artisan.global_position.x-destination.x,artisan.global_position.z-destination.z).length()>.10:
            var stock:Dictionary=residents[0]._shop_stock()
            assert(int(stock.arrow)==transit_arrow_count and int(stock.wood)==1 and int(stock.stone)==1,"Workshop consumed materials before physically arriving at work")
func _done(mode:String)->bool:
    for actor:CharacterBody3D in residents:
        if actor.routine_phase!=expected_phase:return false
        if mode=="work":
            var target:Vector3=life.to_global(actor.get_meta("routine_places").work)
            var radius:float=.75 if actor.role=="trader" else .10
            if Vector2(actor.global_position.x-target.x,actor.global_position.z-target.z).length()>radius or not actor.is_on_floor():return false
        elif mode=="sleep":
            if not is_instance_valid(actor.used_furniture) or actor.used_furniture.kind!="bed" or actor.get_meta("activity","")!="sleep":return false
        elif mode=="public":
            if not is_instance_valid(actor.used_furniture) or not actor.used_furniture.is_in_group("public_rest_furniture") or actor.get_meta("activity","")!="sit":return false
    return true
func _wait(mode:String,seconds:float=110)->bool:
    var deadline:=Time.get_ticks_msec()+int(seconds*1000)
    var next_trace:=Time.get_ticks_msec()+15000
    while not _done(mode):
        await physics_frame;_trace()
        if Time.get_ticks_msec()>next_trace:
            next_trace=Time.get_ticks_msec()+15000
            for actor:CharacterBody3D in residents:print("CANAL_RESIDENT_PROGRESS ",mode," ",actor.name," local=",actor.position," activity=",actor.activity," phase=",actor.routine_phase," clock=",root.get_node("GameState").world_minutes)
        if Time.get_ticks_msec()>deadline:
            for actor:CharacterBody3D in residents:print("CANAL_RESIDENT_BLOCKED ",actor.name," local=",actor.position," activity=",actor.activity," phase=",actor.routine_phase)
            push_error("Canal household could not complete "+mode);quit(1);return false
    arrivals[mode]=root.get_node("GameState").world_minutes
    arrivals[expected_phase+"_arrival"]=arrivals[mode]
    print("CANAL_RESIDENT_PHASE ",mode," clock=",arrivals[mode]);return true
func _run()->void:
    await _load(5)
    var state:=root.get_node("GameState");var saves:=root.get_node("SaveManager")
    assert(absf(root.get_node("SettingsManager").world_minutes_per_second()-.5)<.00001)
    state.world_minutes=9*60
    assert(life.get_node("SquareHome").room_count>=3)
    for actor:CharacterBody3D in residents:
        assert(actor.route_points_local.is_empty() and not actor.has_meta("work_approach_path"),"Canal citizens were assigned a walking route")
        assert(absf(actor.move_speed-1.45)<.0001)
    if not await _wait("work"):return
    # Controlled recipe-supply fixture. No claim that these materials were
    # earned in a graphical journey: verify exact finite consumption/output.
    var trader:CharacterBody3D=residents[0];var artisan:CharacterBody3D=residents[1]
    var stock:Dictionary=trader._shop_stock().duplicate(true);var arrows:int=stock.arrow
    stock.wood=1;stock.stone=1;state.set_world_value("shop:"+trader.citizen_id,stock)
    for frame in range(660):await physics_frame;_trace()
    stock=trader._shop_stock();assert(stock.wood==0 and stock.stone==0 and int(stock.arrow)==arrows+5)
    for frame in range(600):await physics_frame;_trace()
    assert(int(trader._shop_stock().arrow)==arrows+5,"Workshop made free arrows after supplies were exhausted")
    expected_phase="home";state.world_minutes=21*60
    if not await _wait("sleep"):return
    assert(float(arrivals.sleep)>21*60,"The commute used a frozen world clock")
    assert(residents[0].used_furniture!=residents[1].used_furniture)
    var chest:Node=life.get_node("SquareHome/InteriorFurniture/StorageChest")
    assert(int(chest.contents().get("berries",0))==2)
    var inventory:Dictionary=state.inventory.duplicate(true);var coins:int=state.coins
    assert(not trader.complete_trade("arrow",false),"The home-resident shop stayed open at night")
    assert(state.inventory==inventory and state.coins==coins)
    assert(saves.save_game(player,7));await _load(7)
    if not await _wait("sleep",40):return
    assert(state.inventory==inventory and state.coins==coins)
    chest=life.get_node("SquareHome/InteriorFurniture/StorageChest")
    assert(int(chest.contents().get("berries",0))==2,"Household duplicated items on reload")
    trader=residents[0];artisan=residents[1]
    stock=trader._shop_stock().duplicate(true);transit_arrow_count=int(stock.arrow)
    stock.wood=1;stock.stone=1;state.set_world_value("shop:"+trader.citizen_id,stock)
    assert(not artisan._workbench_step(9) and trader._shop_stock()==stock,"Crafting can run while the artisan is at home")
    guard_material_transit=true
    expected_phase="work";state.world_minutes=6*60
    if not await _wait("work"):return
    guard_material_transit=false
    assert(float(arrivals.work)>6*60 and float(arrivals.work)<12*60,"Ordinary commute consumed the working day")
    expected_phase="meal";state.world_minutes=12*60
    if not await _wait("public"):return
    assert(residents[0].used_furniture!=residents[1].used_furniture)
    assert(float(arrivals.public)>12*60 and float(arrivals.public)<14*60)
    expected_phase="social";state.world_minutes=18*60
    if not await _wait("public"):return
    assert(residents[0].used_furniture!=residents[1].used_furniture)
    assert(wet_samples>100 and float(distances.get("capital:canal:provisions",0))>250)
    var report:={"ordinary_npc_move_speed":1.45,"physics_step_s":1./60,"simulation_time_scale":4,"phase_entry_clock_controlled":true,"clock_advances_during_commutes":true,"arrivals":arrivals,"walked_by_citizen_m":distances,"physical_bridge_samples":wet_samples,"npc_position_assignments_by_driver":0,"recipe_supply_is_controlled_fixture":true,"finite_recipe_consumption":true,"shop_closed_at_night":true,"real_scene_disk_restore":true,"personal_storage_did_not_duplicate":true,"exclusive_beds_and_public_seats":true,"full_life_simulation_acceptance":false}
    report["no_crafting_at_home_or_in_transit"]=true
    var file:=FileAccess.open("user://canal-household-proof.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("CANAL_HOUSEHOLD_OK ",JSON.stringify(report));quit(0)
