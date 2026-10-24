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
    assert(player.is_on_floor())
    return true

func _run() -> void:
    assert(root.get_node("SaveManager").call("prepare_load", 1), "Requires actual earned arrival checkpoint")
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
    for offset in [Vector2(-8,4),Vector2(-8,-18),Vector2(-45,-21),Vector2(-45,-23)]:
        if not await _walk(offset):return
    var square: Node = current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO].get_node("CapitalSquareLife")
    var home := square.get_node("SquareHome") as Node3D
    var door := home.get("front_door") as Node3D
    if not bool(door.get("opened")):
        if not await _interact(door, door.to_global(Vector3(0.725,1.2,0))):return
        await create_timer(1).timeout
    assert(door.get("opened"))
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
    assert(root.get_node("SaveManager").call("save_game", player, 4))
    print("CONCEPT_NATIVE_OK earned_checkpoint=true walked_m=", walked, " player_position_assignments=0 physical_rooms=3 reach_checked_front_door=true save_slot=4 quality=Medium clock_fixture=09:00")
    quit(0)
