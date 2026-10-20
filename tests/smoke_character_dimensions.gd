extends Node3D

var failures: Array[String] = []
const APPEARANCE := preload("res://scripts/character_appearance.gd")

func _ready() -> void:
    call_deferred("_run")

func _box(at: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)
    add_child(body)

func _run() -> void:
    var before := GameState.snapshot()
    GameState.set_world_value("player_appearance", APPEARANCE.preset(0))
    var world := preload("res://scenes/stage1.tscn").instantiate()
    var player := world.get_node("World/Player") as CharacterBody3D
    var original_shape := (player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
    player.get_parent().remove_child(player)
    world.free()
    var spawn := WorldGeography.START_SPAWN
    var origin := Vector3(spawn.x, WorldData.elevation_at(spawn), spawn.y)
    _box(origin + Vector3(0, -0.5, 0), Vector3(20, 1, 20))
    _box(origin + Vector3(3, 2.05, 0), Vector3(2, 0.4, 6))
    add_child(player)
    player.set_physics_process(false)
    player.set_process_input(false)
    player.global_position = origin + Vector3.UP * 0.08
    var visual := player.get_node("Avatar")
    visual.set_process(false)
    var collider := player.get_node("CollisionShape3D") as CollisionShape3D
    var base_position := player.global_position
    for height in [160.0, 195.0, 180.0]:
        var profile := APPEARANCE.preset(0)
        profile.height_cm = height
        visual.call("apply_appearance", profile)
        for frame in range(3):
            await get_tree().physics_frame
        var capsule := collider.shape as CapsuleShape3D
        if not is_equal_approx(capsule.height, height / 100.0):
            failures.append("Physical capsule does not match selected height")
        if not is_zero_approx(collider.position.y - capsule.height * 0.5) or player.global_position.distance_to(base_position) > 0.0001:
            failures.append("Height adjustment displaced the feet/root")
        if not is_equal_approx((player.get_node("CameraPivot") as Node3D).position.y, 1.35 * height / 180.0):
            failures.append("Camera pivot does not follow height or accumulates scaling")
        if not player.test_move(player.global_transform, Vector3.DOWN * 0.2):
            failures.append("Feet capsule does not find its actual floor")
        var hits_low_roof := player.test_move(player.global_transform, Vector3(3, 0, 0))
        if hits_low_roof != (height > 177.0):
            failures.append("Physical low passage ignores height: %s hits=%s" % [height, hits_low_roof])
    if collider.shape == original_shape or not is_equal_approx(original_shape.height, 1.8):
        failures.append("Resizing one actor modified the shared scene capsule")
    player.queue_free()
    await get_tree().process_frame
    GameState.load_snapshot(before)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("CHARACTER_DIMENSIONS_OK heights=160,195,180 grounded_root=stable low_roof=physical camera=scaled shared_shape=isolated")
    get_tree().quit(0 if failures.is_empty() else 1)
