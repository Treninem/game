extends SceneTree

var player: CharacterBody3D
var walked := 0.0
var deadline := 0
var center := Vector2(13500, -7000)

func _initialize() -> void:
    call_deferred("_run")

func _walk(offset: Vector2) -> bool:
    player.camera.rotation = Vector3.ZERO
    var target := center + offset
    while Vector2(player.global_position.x, player.global_position.z).distance_to(target) > 0.35:
        var direction := target - Vector2(player.global_position.x, player.global_position.z)
        player.rotation.y = atan2(-direction.x, -direction.y)
        var before := player.global_position
        Input.action_press("move_forward")
        await physics_frame
        walked += Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length()
        if Time.get_ticks_msec() > deadline:
            Input.action_release("move_forward")
            push_error("Native home review walk blocked at %s" % player.global_position)
            quit(1)
            return false
    Input.action_release("move_forward")
    for frame in range(12):
        await physics_frame
    await create_timer(.65).timeout
    return true

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

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://native-market-" + label + ".png")
    print("NATIVE_MARKET_CAPTURE ", label)

func _room_walk(home: Node3D, destination: Vector3) -> bool:
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

func _resolve_market() -> void:
    cell=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO]
    square=cell.get_node("CapitalSquareLife")

func _survey(point:Vector3,target:Vector3,label:String) -> void:
    var camera:=Camera3D.new();current_scene.add_child(camera)
    camera.global_position=cell.to_global(point);camera.look_at(cell.to_global(target));camera.fov=72;camera.make_current()
    await _capture(label)
    camera.free();player.camera.make_current()

func _feet(visual:Node3D,label:String) -> void:
    var boots:=visual.find_child("Boots",true,false) as MeshInstance3D
    var capture:RefCounted=load("res://tests/gpu_skinned_vertex_probe.gd").new()
    capture.setup(root,boots,0)
    await capture.calibrate()
    capture.begin_capture()
    await process_frame;await RenderingServer.frame_post_draw
    var points:PackedVector3Array=capture.finish_capture()
    assert(points.size()==3530,"Public rest lost complete GPU boot coverage")
    var low:=INF
    for point:Vector3 in points:low=minf(low,boots.to_global(point).y)
    var floor_y:float=root.get_node("WorldData").elevation_at(Vector2(visual.global_position.x,visual.global_position.z))+.025
    proof.foot_samples.append({"label":label,"boot_vertices":points.size(),"minimum_y":low,"paving_y":floor_y,"gap":low-floor_y})
    print("PUBLIC_REST_GPU_SAMPLE ",JSON.stringify(proof.foot_samples.back()))
    capture.dispose()
    assert(low-floor_y>=-.02 and low-floor_y<=.04,"Public rest soles penetrate or float above paving: "+label+" gap="+str(low-floor_y))

func _wait_seated() -> bool:
    var trader:CharacterBody3D=square.get_node("SquareTrader")
    var artisan:CharacterBody3D=square.get_node("SquareArtisan")
    var limit:=Time.get_ticks_msec()+100000
    while trader.get_meta("activity","")!="sit" or artisan.get_meta("activity","")!="sit":
        await physics_frame
        if Time.get_ticks_msec()>limit:
            push_error("Actual market residents could not find/reach their public seats");quit(1);return false
    if trader.used_furniture==artisan.used_furniture:
        push_error("Actual market residents share one reserved seat");quit(1);return false
    return true


func _street_feet(label:String) -> void:
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
    proof.street_foot_samples.append({"label":label,"vertices":points.size(),"gap_m":gap,"surface":String(hit.collider.name)})
    capture.dispose()

func _streetscape() -> bool:
    var street:=square.get_node("CapitalStreetscape") as Node3D
    var details:Dictionary=street.get_meta("measured_street_details")
    assert(details.paving_panels==28 and details.planters==6 and details.lantern_posts==4 and details.central_clear_width_m==14.0)
    assert(street.get_node("MeasuredWalkablePaving").get_child_count()==28)
    var post_mesh:Mesh=street.get_node("LanternPost").multimesh.mesh
    var iron_checked:=false
    for slot in range(post_mesh.get_surface_count()):
        var material:=post_mesh.surface_get_material(slot) as StandardMaterial3D
        if material.resource_name=="StreetIron":
            assert(material.albedo_color.r<.4 and material.albedo_color.g<.4 and material.albedo_color.b<.4 and material.roughness>=.7 and material.metallic>.5,"Export disconnected the actual dark forged iron material")
            iron_checked=true
    assert(iron_checked)
    # Measure real hollow planter wall and soil using independent physical rays.
    var trough:=street.get_node("PlantedStoneTrough_-1_24") as StaticBody3D
    var heights:Array=[]
    for x:float in [0,.72]:
        var point:=trough.to_global(Vector3(x,0,0))
        var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.5,point+Vector3.UP*.1,1)
        var hit:=player.get_world_3d().direct_space_state.intersect_ray(ray)
        assert(not hit.is_empty() and hit.collider==trough)
        heights.append(Vector3(hit.position).y-trough.global_position.y)
    assert(absf(heights[0]-.34)<.01 and absf(heights[1]-.59)<.01,"Planter hollow soil/rim collision differs from mesh")
    root.get_node("GameState").world_minutes=9*60
    for point:Vector2 in [Vector2(-8,-4),Vector2(0,4),Vector2(0,21),Vector2(16.8,21)]:
        if not await _walk(point):return false
    proof.street_foot_samples=[]
    await _street_feet("east-promenade-entry")
    await _survey(Vector3(6,2.2,16),Vector3(18,1.6,32),"street-promenade-day")
    for point:Vector2 in [Vector2(16.8,36),Vector2(14,36),Vector2(14,52),Vector2(16.8,52),Vector2(16.8,60)]:
        if not await _walk(point):return false
    await _street_feet("east-promenade-north")
    for point:Vector2 in [Vector2(0,60),Vector2(0,42),Vector2(-15,42),Vector2(-16.8,36)]:
        if not await _walk(point):return false
    await _street_feet("west-promenade")
    root.get_node("GameState").world_minutes=19*60
    await create_timer(1.5).timeout
    var lights:=0
    for node in square.get_children():
        if node is OmniLight3D and String(node.name).begins_with("StreetPostLight"):
            assert(node.visible and not node.shadow_enabled and node.omni_range<=5.5);lights+=1
    assert(lights==4)
    await _survey(Vector3(-5,2.1,35),Vector3(-17,1.6,55),"street-promenade-evening")
    root.get_node("SettingsManager").set_quality_preset(0)
    await create_timer(1.5).timeout
    for node in square.get_children():
        if node is OmniLight3D and String(node.name).begins_with("StreetPostLight"):assert(not node.visible,"Low preset keeps optional street lights")
    root.get_node("SettingsManager").set_quality_preset(1)
    proof.streetscape={"details":details,"planter_physical_heights_m":heights,"actual_walked_m":walked,"four_night_lights_bounded_and_low_disabled":true,"manual_play":false,"driver_position_assignments":0}
    return true

func _run() -> void:
    if not root.get_node("SaveManager").prepare_load(1):
        push_error("Public market native review requires actual earned arrival checkpoint");quit(1);return
    change_scene_to_file("res://scenes/world_loading.tscn")
    deadline=Time.get_ticks_msec()+420000
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or bool(player.get("ground_guard_active")):
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec()>deadline:push_error("Market native initial load timeout");quit(1);return
    current_scene.set_process(false)
    var state:=root.get_node("GameState")
    state.world_minutes=9*60
    root.get_node("SettingsManager").set_quality_preset(1)
    _resolve_market()
    for point:Vector2 in [Vector2(-8,-6),Vector2(-16,-18),Vector2(-28,-18),Vector2(-28,-4)]:
        if not await _walk(point):return
    await _survey(Vector3(-5,2.3,-1),Vector3(-22,3.1,-14),"arcade-walk-character")
    for point:Vector2 in [Vector2(-16,-4),Vector2(-16,-6.1)]:
        if not await _walk(point):return
    var trader:CharacterBody3D=square.get_node("SquareTrader")
    var stock_before:Dictionary=trader._shop_stock()
    var arrows_before:int=state.inventory.get("arrow",0)
    var coins_before:int=state.coins
    var price:int=trader.SHOP_PRICES.arrow
    if not await _interact(trader,trader.global_position+Vector3.UP*1.1):return
    var dialogue:=root.get_node("DialogueManager")
    assert(dialogue.is_open,"Market ray did not open the real merchant UI")
    var index:=-1
    for i in range(dialogue.options.size()):
        var option:Dictionary=dialogue.options[i]
        if option.get("action","")=="merchant_trade" and option.get("item","")=="arrow" and not bool(option.get("sell",false)):index=i;break
    assert(index>=0 and coins_before>=price and int(stock_before.arrow)>0)
    dialogue.choose(index,-1,dialogue.dialogue_revision)
    dialogue.close_dialogue()
    await create_timer(.8).timeout
    var stock:Dictionary=trader._shop_stock()
    assert(int(stock.arrow)==int(stock_before.arrow)-1 and int(state.inventory.get("arrow",0))==arrows_before+1)
    assert(state.coins==coins_before-price and int(stock.coins)==int(stock_before.coins)+price)
    var display:Node=square.get_node("SquareMarketStall/ActualArrowStock")
    assert(int(display.get_meta("displayed_arrows"))==mini(60,int(stock.arrow)),"Visible goods did not follow actual paid trade")
    proof["paid_trade_and_visible_stock"]=true
    await _survey(Vector3(-10,2.1,-5),Vector3(-17,1.5,-12),"covered-market-trade")
    for point:Vector2 in [Vector2(-8,-4),Vector2(-8,4)]:
        if not await _walk(point):return
    state.world_minutes=12*60
    if not await _wait_seated():return
    if not await _walk(Vector2(-8,10)):return
    var artisan:CharacterBody3D=square.get_node("SquareArtisan")
    await _survey(Vector3(-4,2.0,8),Vector3(-10,1.0,14),"residents-public-rest-character")
    await _feet(trader.visual,"trader-public-rest")
    await _feet(artisan.visual,"artisan-public-rest")
    var resident:CharacterBody3D=trader if trader.visual.global_position.distance_to(player.global_position)<artisan.visual.global_position.distance_to(player.global_position) else artisan
    if not await _interact(resident,resident.used_furniture.global_position+Vector3.UP*.95):return
    assert(dialogue.is_open and resident.visual.top_level,"Visible seated resident cannot be talked to")
    dialogue.close_dialogue()
    proof["talk_to_visible_seated_resident"]=true
    var occupied:StaticBody3D=trader.used_furniture if trader.used_furniture.global_position.distance_to(player.global_position)<artisan.used_furniture.global_position.distance_to(player.global_position) else artisan.used_furniture
    var owner:String=occupied.occupant
    if not await _interact(occupied,occupied.global_position+Vector3.UP*.25):return
    assert(occupied.occupant==owner and String(state.get_world_value("player:rest_furniture","")).is_empty(),"Hero stole an occupied public seat")
    proof["exclusive_seats"]=true
    for point:Vector2 in [Vector2(-8,-4),Vector2(-28.95,-4),Vector2(-28.95,-8)]:
        if not await _walk(point):return
    var bench:StaticBody3D=square.get_node("PublicFurniture/BenchPublic_-3000_-800")
    if not await _interact(bench,bench.global_position+Vector3.UP*.25):return
    for frame in range(12):await physics_frame
    var avatar:=player.get_node("Avatar") as Node3D
    assert(avatar.top_level and bench.occupant=="player" and player.is_on_floor())
    await _survey(Vector3(-25,2.2,-3),Vector3(-30,.9,-8),"hero-public-rest")
    await _feet(avatar,"hero-public-rest")
    assert(player.get_node("CameraPivot").global_position.distance_to(bench.global_position+Vector3.UP*(float(bench.get_meta("rest_support_y"))+.65*avatar.global_basis.get_scale().y))<.05,"Rest camera focuses on the empty approach instead of the seated hero")
    await _capture("hero-public-rest-player-camera")
    var bench_id:String=bench.furniture_id
    var saved_position:=player.global_position
    var saved_seats:Dictionary={trader.citizen_id:trader.used_furniture.furniture_id,artisan.citizen_id:artisan.used_furniture.furniture_id}
    assert(root.get_node("SaveManager").save_game(player,6))
    assert(root.get_node("SaveManager").prepare_load(6))
    change_scene_to_file("res://scenes/world_loading.tscn");player=null
    var reload_limit:=Time.get_ticks_msec()+180000
    await process_frame
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or bool(player.get("ground_guard_active")):
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec()>reload_limit:push_error("Market real disk reload timeout");quit(1);return
    current_scene.set_process(false);state.world_minutes=12*60;_resolve_market()
    for frame in range(16):await physics_frame
    avatar=player.get_node("Avatar")
    assert(avatar.top_level and player.is_on_floor() and player.global_position.distance_to(saved_position)<.4)
    assert(state.get_world_value("player:rest_furniture","")==bench_id)
    if not await _wait_seated():return
    for npc in [square.get_node("SquareTrader"),square.get_node("SquareArtisan")]:
        assert(npc.used_furniture.furniture_id==saved_seats[npc.citizen_id] and npc.visual.top_level)
    trader=square.get_node("SquareTrader");display=square.get_node("SquareMarketStall/ActualArrowStock")
    await create_timer(.8).timeout
    assert(int(trader._shop_stock().arrow)==int(stock.arrow) and int(display.get_meta("displayed_arrows"))==mini(60,int(stock.arrow)))
    proof["real_scene_disk_restore"]=true
    await _survey(Vector3(-25,2.2,-3),Vector3(-30,.9,-8),"public-rest-reloaded")
    var jump:=InputEventAction.new();jump.action="jump";jump.pressed=true
    Input.parse_input_event(jump);Input.flush_buffered_events()
    assert(not avatar.top_level,"Jump did not immediately leave the public seat")
    var peak:=player.global_position.y
    for frame in range(70):
        await physics_frame
        peak=maxf(peak,player.global_position.y)
        if frame==0:Input.action_release("jump")
    assert(peak>saved_position.y+.25 and player.is_on_floor() and String(state.get_world_value("player:rest_furniture","")).is_empty())
    assert(not player.has_meta("rest_collision_snapshot") and not player.has_meta("rest_camera_pivot"),"Wake failed to restore the standing collision/camera")
    proof["jump_wake_and_land"]=true
    state.world_minutes=9*60
    var work_limit:=Time.get_ticks_msec()+100000
    while true:
        var all_working:=true
        for npc in [square.get_node("SquareTrader"),square.get_node("SquareArtisan")]:
            var target:Vector3=square.to_global(npc.get_meta("routine_places").work)
            all_working=all_working and Vector2(target.x-npc.global_position.x,target.z-npc.global_position.z).length()<.35
        if all_working:break
        await physics_frame
        if Time.get_ticks_msec()>work_limit:push_error("Actual residents could not return from public rest to work");quit(1);return
    proof["residents_return_to_work"]=true
    state.world_minutes=18.5*60
    if not await _wait_seated():return
    await _survey(Vector3(-4,2.3,-2),Vector3(-22,2.1,-14.5),"arcade-evening")
    if not await _streetscape():return
    proof["walked_m"]=walked
    var file:=FileAccess.open("user://public-market-proof.json",FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(proof,"  "));file.close()
    print("CITY_STREETSCAPE_NATIVE_OK ordinary_walk_m=",walked," player_position_assignments=0 arcade=true paid_trade=true finite_visible_stock=true npc_seats=true player_rest=true actual_scene_reload=true jump_wake=true npc_return_work=true gpu_boot_coverage=3530_per_actor manual_play=false")
    quit(0)
