extends "res://scripts/capital_square_life.gd"

const CANAL_SHOP:="capital:canal:provisions"

func _ready() -> void:
    var home:=preload("res://scripts/enterable_building.gd").new()
    home.name="SquareHome";home.configure(Vector3(12,3.2,10),2,"Дом торговки Веры и мастера Никиты")
    home.position=Vector3(-45,_ground_y(Vector3(-45,0,-30))+.03-home.floor_thickness,-30)
    home.add_to_group("map_building");home.set_meta("map_footprint",Vector2(12,10))
    home.set_meta("household_owners",[CANAL_SHOP,"capital:canal:fletcher"])
    add_child(home);preload("res://scripts/cottage_exterior.gd").build(home)
    home.front_door.persistence_key="door:capital:canal:home"
    home.front_door.set_open(bool(GameState.get_world_value(home.front_door.persistence_key,false)),true)
    var stall:=_place(STALL,"CanalProvisionsStall",Vector3(55,0,-24),2.65,0,true)
    # Counter collision uses the authored mesh, not a box sealing the merchant.
    var old_collision:=stall.get_node_or_null("CollisionShape3D")
    if old_collision!=null:old_collision.free()
    MARKET_STRUCTURE.physical_mesh(stall,stall.get_child(0),"canal_stall_2.65",true)
    _prop("Barrel_Apples",Vector3(58,0,-25),.75)
    _prop("Barrel",Vector3(60,0,-25),.9)
    var workbench:=_prop("Workbench",Vector3(65,0,-25),.95)
    var depth:Vector2=workbench.get_meta("map_footprint")
    var workplace:=Vector3(65,0,-25+depth.y*.5+.42)
    var trader:=_resident("Вера","trader","CanalTrader",CANAL_SHOP,Vector3(55,0,-20.5),Vector3(55,0,-24),1)
    var display:=preload("res://scripts/market_goods_display.gd").new();display.name="ActualArrowStock";display.build(stall,trader)
    var artisan:=_resident("Никита","craftsman","CanalFletcher","capital:canal:fletcher",workplace,Vector3(65,0,-25),0)
    artisan.set_meta("work_shop_id",CANAL_SHOP);artisan.set_meta("work_recipe","arrow");working_artisan=artisan
    # Destinations are authored workplaces and a shared real home. Neither
    # resident gets a patrol or a list of bridge waypoints; the planner chooses.
    _prepare_workpieces(workbench)
    _prop("Bench",Vector3(-26,0,-5),.47,-PI*.5)
    _prop("Bench",Vector3(26,0,-24),.47,PI*.5)
    _prop("Bench",Vector3(26,0,-20),.47,PI*.5)
    var navigation:=preload("res://scripts/public_space_navigation.gd").new()
    navigation.name="PublicSpaceNavigation";navigation.lower_bound=Vector2(-72,-55);navigation.upper_bound=Vector2(80,55)
    navigation.set_meta("commute_navigation",true)
    add_child(navigation)
    set_meta("functional_canal_household",true)

func _process(delta:float) -> void:
    light_elapsed+=delta
    if light_elapsed<1:return
    light_elapsed=0
    if not is_instance_valid(workpieces) or not is_instance_valid(working_artisan):return
    var stock:Dictionary=GameState.get_world_value("shop:"+CANAL_SHOP,{})
    var supplied:=true
    for item:String in InventorySystem.RECIPES.arrow.requirements:
        supplied=supplied and int(stock.get(item,0))>=int(InventorySystem.RECIPES.arrow.requirements[item])
    workpieces.visible=supplied and working_artisan.get_meta("activity","idle")=="work"

func _ground_y(point:Vector3)->float:
    var world:=to_global(point)
    return WorldData.elevation_at(Vector2(world.x,world.z))+.006-global_position.y

func _resident(label:String,role:String,node_name:String,id:String,workplace:Vector3,facing:Vector3,palette:int)->CharacterBody3D:
    var resident:=NPC.new();resident.name=node_name;resident.autonomous=true
    resident.body_sex="female" if role=="trader" else "male"
    resident.set_meta("citizen_id",id)
    resident.set_meta("routine_places",{"work":workplace,"home":Vector3(-45+(-1.4 if role=="trader" else 1.4),0,-29),"meal":Vector3(-24.95,0,-5) if role=="trader" else Vector3(24.95,0,-24),"social":Vector3(24.95,0,-22)})
    resident.set_meta("home_building","SquareHome");resident.set_meta("work_facing",facing)
    resident.configure(label,role,palette,[]);resident.position=Vector3(workplace.x,_ground_y(workplace)+.08,workplace.z)
    add_child(resident);return resident
