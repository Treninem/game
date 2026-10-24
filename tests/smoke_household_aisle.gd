extends Node3D

func _ready() -> void:
    get_tree().create_timer(40).timeout.connect(func(): get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    GameState.reset_new_game()
    position = Vector3(CapitalData.CENTER.x, 0, CapitalData.CENTER.y)
    GameState.world_minutes = 21 * 60
    var home := preload("res://scripts/enterable_building.gd").new()
    home.name = "SquareHome"
    home.configure(Vector3(12, 3.2, 10))
    add_child(home)
    var blocker := CharacterBody3D.new()
    blocker.name = "StationaryHero"
    blocker.position = Vector3(0, 0.2, 1)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    blocker.add_child(collision)
    add_child(blocker)
    var resident := preload("res://scripts/settlement_npc.gd").new()
    resident.name = "AisleCraftsman"
    resident.configure("Resident", "craftsman", 0, [])
    resident.autonomous = true
    resident.set_meta("citizen_id", "aisle:resident")
    resident.set_meta("home_building", "SquareHome")
    resident.set_meta("routine_places", {"home": Vector3(0, 0, 1)})
    resident.position = home.get_node("InteriorFurniture/BedSecond").approach_point() - global_position
    GameState.set_world_value("household:aisle:resident", {"stored": true, "seated_seconds": 0.0})
    add_child(resident)
    var before := blocker.global_position
    for frame in range(1500):
        await get_tree().physics_frame
        if resident.get_meta("activity") == "sit":
            assert(blocker.global_position.distance_to(before) < 0.01, "Resident displaced the stationary hero")
            print("HOUSEHOLD_AISLE_OK hero=stationary capsule=physical resident=passed_and_sat")
            get_tree().quit(0)
            return
    push_error("Resident cannot clear a stationary hero in the household aisle: " + str(resident.position))
    get_tree().quit(1)
