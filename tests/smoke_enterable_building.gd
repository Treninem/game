extends Node3D

const BUILDING_SCRIPT := preload("res://scripts/enterable_building.gd")
const CITY_SCRIPT := preload("res://scripts/city_district.gd")

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Enterable building smoke::%s" % clean)
    push_error("Enterable building smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var building := BUILDING_SCRIPT.new() as EnterableBuilding
    building.name = "TestEnterableHouse"
    building.configure(Vector3(9.0, 3.2, 8.0), 0, "Тестовый дом")
    add_child(building)

    for _i in range(5):
        await get_tree().physics_frame

    if building.room_count != 1:
        _fail(2, "building does not expose exactly one real starter room")
        return
    if building.door_count != 1 or building.front_door == null:
        _fail(3, "building is missing its physical interactive front door")
        return
    if building.window_count < 3:
        _fail(4, "building does not have real window openings on multiple walls")
        return
    if building.structural_piece_count < 14:
        _fail(5, "building shell is suspiciously monolithic")
        return
    if building.interior_size.x <= 0.0 or building.interior_size.z <= 0.0:
        _fail(6, "building has no measurable interior volume")
        return
    if not building.is_in_group("enterable_building"):
        _fail(7, "building is not registered as an enterable world space")
        return
    if not building.front_door.has_method("interact"):
        _fail(8, "front door is decorative and has no interact method")
        return

    var furniture := building.get_node_or_null("InteriorFurniture") as Node3D
    if furniture == null:
        _fail(16, "interior is an empty room with no furniture root")
        return
    if building.interior_prop_count < 4:
        _fail(17, "interior has fewer than four physical furniture pieces")
        return
    var required_props := ["Bed", "Table", "StorageChest", "Bench"]
    for prop_name in required_props:
        var prop := furniture.get_node_or_null(prop_name) as StaticBody3D
        if prop == null:
            _fail(18, "missing physical interior prop %s" % prop_name)
            return
        var has_collision := false
        for child in prop.get_children():
            if child is CollisionShape3D and (child as CollisionShape3D).shape != null:
                has_collision = true
                break
        if not has_collision:
            _fail(19, "interior prop %s is decorative and has no collision" % prop_name)
            return
        if absf(prop.position.x) < building.doorway_width * 0.65 and prop.position.z > -2.0:
            _fail(20, "interior prop %s blocks the main doorway aisle" % prop_name)
            return

    # Closed door must physically block a chest-height ray through the doorway.
    building.front_door.set_open(false, true)
    await get_tree().physics_frame
    var closed_hit := _ray(Vector3(0.0, 1.25, 6.0), Vector3(0.0, 1.25, 2.6))
    if closed_hit.is_empty():
        _fail(9, "closed door does not block the doorway")
        return
    var closed_collider := closed_hit.get("collider") as Node
    if closed_collider != building.front_door:
        _fail(10, "closed doorway is blocked by a sealed facade instead of the door; collider=%s" % closed_collider)
        return

    # Open door must clear the exact same passage into the interior.
    building.front_door.set_open(true, true)
    await get_tree().physics_frame
    var open_hit := _ray(Vector3(0.0, 1.25, 6.0), Vector3(0.0, 1.25, 0.0))
    if not open_hit.is_empty():
        _fail(11, "open doorway is still physically sealed; collider=%s" % open_hit.get("collider"))
        return

    # Adjacent facade must still be solid, proving we did not simply remove the wall.
    var wall_hit := _ray(Vector3(3.0, 1.25, 6.0), Vector3(3.0, 1.25, 2.6))
    if wall_hit.is_empty():
        _fail(12, "front wall beside the doorway has no collision")
        return
    var wall_collider := wall_hit.get("collider") as Node
    if wall_collider == building.front_door:
        _fail(13, "door collision incorrectly spans the facade")
        return

    # Back window must be a genuine opening rather than a wall painted as glass.
    var window_hit := _ray(Vector3(0.0, 1.55, -6.0), Vector3(0.0, 1.55, -2.7))
    if not window_hit.is_empty():
        _fail(14, "window opening is physically sealed; collider=%s" % window_hit.get("collider"))
        return

    # Main interior aisle must remain free at human height after furnishing.
    var interior_hit := _ray(Vector3(0.0, 1.25, 1.6), Vector3(0.0, 1.25, -1.6))
    if not interior_hit.is_empty():
        _fail(15, "furniture or a whole-house collision blocks the main interior aisle")
        return

    # City houses used to be visual shells wrapped in one solid 8xN x8 collision.
    # Materialize the exact house path used by Lumengrad and prove all represented
    # floors are physical, connected by stairs and actually enterable.
    var city := CITY_SCRIPT.new()
    city.name = "CityDistrictHarness"
    add_child(city)
    await get_tree().process_frame

    var city_cell := Node3D.new()
    city_cell.name = "CityHouseTestCell"
    city.add_child(city_cell)
    var rng := RandomNumberGenerator.new()
    rng.seed = 771331
    var townhouse := city.call(
        "_build_medieval_house",
        city_cell,
        Vector3(20.0, 0.0, 0.0),
        0.0,
        "aristocratic",
        rng
    ) as EnterableTownhouse

    for _i in range(4):
        await get_tree().physics_frame

    if townhouse == null:
        _fail(21, "Lumengrad house generator did not return an enterable townhouse")
        return
    if not townhouse.is_in_group("enterable_city_house") or not townhouse.is_in_group("enterable_building"):
        _fail(22, "Lumengrad townhouse is not registered as an enterable world space")
        return
    if townhouse.story_count != 3 or townhouse.room_count != 3:
        _fail(23, "elite Lumengrad townhouse lost its three physical represented floors")
        return
    if townhouse.stair_flight_count != townhouse.story_count - 1:
        _fail(24, "represented townhouse floors are not connected by physical stair flights")
        return
    if townhouse.structural_piece_count < 70:
        _fail(25, "townhouse structure is suspiciously simple and may have regressed to monolithic collision")
        return
    if townhouse.interior_prop_count < townhouse.story_count * 2:
        _fail(26, "townhouse represented floors do not contain physical interior fixtures")
        return
    if townhouse.interior_floor_area_m2 <= 80.0:
        _fail(27, "townhouse has no measurable multi-floor interior area")
        return
    if bool(townhouse.get_meta("monolithic_collision", true)):
        _fail(28, "townhouse explicitly reports a monolithic whole-building collision")
        return
    if not bool(townhouse.get_meta("interior_fits_shell", false)):
        _fail(29, "townhouse interior is not bounded by its physical exterior shell")
        return
    if townhouse.get_node_or_null("RealPackRoof") == null:
        _fail(30, "townhouse lost the promoted production roof asset")
        return

    var townhouse_shell := townhouse.get_node_or_null("PhysicalShell") as Node3D
    if townhouse_shell == null:
        _fail(31, "townhouse has no physical shell root")
        return
    for flight_index in range(townhouse.story_count - 1):
        var flight := townhouse_shell.get_node_or_null("StairFlight_%d" % flight_index) as Node3D
        if flight == null or int(flight.get_meta("step_count", 0)) < 12:
            _fail(32, "townhouse stair flight %d is missing a physically traversable step sequence" % flight_index)
            return
        var physical_steps := 0
        for step_candidate in flight.get_children():
            var step := step_candidate as StaticBody3D
            if step == null:
                continue
            var step_collision := step.get_node_or_null("Collision") as CollisionShape3D
            if step_collision != null and step_collision.shape != null:
                physical_steps += 1
        if physical_steps < 12:
            _fail(33, "townhouse stair flight %d contains decorative rather than physical steps" % flight_index)
            return

    townhouse.front_door.set_open(false, true)
    await get_tree().physics_frame
    var townhouse_closed := _ray(Vector3(20.0, 1.25, 6.0), Vector3(20.0, 1.25, 2.6))
    if townhouse_closed.is_empty() or townhouse_closed.get("collider") != townhouse.front_door:
        _fail(34, "Lumengrad townhouse closed door does not physically control access")
        return

    townhouse.front_door.set_open(true, true)
    await get_tree().physics_frame
    var townhouse_open := _ray(Vector3(20.0, 1.25, 6.0), Vector3(20.0, 1.25, 0.8))
    if not townhouse_open.is_empty():
        _fail(35, "Lumengrad townhouse doorway remains sealed when the door is open; collider=%s" % townhouse_open.get("collider"))
        return

    var townhouse_window := _ray(Vector3(20.0, 1.55, -6.0), Vector3(20.0, 1.55, -3.0))
    if not townhouse_window.is_empty():
        _fail(36, "Lumengrad townhouse back window is not a real physical opening")
        return

    # At the first interstory boundary, the main floor must be solid while the
    # stairwell strip is genuinely open. This catches a hidden full-floor box.
    var floor_hit := _ray(Vector3(18.5, 2.82, 0.0), Vector3(18.5, 3.36, 0.0))
    if floor_hit.is_empty():
        _fail(37, "townhouse first-floor slab is missing beside the stairwell")
        return
    var stairwell_hit := _ray(Vector3(22.45, 2.82, 0.0), Vector3(22.45, 3.36, 0.0))
    if not stairwell_hit.is_empty():
        _fail(38, "townhouse interstory floor seals the physical stairwell opening")
        return

    print("Enterable building smoke passed: starter_room=", building.room_count, " starter_furniture=", building.interior_prop_count, " city_stories=", townhouse.story_count, " city_stairs=", townhouse.stair_flight_count, " city_floor_area_m2=", townhouse.interior_floor_area_m2)
    get_tree().quit(0)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_bodies = true
    query.collide_with_areas = false
    return get_world_3d().direct_space_state.intersect_ray(query)
