extends SceneTree

var player: CharacterBody3D
var village: Node3D
var camera: Camera3D
var distance := 0.0

func _initialize() -> void:
    call_deferred("_run")

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://village-paths-"+label+".png")

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
    create_timer(240).timeout.connect(func(): push_error("Village visual watchdog");quit(1))
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
    print("VILLAGE_FRAME_SAMPLE frames=120 mean_ms=",float(Time.get_ticks_usec()-sample_start)/120000.0,
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
    assert(root.get_node("SaveManager").call("save_game",player,5))
    print("VILLAGE_PATHS_VISUAL_OK walked_m=",distance," player_position_assignments=0 earned_checkpoint=true door=reach_checked save_slot=5 quality=Medium")
    quit(0)
