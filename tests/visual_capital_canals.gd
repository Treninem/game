extends SceneTree

const DATA:=preload("res://scripts/capital_canal_data.gd")
var player:CharacterBody3D
var walked:=0.
var floor_samples:Array=[]
var foot_samples:Array=[]

func _initialize()->void:call_deferred("_run")

func _ready_world()->bool:
    if current_scene==null or current_scene.name!="Bootstrap":return false
    player=get_first_node_in_group("player") as CharacterBody3D
    return player!=null and bool(current_scene.startup_state_ready) and not player.ground_guard_active

func _walk(offset:Vector2)->bool:
    print("CANAL_WALK_TO ",offset)
    var target:=preload("res://scripts/capital_data.gd").CENTER+offset
    var deadline:=Time.get_ticks_msec()+70000
    while Vector2(player.global_position.x,player.global_position.z).distance_to(target)>.30:
        var direction:=target-Vector2(player.global_position.x,player.global_position.z)
        player.rotation.y=atan2(-direction.x,-direction.y);player.camera.rotation=Vector3.ZERO
        var previous:=player.global_position;Input.action_press("move_forward");await physics_frame
        walked+=Vector2(player.global_position.x-previous.x,player.global_position.z-previous.z).length()
        if Time.get_ticks_msec()>deadline:push_error("Canal ordinary walk blocked: "+str(player.global_position));quit(1);return false
    Input.action_release("move_forward")
    for frame in range(18):await physics_frame
    await create_timer(.65).timeout
    assert(player.is_on_floor(),"Canal traversal lost physical support")
    floor_samples.append({"xz":str(offset),"y":player.global_position.y})
    await _feet(str(offset))
    print("CANAL_WALK_REACHED ",offset," walked_m=",walked)
    return true

func _capture(offset:Vector3,look:Vector3,label:String)->void:
    var camera:=Camera3D.new();current_scene.add_child(camera)
    var center:Vector2=preload("res://scripts/capital_data.gd").CENTER
    camera.global_position=Vector3(center.x,0,center.y)+offset;camera.look_at(Vector3(center.x,0,center.y)+look);camera.fov=66;camera.make_current()
    for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png("user://canal-"+label+".png")==OK)
    print("CAPITAL_CANAL_CAPTURE ",label)
    player.camera.make_current();camera.queue_free()

func _interact(target: Node3D, point: Vector3) -> bool:
    # Face the actor as a real mouse turn does, then let the camera probe settle
    # on the same side. Rotating only the camera behind an open door can create
    # an impossible backwards aim which the reach/front guard rightly rejects.
    var toward := point - player.global_position
    player.rotation.y = atan2(-toward.x, -toward.z)
    player.camera.rotation = Vector3.ZERO
    for frame in range(4):
        await physics_frame
    player.camera.look_at(point, Vector3.UP)
    player.interaction_ray.force_raycast_update()
    if player.interaction_ray.get_collider() != target:
        push_error("Native interaction ray did not select %s; hit %s" % [target.name, player.interaction_ray.get_collider()])
        quit(1)
        return false
    player.call("_try_interact")
    await physics_frame
    return true

func _feet(label:String) -> void:
    var visual:=player.get_node("Avatar") as Node3D
    var boots:=visual.find_child("Boots",true,false) as MeshInstance3D
    var capture:RefCounted=load("res://tests/gpu_skinned_vertex_probe.gd").new()
    capture.setup(root,boots,0);await capture.calibrate();capture.begin_capture()
    await process_frame;await RenderingServer.frame_post_draw
    var points:PackedVector3Array=capture.finish_capture();assert(points.size()==3530)
    var lowest:=Vector3(0,INF,0)
    for point:Vector3 in points:
        var world:=boots.to_global(point)
        if world.y<lowest.y:lowest=world
    var query:=PhysicsRayQueryParameters3D.create(lowest+Vector3.UP*.5,lowest-Vector3.UP*.5,1,[player.get_rid()])
    var hit:=player.get_world_3d().direct_space_state.intersect_ray(query)
    assert(not hit.is_empty() and player.is_on_floor(),"Street traversal lost actual physical support")
    var gap:=lowest.y-Vector3(hit.position).y
    assert(gap>=-.02 and gap<=.04,"Rendered street sole penetrates/floats: "+label+" gap="+str(gap))
    foot_samples.append({"label":label,"vertices":points.size(),"gap_m":gap,"surface":String(hit.collider.name)})
    capture.dispose()

func _room_walk(home: Node3D, destination: Vector3) -> bool:
    var deadline:=Time.get_ticks_msec()+45000
    while Vector2(home.to_local(player.global_position).x - destination.x, home.to_local(player.global_position).z - destination.z).length() > 0.24:
        var point: Vector3 = home.get_node("HouseRooms").waypoint(home.to_local(player.global_position), destination, player)
        var toward := home.to_global(point) - player.global_position
        player.rotation.y = atan2(-toward.x, -toward.z)
        var before := player.global_position
        Input.action_press("move_forward")
        await physics_frame
        walked += before.distance_to(player.global_position)
        if Time.get_ticks_msec() > deadline:
            Input.action_release("move_forward")
            push_error("Actual capital home room walk blocked: " + str(home.to_local(player.global_position)))
            quit(1)
            return false
    Input.action_release("move_forward")
    for frame in range(10):await physics_frame
    await create_timer(.65).timeout
    if not player.is_on_floor():
        push_error("Capital concept room walk lost physical support")
        quit(1)
        return false
    return true

var square:Node3D
var cell:Node3D
var proof:={"player_position_assignments":0,"manual_play":false,"foot_samples":[]}

func _run()->void:
    assert(DisplayServer.get_name()!="headless")
    create_timer(700).timeout.connect(func():push_error("CAPITAL_CANAL_NATIVE timeout");quit(1))
    assert(root.get_node("SaveManager").prepare_load(5))
    change_scene_to_file("res://scenes/world_loading.tscn")
    var deadline:=Time.get_ticks_msec()+160000
    while not _ready_world():
        await physics_frame
        if Time.get_ticks_msec()>deadline:push_error("Native canal old-save load timeout");quit(1);return
    current_scene.set_process(false)
    root.get_node("GameState").world_minutes=9*60
    root.get_node("SettingsManager").set_quality_preset(1)
    await _capture(Vector3(1187,5,-153),Vector3(1180,3.1,-160),"bridge-hero-before-walk")
    for point:Vector2 in [Vector2(1125,-160),Vector2(1125,-80),Vector2(1130,0),Vector2(1235,0),Vector2(1240,-80),Vector2(1240,-160),Vector2(1180,-160)]:
        if not await _walk(point):return
        if point==Vector2(1125,-80):await _capture(Vector3(1145,4,-102),Vector3(1190,1,-165),"bank-to-bridge-day")
        if point==Vector2(1235,0):await _capture(Vector3(1220,6,24),Vector3(1175,1,-30),"second-bridge-bank")
    await _capture(Vector3(1156,3.6,-132),Vector3(1200,1,-170),"masonry-water-context")
    # Ordinary walk to the actual merchant and front door; no actor relocation.
    var state:=root.get_node("GameState")
    var household:Node3D=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i(7,-1)].get_node("CanalHousehold")
    for point:Vector2 in [Vector2(1240,-160),Vector2(1240,-177.5),Vector2(1232.8,-177.5),Vector2(1232.8,-180.5)]:
        if not await _walk(point):return
    var trader:CharacterBody3D=household.get_node("CanalTrader")
    var stock_before:Dictionary=trader._shop_stock().duplicate(true)
    var arrows_before:int=state.inventory.get("arrow",0);var coins_before:int=state.coins
    var price:int=trader.SHOP_PRICES.arrow
    if not await _interact(trader,trader.global_position+Vector3.UP*1.1):return
    var dialogue:=root.get_node("DialogueManager");assert(dialogue.is_open)
    var option_index:=-1
    for index in range(dialogue.options.size()):
        var option:Dictionary=dialogue.options[index]
        if option.get("action","")=="merchant_trade" and option.get("item","")=="arrow" and not bool(option.get("sell",false)):option_index=index;break
    assert(option_index>=0 and coins_before>=price and int(stock_before.arrow)>0)
    dialogue.choose(option_index,-1,dialogue.dialogue_revision);dialogue.close_dialogue()
    await create_timer(.8).timeout
    var stock:Dictionary=trader._shop_stock()
    assert(int(stock.arrow)==int(stock_before.arrow)-1 and int(state.inventory.get("arrow",0))==arrows_before+1)
    assert(state.coins==coins_before-price and int(stock.coins)==int(stock_before.coins)+price)
    assert(int(household.get_node("CanalProvisionsStall/ActualArrowStock").get_meta("displayed_arrows"))==mini(60,int(stock.arrow)))
    await _capture(Vector3(1229,2.6,-175),Vector3(1235,1.2,-183),"paid-merchant-character")
    for point:Vector2 in [Vector2(1232.8,-177.5),Vector2(1240,-177.5),Vector2(1240,-160),Vector2(1125,-160),Vector2(1125,-178),Vector2(1135,-183)]:
        if not await _walk(point):return
    var home:Node3D=household.get_node("SquareHome");var door:Node3D=home.front_door
    if not bool(door.get("opened")):
        if not await _interact(door,door.to_global(Vector3(.725,1.2,0))):return
        await create_timer(1).timeout
    assert(door.get("opened") and home.room_count>=3)
    if not await _walk(Vector2(1135,-189)):return
    if not await _room_walk(home,Vector3(-3.1,0,-3.27)):return
    await _capture(home.position+Vector3(1180,-.0,-160)+Vector3(-1.9,2.1,-2.2),home.position+Vector3(1180,.8,-160)+Vector3(-3.1,0,-3.27),"home-bedroom-character")
    if not await _room_walk(home,Vector3(3,0,3.1)):return
    await _capture(home.position+Vector3(1180,2.1,-160)+Vector3(2,0,2.8),home.position+Vector3(1180,1.35,-160)+Vector3(4,0,4),"home-kitchen-character")
    if not await _room_walk(home,Vector3(1.8,0,-.8)):return
    await _feet("home-dining")
    assert(root.get_node("SaveManager").save_game(player,8))
    if not await _room_walk(home,Vector3(0,0,3.2)):return
    for point:Vector2 in [Vector2(1135,-183),Vector2(1125,-178),Vector2(1125,-160),Vector2(1180,-160)]:
        if not await _walk(point):return

    root.get_node("GameState").world_minutes=19*60
    await create_timer(1.5).timeout
    await _capture(Vector3(1156,3.6,-132),Vector3(1200,1,-170),"evening-context")
    var report:={"walked_m":walked,"driver_position_assignments":0,"manual_play":false,"source_checkpoint":"Previously earned1.34km actual city road survey; old geometry revision is migrated vertically by SaveManager","floor_samples":floor_samples,"gpu_sole_samples":foot_samples,"paid_trade_and_finite_stock":true,"real_front_door_and_rooms":true,"new_household_saved_slot":8,"clock_frozen_fixture":true,"live_private_world":true,"published":false,"full_art_acceptance":false}
    var file:=FileAccess.open("user://canal-native-proof.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("CAPITAL_CANAL_NATIVE_OK ",JSON.stringify(report));quit(0)
