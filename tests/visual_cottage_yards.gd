extends SceneTree

var player: CharacterBody3D
var village: Node3D
var camera: Camera3D
var distance := 0.0

func _initialize() -> void:
    call_deferred("_run")

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://cottage-yards-"+label+".png")

func _walk(point: Vector2) -> bool:
    var target := village.to_global(Vector3(point.x,0,point.y))
    var began := Time.get_ticks_msec()
    player.camera.rotation = Vector3.ZERO
    while Vector2(player.global_position.x-target.x,player.global_position.z-target.z).length()>0.32:
        var direction := target-player.global_position
        player.rotation.y = atan2(-direction.x,-direction.z)
        var before := player.global_position
        Input.action_press("move_forward")
        await physics_frame
        distance += Vector2(before.x-player.global_position.x,before.z-player.global_position.z).length()
        if Time.get_ticks_msec()-began>20000:
            Input.action_release("move_forward")
            push_error("Village normal walk blocked at %s toward %s" % [village.to_local(player.global_position),point])
            quit(1)
            return false
    Input.action_release("move_forward")
    return true

func _follow(path: PackedVector2Array) -> bool:
    for point in path:
        if not await _walk(point): return false
    for frame in range(12):await physics_frame
    assert(player.is_on_floor())
    return true

func _run() -> void:
    create_timer(400).timeout.connect(func(): push_error("Village visual watchdog");quit(1))
    assert(root.get_node("SaveManager").call("prepare_load",4),"Requires a checkpoint reached by ordinary forest journey")
    root.get_node("SettingsManager").call("set_quality_preset",1)
    change_scene_to_file("res://scenes/world_loading.tscn")
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or bool(player.get("ground_guard_active")):
        await physics_frame
        player = get_first_node_in_group("player") as CharacterBody3D
    current_scene.set_process(false)
    root.get_node("GameState").set("world_minutes",9.0*60)
    var settlements := current_scene.get_node("World/Settlements")
    village = settlements.loaded.get("border_village_01")
    assert(village!=null,"Real village was not streamed around the arrival save")
    camera = Camera3D.new()
    current_scene.add_child(camera)
    camera.global_position = village.to_global(Vector3(25,55,68))
    camera.look_at(village.to_global(Vector3(0,0,0)))
    camera.make_current()
    await _capture("overview")
    var local := village.to_local(player.global_position)
    var lanes: Array = village.get_node("VillageLanes").get_meta("local_paths")
    var nearest := INF
    var approach := PackedVector2Array()
    for path: PackedVector2Array in lanes:
        if path[0].distance_squared_to(Vector2(local.x,local.z))<nearest:
            nearest = path[0].distance_squared_to(Vector2(local.x,local.z))
            approach = path
    if not await _follow(approach):return
    camera.global_position = village.to_global(Vector3(8,3.3,14))
    camera.look_at(player.global_position+Vector3.UP)
    await _capture("square-character")
    var sample_start := Time.get_ticks_usec()
    for frame in range(120):await process_frame
    print("COTTAGE_FRAME_SAMPLE frames=120 mean_ms=",float(Time.get_ticks_usec()-sample_start)/120000.0,
        " video_bytes=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
        " draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
    var home := village.get_node("Enterable_01") as Node3D
    var houses: Array[Node3D] = []
    for child in village.get_children():
        if child is Node3D and child.name.begins_with("Enterable_"): houses.append(child)
    var footpath: PackedVector2Array = village.get_node("HomeAccess_Enterable_01").get_meta("local_path")
    var planner: Script = load("res://scripts/settlement_paths.gd")
    var grid: AStarGrid2D = planner._grid(village,houses,0.8)
    if not await _follow(grid.get_point_path(Vector2i.ZERO,Vector2i(footpath[-1].round()))):return
    var reversed := footpath.duplicate()
    reversed.reverse()
    # Stop short of the closed door, at ordinary interaction distance.
    reversed.remove_at(reversed.size()-1)
    if not await _follow(reversed):return
    var door := home.get("front_door") as Node3D
    var toward := door.to_global(Vector3(0.725,1.1,0))
    player.rotation.y = atan2(-(toward-player.global_position).x,-(toward-player.global_position).z)
    for frame in range(8):await physics_frame
    player.camera.look_at(toward)
    player.interaction_ray.force_raycast_update()
    assert(player.interaction_ray.get_collider()==door,"Actual front door not selected by player ray")
    player.call("_try_interact")
    for frame in range(40):await physics_frame
    assert(bool(door.get("opened")))
    camera.global_position = home.to_global(Vector3(4.5,2.8,10))
    camera.look_at(home.to_global(Vector3(0,1.2,3)))
    await _capture("home-entrance")
    var yard := home.get_node("GardenYard") as Node3D
    if not await _garden(home,yard):return
    var chest_home := village.get_node("Enterable_02") as Node3D
    var chest_yard := chest_home.get_node("GardenYard") as Node3D
    var path: PackedVector2Array = chest_yard.get_meta("access_path")
    if not await _public_route(path[0]):return
    if not await _garden(chest_home,chest_yard):return
    var chest := chest_yard.get_node("GardenChest") as Node3D
    var offset: Vector2 = chest_yard.get_meta("plot_offset")
    if not await _walk(_point(chest_home,offset+Vector2(0,.25))):return
    camera.global_position=chest_home.to_global(Vector3(offset.x+2.4,2.1,offset.y+2.8))
    camera.look_at(chest.global_position+Vector3.UP*.35)
    if not await _use(chest,chest.global_position+Vector3.UP*.12):return
    assert(bool(root.get_node("DialogueManager").get("is_open")))
    await _capture("storage-ui")
    var count: int = int(Dictionary(root.get_node("GameState").get("inventory")).get("berries",0))
    if not await _choose("Положить: Лесные ягоды"):return
    assert(int(Dictionary(root.get_node("GameState").get("inventory")).get("berries",0))==count-1)
    assert(Dictionary(chest.call("contents")).get("berries",0)==1)
    if not await _choose("Закрыть сундук"):return
    for frame in range(10):await physics_frame
    # Jump against the actual sloping store roof and land on streamed terrain.
    var capsule := player.get_node("CollisionShape3D") as CollisionShape3D
    var query := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*2.1,player.global_position+Vector3.UP*4,1,[player.get_rid()])
    var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
    assert(not hit.is_empty(),"Store roof is not physical")
    var ceiling: float = Vector3(hit.position).y
    Input.action_press("jump")
    await physics_frame
    Input.action_release("jump")
    var max_top := 0.0
    for frame in range(100):
        await physics_frame
        var top := player.global_position.y+capsule.position.y+(capsule.shape as CapsuleShape3D).height*.5
        max_top=maxf(max_top,top)
        assert(top<=ceiling+.055,"Player head passes through the store roof")
    assert(player.is_on_floor(),"Player remains airborne after store jump")
    await _capture("store-character")
    for preset in [0,1,2,3]:
        root.get_node("SettingsManager").call("set_quality_preset",preset)
        for frame in range(30):await process_frame
        await _capture("quality-%d" % preset)
    root.get_node("SettingsManager").call("set_quality_preset",1)
    assert(root.get_node("SaveManager").call("save_game",player,5))
    print("COTTAGE_YARDS_VISUAL_OK walked_m=",distance," driver_position_assignments=0 earned_checkpoint=true gates=reach_checked harvest=finite storage=actual_ui_button disk_slot=5 jump_roof=physical max_capsule_top=",max_top," ceiling=",ceiling," presets=4")
    quit(0)

func _point(home: Node3D,p: Vector2) -> Vector2:
    var local := village.to_local(home.to_global(Vector3(p.x,0,p.y)))
    return Vector2(local.x,local.z)

func _use(target: Node3D,point: Vector3) -> bool:
    var toward := point-player.global_position
    player.rotation.y=atan2(-toward.x,-toward.z)
    player.camera.rotation=Vector3.ZERO
    for frame in range(8):await physics_frame
    player.camera.look_at(point)
    player.interaction_ray.force_raycast_update()
    if player.interaction_ray.get_collider()!=target:
        push_error("Cottage use ray selected %s instead of %s" % [player.interaction_ray.get_collider(),target.name])
        quit(1)
        return false
    player.call("_try_interact")
    for frame in range(4):await process_frame
    return true

func _choose(prefix: String) -> bool:
    for button: Button in root.find_children("*","Button",true,false):
        if not button.is_visible_in_tree() or not button.text.begins_with(prefix):continue
        button.grab_focus()
        var event := InputEventAction.new()
        event.action="ui_accept"
        event.pressed=true
        Input.parse_input_event(event)
        Input.flush_buffered_events()
        await process_frame
        event=InputEventAction.new()
        event.action="ui_accept"
        event.pressed=false
        Input.parse_input_event(event)
        Input.flush_buffered_events()
        for frame in range(4):await process_frame
        return true
    push_error("Actual storage button not found: "+prefix)
    quit(1)
    return false

func _garden(home: Node3D,yard: Node3D) -> bool:
    var path: PackedVector2Array = yard.get_meta("access_path")
    if not await _follow(path):return false
    var offset: Vector2=yard.get_meta("plot_offset")
    var size: Vector2=yard.get_meta("plot_size")
    if not await _walk(_point(home,offset+Vector2(0,size.y*.5+2.4))):return false
    var gate := yard.get_node("GardenGate") as Node3D
    if not await _use(gate,gate.to_global(Vector3(1,.55,0))):return false
    for frame in range(45):await physics_frame
    assert(not bool(gate.get("opened")))
    if not await _use(gate,gate.to_global(Vector3(1,.55,0))):return false
    for frame in range(45):await physics_frame
    assert(bool(gate.get("opened")))
    if not await _walk(_point(home,offset+Vector2(0,size.y*.5-.5))):return false
    var berry := yard.get_node("Berry_0") as Node3D
    if not await _walk(_point(home,offset+Vector2(-1.7 if not yard.has_node("GardenChest") else -2.1,.8))):return false
    var before: int=int(Dictionary(root.get_node("GameState").get("inventory")).get("berries",0))
    for i in range(3):
        if not await _use(berry,berry.global_position+Vector3.UP*.65):return false
        for frame in range(3):await physics_frame
    assert(int(Dictionary(root.get_node("GameState").get("inventory")).get("berries",0))==before+3)
    assert(int(berry.get("uses"))==0)
    if not _observe_yard(home,offset):return false
    await _capture("garden-"+String(home.name))
    if not yard.has_node("GardenChest"):
        if not await _walk(_point(home,offset+Vector2(0,size.y*.5-.5))):return false
        if not await _walk(_point(home,offset+Vector2(0,size.y*.5+3))):return false
        var back:=path.duplicate()
        back.reverse()
        if not await _follow(back):return false
    return true

func _public_route(destination: Vector2) -> bool:
    var houses: Array[Node3D]=[]
    for child in village.get_children():
        if child is Node3D and child.name.begins_with("Enterable_"):houses.append(child)
    var planner: Script=load("res://scripts/settlement_paths.gd")
    var grid: AStarGrid2D=planner._grid(village,houses,1.0)
    var footprints: Array[PackedVector2Array]=[]
    for surface: Node3D in get_nodes_in_group("terrain_path_surface"):
        if not village.is_ancestor_of(surface) or surface.name=="CultivatedGround":continue
        for polygon: PackedVector2Array in surface.get_meta("path_polygons",[]):footprints.append(polygon)
    for z in range(-68,69):
        for x in range(-78,79):
            var id:=Vector2i(x,z)
            if grid.is_point_solid(id):continue
            var world:=village.to_global(Vector3(x,0,z))
            var allowed:=false
            for polygon in footprints:
                if Geometry2D.is_point_in_polygon(Vector2(world.x,world.z),polygon):allowed=true;break
            if not allowed:grid.set_point_solid(id)
    var local:=village.to_local(player.global_position)
    var path:=grid.get_point_path(Vector2i(Vector2(local.x,local.z).round()),Vector2i(destination.round()))
    assert(not path.is_empty(),"Public streets do not connect the two real yards")
    return await _follow(path)

func _observe_yard(home: Node3D,offset: Vector2) -> bool:
    # Require a physically unobstructed observer view; an image inside an
    # adjacent wall cannot verify art. Player movement remains ordinary input.
    var target := home.to_global(Vector3(offset.x,.9,offset.y))
    for relative: Vector3 in [Vector3(5,4,6),Vector3(-5,4,6),Vector3(0,5,7),Vector3(0,7,0)]:
        var point := home.to_global(Vector3(offset.x,0,offset.y)+relative)
        var query := PhysicsRayQueryParameters3D.create(target,point,1,[player.get_rid()])
        if not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():continue
        camera.global_position=point
        camera.look_at(target)
        return true
    push_error("No clear camera view for the real garden: "+String(home.name))
    quit(1)
    return false
