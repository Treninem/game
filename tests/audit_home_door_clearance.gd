extends SceneTree

# Diagnostic setup at the actual far-capital coordinates. The home, leaf,
# trim, furniture, people, routines and physics are the production classes.
# Position assignment below creates each fixture; none occurs during travel.
var errors: Array[String] = []
var rows: Array = []
var fixture: Node3D
var home: Node3D

func _initialize() -> void:
    create_timer(210).timeout.connect(func():
        push_error("Home doorway diagnostic watchdog expired")
        quit(1)
    )
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await physics_frame

func _resident(height: float, side: float, entering: bool, identity: String) -> CharacterBody3D:
    var state := root.get_node("GameState")
    state.set_world_value("appearance:" + identity, {"sex": "male", "height_cm": height})
    # Load production scripts only after the normal autoloads are available.
    var npc: CharacterBody3D = load("res://scripts/settlement_npc.gd").new()
    npc.name = "DoorCitizen" + str(rows.size())
    npc.role = "craftsman"
    npc.set_meta("citizen_id", identity)
    npc.set_meta("home_building", "Home")
    npc.set_meta("routine_places", {"home": Vector3(0, 0, 0), "work": Vector3(0, 0, 10)})
    # Reproduce the observed lateral offset and the jamb's physical edge.
    npc.position = home.position + Vector3(side * .262695, home.floor_thickness + .025, 5.148926 if entering else 3.7)
    fixture.add_child(npc)
    npc.ground_ready = true
    await _frames(8)
    npc.home_crossing = entering
    npc.autonomous = true
    return npc

func _travel(npc: CharacterBody3D, entering: bool, limit: int) -> Dictionary:
    var previous := npc.global_position
    var walked := 0.0
    var maximum_frame_motion := 0.0
    var reached := false
    var elapsed := 0
    for frame in range(limit):
        await physics_frame
        var motion := npc.global_position.distance_to(previous)
        walked += motion
        maximum_frame_motion = maxf(maximum_frame_motion, motion)
        previous = npc.global_position
        elapsed = frame + 1
        var point := home.to_local(npc.global_position)
        if npc.is_on_floor() and absf(point.x) < .8 and (point.z < 3.9 if entering else point.z > 6.1):
            reached = true
            break
    return {"reached": reached, "frames": elapsed, "walked_m": walked,
            "maximum_frame_motion_m": maximum_frame_motion,
            "end_home_local": home.to_local(npc.global_position),
            "activity": npc.activity, "grounded": npc.is_on_floor()}

func _run() -> void:
    root.get_node("GameState").world_minutes = 22 * 60
    fixture = Node3D.new()
    fixture.name = "FarCapitalDoorFixture"
    var center: Vector2 = load("res://scripts/capital_data.gd").CENTER
    var elevation: float = root.get_node("WorldData").elevation_at(center)
    fixture.position = Vector3(center.x, elevation + .025, center.y)
    root.add_child(fixture)
    current_scene = fixture
    var ground := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(40, .2, 40)
    collision.shape = shape
    collision.position.y = -.1
    ground.add_child(collision)
    fixture.add_child(ground)
    home = load("res://scripts/enterable_building.gd").new()
    home.name = "Home"
    home.configure(Vector3(12, 3.2, 10), 1, "Проверка настоящего прохода")
    home.position.y = .03 - home.floor_thickness
    fixture.add_child(home)
    load("res://scripts/cottage_exterior.gd").build(home)
    home.front_door.set_open(true, true)
    await _frames(8)
    for height: float in [160, 180, 200]:
        for side: float in [-1, 1]:
            for entering: bool in [true, false]:
                root.get_node("GameState").world_minutes = (22 if entering else 9) * 60
                home.set_meta("door_user", 0)
                home.front_door.set_open(true, true)
                var identity := "audit:door:%s:%s:%s" % [height, side, entering]
                var npc: CharacterBody3D = await _resident(height, side, entering, identity)
                var target := home.to_global(Vector3(0, home.floor_thickness, 3.2 if entering else 7))
                var desired := target - npc.global_position
                desired.y = 0
                desired = desired.normalized()
                var ray_clear: bool = npc._routine_way_clear(desired, 1.8)
                var capsule_blocked := npc.test_move(npc.global_transform, desired * .3)
                var result: Dictionary = await _travel(npc, entering, 480)
                result.merge({"height_cm": height, "side": side, "entering": entering,
                    "initial_centre_ray_clear": ray_clear, "initial_body_motion_blocked": capsule_blocked,
                    "ordinary_speed_m_s": npc.move_speed, "driver_position_assignments_after_setup": 0})
                rows.append(result)
                print("HOME_DOOR_CASE ", JSON.stringify(result))
                if not result.reached:
                    errors.append("Physical doorway crossing failed: height=%s side=%s entering=%s end=%s activity=%s" % [height, side, entering, result.end_home_local, result.activity])
                if result.maximum_frame_motion_m > .15:
                    errors.append("Door fixture unexpectedly displaced the citizen faster than normal physical movement")
                npc.queue_free()
                await _frames(2)
    var output := FileAccess.open("user://home-door-clearance.json", FileAccess.WRITE)
    output.store_string(JSON.stringify({"actual_production_home_and_people": true,
        "controlled_fixture": true, "manual_play": false,
        "capital_origin": fixture.global_position, "door_clear_width_m": home.doorway_width,
        "driver_position_assignments_after_setup": 0, "cases": rows, "errors": errors}, "  "))
    output.close()
    if not errors.is_empty():
        for message in errors:
            push_error(message)
        quit(1)
        return
    print("HOME_DOOR_CLEARANCE_OK cases=", rows.size())
    quit(0)
