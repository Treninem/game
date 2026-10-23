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
    root.get_texture().get_image().save_png("user://native-home-" + label + ".png")
    print("NATIVE_HOME_CAPTURE ", label)

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

func _run() -> void:
    if not root.get_node("SaveManager").call("prepare_load", 1):
        push_error("Capital concept review requires actual earned arrival checkpoint")
        quit(1)
        return
    change_scene_to_file("res://scenes/world_loading.tscn")
    deadline = Time.get_ticks_msec() + 300000
    while current_scene == null or current_scene.name != "Bootstrap" or player == null or bool(player.get("ground_guard_active")):
        await physics_frame
        player = get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec() > deadline:quit(1);return
    current_scene.set_process(false)
    root.get_node("GameState").set("world_minutes", 9.0 * 60)
    root.get_node("SettingsManager").call("set_quality_preset", 1)
    root.get_node("SettingsManager").call("set_camera_distance", 3.8)
    print("CONCEPT_NATIVE_START earned_checkpoint=true player_position_assignments=0 ", player.global_position)
    var city_cell:Node3D=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO]
    if int(city_cell.get_meta("concept_edge_houses",0))!=22 or int(city_cell.get_meta("concept_market_canopies",0))!=6:
        push_error("Capital concept composition was not built")
        quit(1)
        return
    var details:Dictionary=city_cell.get_meta("concept_facade_details",{})
    if int(details.get("authored_houses",0))!=22 or int(details.get("window_boxes",0))<20 or int(details.get("flowers",0))<60:
        push_error("Capital concept lost its batched authored facade details")
        quit(1)
        return
    var square:Node3D=city_cell.get_node("CapitalSquareLife")
    var court:Dictionary=square.get_meta("market_court",{})
    if int(court.get("trees",0))!=4 or int(court.get("goods",0))!=12:
        push_error("Market court details missing");quit(1);return
    var fountain:StaticBody3D=square.get_node("MarketFountain")
    if fountain.basins.size()!=2 or fountain.get_node_or_null("StoneBasinCollision")==null:
        push_error("Fountain lost stone support or separate water basins");quit(1);return
    var exclusions:Array[RID]=[player.get_rid()]
    for npc in get_nodes_in_group("settlement_npc"):
        if npc is CollisionObject3D:exclusions.append(npc.get_rid())
    for ends:Array in [[Vector2(-75,0),Vector2(75,0)],[Vector2(0,-40),Vector2(0,75)]]:
        var a:Vector2=center+ends[0];var b:Vector2=center+ends[1]
        var query:=PhysicsRayQueryParameters3D.create(Vector3(a.x,1.2,a.y),Vector3(b.x,1.2,b.y),1,exclusions)
        if not city_cell.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
            push_error("Capital concept obstructed a cardinal street")
            quit(1)
            return
    await create_timer(1.25).timeout
    var survey:=Camera3D.new();current_scene.add_child(survey)
    survey.global_position=city_cell.to_global(Vector3(-5,2.1,-7));survey.look_at(city_cell.to_global(Vector3(0,4,40)));survey.fov=72;survey.make_current()
    await _capture("capital-market-character")
    survey.free();player.camera.make_current()
    if not await _walk(Vector2(8.5,4)):return
    if not await _walk(Vector2(8.5,12)):return
    survey=Camera3D.new();current_scene.add_child(survey)
    survey.global_position=city_cell.to_global(Vector3(8.5,1.7,8));survey.look_at(city_cell.to_global(Vector3(20,5,52)));survey.fov=72;survey.make_current()
    await _capture("capital-residential-street")
    survey.global_position=city_cell.to_global(Vector3(35,30,45));survey.look_at(city_cell.to_global(Vector3(0,2,-12)));survey.fov=74
    await _capture("capital-square-overview")
    survey.free();player.camera.make_current()
    if not await _walk(Vector2(8.5,4)):return
    if not await _walk(Vector2(-8,4)):return
    if not await _walk(Vector2(-8,25.4)):return
    if not await _walk(Vector2(-16,25.4)):return
    var state:Node=root.get_node("GameState")
    var inventory_before:Dictionary=state.inventory.duplicate(true)
    var coins_before:int=state.coins
    var uses_before:int=state.get_world_value("fountain:capital:market:uses",0)
    state.thirst=60.0
    if not await _interact(fountain,fountain.to_global(Vector3(0,.8,-2.55))):return
    if state.thirst<94.5 or state.thirst>95.1 or state.inventory!=inventory_before or state.coins!=coins_before or int(state.get_world_value("fountain:capital:market:uses",0))!=uses_before+1:
        push_error("Reach-checked fountain changed inventory/money or failed to quench thirst");quit(1);return
    state.thirst=100.0
    if not await _interact(fountain,fountain.to_global(Vector3(0,.8,-2.55))):return
    if int(state.get_world_value("fountain:capital:market:uses",0))!=uses_before+1:
        push_error("Full-thirst fountain interaction incorrectly counted another drink");quit(1);return
    var water_camera:=Camera3D.new();current_scene.add_child(water_camera)
    water_camera.global_position=fountain.to_global(Vector3(7,3,-8));water_camera.look_at(fountain.global_position+Vector3.UP*1.1);water_camera.make_current()
    await _capture("market-fountain-character")
    water_camera.free();player.camera.make_current()
    if not await _walk(Vector2(-8,25.4)):return
    if not await _walk(Vector2(-8,4)):return
    for offset in [Vector2(-8,-18),Vector2(-45,-21),Vector2(-45,-23)]:
        if not await _walk(offset):return
    var home := square.get_node("SquareHome") as Node3D
    var outside:=Camera3D.new()
    current_scene.add_child(outside)
    outside.global_position=home.to_global(Vector3(10,6,13))
    outside.fov=58
    outside.look_at(home.to_global(Vector3(0,2.8,0)))
    outside.make_current()
    await _capture("region-exterior")
    outside.global_position=home.to_global(Vector3(9,1.7,14))
    outside.look_at(home.to_global(Vector3(0,2.8,0)))
    await _capture("region-exterior-eye-level")
    outside.free()
    player.camera.make_current()
    var door := home.get("front_door") as Node3D
    if not bool(door.get("opened")):
        if not await _interact(door, door.to_global(Vector3(0.725,1.2,0))):return
        await create_timer(1).timeout
    if not bool(door.get("opened")):
        push_error("Capital concept front door did not open")
        quit(1)
        return
    if not await _walk(Vector2(-45,-29)):return
    var camera := Camera3D.new()
    current_scene.add_child(camera)
    camera.make_current()
    if not await _room_walk(home,Vector3(-3.1,0,-3.27)):return
    camera.global_position = home.to_global(Vector3(-1.9,2.1,-2.2))
    camera.look_at(player.global_position + Vector3.UP * 0.8)
    await _capture("concept-bedroom-character")
    if not await _room_walk(home,Vector3(3,0,3.1)):return
    camera.global_position = home.to_global(Vector3(2,2.3,2.8))
    camera.fov = 82
    camera.look_at(home.to_global(Vector3(4,1.35,4)))
    await _capture("concept-kitchen-character")
    if not await _room_walk(home,Vector3(1.8,0,-0.8)):return
    camera.global_position = home.to_global(Vector3(1.1,2.2,-0.3))
    camera.fov = 75
    camera.look_at(home.to_global(Vector3(4.3,1,-0.45)))
    await _capture("concept-dining")
    var saved_position := player.global_position
    if not root.get_node("SaveManager").call("save_game", player, 4):
        push_error("Capital concept slot4 save failed")
        quit(1)
        return
    if not root.get_node("SaveManager").call("prepare_load", 4):
        push_error("Capital concept slot4 reload preparation failed")
        quit(1)
        return
    change_scene_to_file("res://scenes/world_loading.tscn")
    player = null
    deadline = Time.get_ticks_msec() + 180000
    await process_frame
    while current_scene == null or current_scene.name != "Bootstrap" or player == null or bool(player.get("ground_guard_active")):
        await physics_frame
        player = get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec() > deadline:
            push_error("Capital concept slot4 reload exceeded its independent 180s bound")
            quit(1)
            return
    for frame in range(12):await physics_frame
    if not player.is_on_floor() or player.global_position.distance_to(saved_position) > 0.4:
        push_error("Capital concept reload did not restore the supported saved position")
        quit(1)
        return
    if int(root.get_node("GameState").get_world_value("fountain:capital:market:uses",0))!=uses_before+1:
        push_error("Fountain use did not survive actual disk reload");quit(1);return
    var proof := {"fountain_use_persisted":true,"inventory_and_coins_conserved":true,"full_thirst_no_extra_use":true,"walked_m":walked,"player_position_assignments":0,"physical_rooms":3,"disk_reload":true,"release_checks":true,"saved_position":str(saved_position),"loaded_position":str(player.global_position)}
    var file := FileAccess.open("user://capital-concept.json",FileAccess.WRITE)
    if file == null:
        push_error("Capital concept proof could not be saved")
        quit(1)
        return
    file.store_string(JSON.stringify(proof,"  "))
    file.close()
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png("user://capital-concept-reloaded.png") != OK:
        push_error("Capital concept reloaded frame could not be saved")
        quit(1)
        return
    print("CAPITAL_CONCEPT_NATIVE_OK edge_houses=22 market_canopies=6 earned_checkpoint=true walked_m=", walked, " player_position_assignments=0 physical_rooms=3 reach_checked_front_door=true save_slot=4 disk_reload=true release_checks=true fountain_interaction=true fountain_disk_reload=true quality=Medium clock_fixture=09:00")
    quit(0)
