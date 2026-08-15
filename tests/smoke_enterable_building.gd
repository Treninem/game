extends Node3D

const BUILDING_SCRIPT := preload("res://scripts/enterable_building.gd")

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

    # Interior must contain free standing space at human height.
    var interior_hit := _ray(Vector3(0.0, 1.25, 1.6), Vector3(0.0, 1.25, -1.6))
    if not interior_hit.is_empty():
        _fail(15, "interior contains a whole-house collision or invisible blocker")
        return

    print("Enterable building smoke passed: room=", building.room_count, " door=", building.door_count, " windows=", building.window_count, " structural_pieces=", building.structural_piece_count, " interior=", building.interior_size)
    get_tree().quit(0)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_bodies = true
    query.collide_with_areas = false
    return get_world_3d().direct_space_state.intersect_ray(query)
