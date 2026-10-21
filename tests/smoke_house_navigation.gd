extends Node3D

func _ready() -> void:
    get_tree().create_timer(60).timeout.connect(func(): push_error("House navigation fixture timed out"); get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    GameState.reset_new_game()
    position.x = 60
    var decorator := SettlementInteriorVisuals.new()
    add_child(decorator)
    for width: float in [9.0, 12.0]:
        var home := EnterableBuilding.new()
        home.configure(Vector3(width, 3.2, 8 if width < 10 else 10), 1)
        add_child(home)
        decorator.decorate_building(home)
        assert(home.room_count == 4 and home.get_node("HouseRooms").room_doors.size() == 3)
        assert(home.has_node("InteriorFurniture/BedSecond") == (width > 10))
        assert(home.get_node("HouseholdDetails").get_meta("place_settings") == (1 if width < 10 else 2))
        home.free()
    var home := EnterableBuilding.new()
    home.configure(Vector3(12, 3.2, 10), 1)
    add_child(home)
    decorator.decorate_building(home)
    var actor := CharacterBody3D.new()
    add_child(actor)
    var from := Vector3(0.3, 0.22, 0)
    var goal := Vector3(0.3, 0.22, -3.2)
    actor.global_position = home.to_global(from)
    var navigation = load("res://scripts/house_navigation.gd").new()
    navigation.build(home)
    navigation.next_point(from, goal, actor)
    var original: Array = navigation.routes[actor.get_instance_id()].path.duplicate()
    assert(not original.is_empty())
    var obstacle := StaticBody3D.new()
    obstacle.position = Vector3(0.3, 0.8, -1.6)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.7, 1.2, 0.7)
    collision.shape = shape
    obstacle.add_child(collision)
    home.add_child(obstacle)
    navigation.build(home)
    navigation.next_point(from, goal, actor)
    var detour: Array = navigation.routes[actor.get_instance_id()].path
    assert(not detour.is_empty() and detour != original, "A* did not adapt to a real additional obstacle")
    obstacle.free()
    var person := CharacterBody3D.new()
    person.add_to_group("settlement_npc")
    person.position = Vector3(0.3, 0.22, -1.6)
    var person_collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.34
    capsule.height = 1.8
    person_collision.shape = capsule
    person_collision.position.y = 0.9
    person.add_child(person_collision)
    add_child(person)
    navigation.build(home)
    navigation.next_point(from, goal, actor)
    var around_person: Array = navigation.routes[actor.get_instance_id()].path
    assert(not around_person.is_empty() and around_person != original, "AI did not replan around a stationary person")
    person.free()
    var door: DoorInteractable = home.get_node("HouseRooms").room_doors[0]
    door.set_locked(true)
    navigation.next_point(from, Vector3(-2.8, 0.22, -3.27), actor)
    assert(navigation.routes[actor.get_instance_id()].path.is_empty(), "AI routes through a locked bedroom door")
    door.set_locked(false)
    navigation.next_point(from, Vector3(-2.8, 0.22, -3.27), actor)
    assert(not navigation.routes[actor.get_instance_id()].path.is_empty(), "AI fails to reconsider an unlocked door")
    print("HOUSE_NAVIGATION_OK layouts=2 furnishings=occupancy_scaled dynamic_obstacle=detour stationary_person=detour locked_door=unreachable unlocked_door=replanned")
    get_tree().quit(0)
