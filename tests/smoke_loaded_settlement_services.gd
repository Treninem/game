extends SceneTree
const SERVICES:=["SettlementInteriorVisuals","SettlementCivicSpaces","SettlementPublicWorks"]
func _initialize()->void:call_deferred("_run")
func _home(parent:Node,point:Vector3,label:String)->Node3D:
    var home:Node3D=load("res://scripts/enterable_building.gd").new()
    home.name=label;home.configure(Vector3(12,3.2,10));home.position=point
    home.set_meta("household_owners",["fixture:adult:one","fixture:adult:two"])
    parent.add_child(home);return home
func _details_ready(home:Node3D)->bool:
    return bool(home.get_meta("real_furniture_visuals",false)) and home.has_node("InteriorFurniture/Bed/RealBedModel") and home.has_node("InteriorFurniture/Table/RealTableModel") and home.has_node("HouseholdDetails")
func _run()->void:
    assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self))
    assert(root.get_node("SaveManager").prepare_load(5));change_scene_to_file("res://scenes/world_loading.tscn")
    var deadline:=Time.get_ticks_msec()+120000;var player:CharacterBody3D
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or not bool(current_scene.get("startup_state_ready")) or player.ground_guard_active:
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec()>deadline:push_error("Loaded settlement service fixture timeout");quit(1);return
    var state:=root.get_node("GameState");var inventory:Dictionary=state.inventory.duplicate(true);var coins:int=state.coins
    var world:=current_scene.get_node("World");var listeners:Dictionary={}
    for name:String in SERVICES:
        var service:=world.get_node(name)
        listeners[name]=node_added.is_connected(Callable(service,"_on_node_added"))
    var point:=Vector2(player.global_position.x-70,player.global_position.z+100)
    var ground:float=root.get_node("WorldData").elevation_at(point)
    # Explicit newly streamed component fixture after the real loading scene
    # transfer. No avatar relocation, money/items or new visual assets.
    var home:=_home(world,Vector3(point.x,ground,point.y),"LoadedFamilyFixture")
    for frame in range(180):
        await physics_frame
        if _details_ready(home):break
    print("LOADED_SERVICE_STATE listeners=",listeners," real_home_details=",_details_ready(home))
    assert(_details_ready(home),"Home created after real load stays on proxy furniture and has no household dressing")
    assert(listeners.values().all(func(value:Variant)->bool:return bool(value)),"A loaded settlement service lost its scene subscription")
    var count:=home.find_children("*","MeshInstance3D",true,false).size()
    var loaded_world:Node=current_scene
    var holder:=Node3D.new();root.add_child(holder);loaded_world.reparent(holder);loaded_world.reparent(root);current_scene=loaded_world
    for frame in range(8):await process_frame
    assert(home.find_children("*","MeshInstance3D",true,false).size()==count,"World reentry duplicates household models/details")
    for name:String in SERVICES:
        assert(node_added.is_connected(Callable(world.get_node(name),"_on_node_added")),"Repeated world entry loses settlement dressing")
    var second:=_home(world,Vector3(point.x+18,ground,point.y),"ReenteredFamilyFixture")
    for frame in range(180):
        await physics_frame
        if _details_ready(second):break
    assert(_details_ready(second),"New home after repeated reentry stays empty")
    # Materialize the existing canonical town after loading. Its own placement
    # is an explicit fixture; the avatar remains at the earned canal checkpoint.
    var settlements:=world.get_node("Settlements");settlements.set_process(false)
    var town:Node3D=settlements.materialize_settlement_for_test("first_fortified_town")
    assert(town!=null)
    for frame in range(240):
        await process_frame
        if bool(town.get_meta("public_works_ready",false)) and bool(town.get_meta("civic_space_ready",false)):break
    assert(bool(town.get_meta("public_works_ready",false)) and town.has_node("PublicWorks/MarketDistrict"),"Town streamed after load has no actual market infrastructure")
    assert(bool(town.get_meta("civic_space_ready",false)),"Town streamed after load has no civic interior")
    var hall:Node3D=town.get_node("Enterable_14")
    assert(hall.has_node("CouncilChamber") and not hall.has_node("InteriorFurniture"))
    assert(not hall.has_node("HouseholdDetails"),"Council hall inherited a dwelling kitchen rugs and pantry")
    var town_meshes:=town.find_children("*","MeshInstance3D",true,false).size()
    loaded_world.reparent(holder);loaded_world.reparent(root);current_scene=loaded_world
    for frame in range(8):await process_frame
    assert(town.find_children("*","MeshInstance3D",true,false).size()==town_meshes,"World reentry duplicates market/civic infrastructure")
    assert(state.inventory==inventory and state.coins==coins)
    var report:={"actual_load_transfer":true,"new_homes_after_load_and_reentry_decorated":true,"mesh_instances_first_home":count,"household_models_not_duplicated":true,"three_live_service_subscriptions":true,"inventory_money_unchanged":true,"avatar_position_assignments":0,"controlled_component_fixture":true,"manual_play":false,"full_visual_acceptance":false}
    report["actual_post_load_town_market_and_council"]=true;report["civic_room_excludes_dwelling_dressing"]=true;report["town_meshes_not_duplicated"]=town_meshes
    var file:=FileAccess.open("user://loaded-settlement-services.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("LOADED_SETTLEMENT_SERVICES_OK ",JSON.stringify(report));quit(0)
