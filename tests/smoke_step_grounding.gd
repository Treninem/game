extends Node3D

func _box(parent: Node3D, position: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = position
    parent.add_child(body)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    var player := world.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    world.free()
    var origin := WorldGeography.START_SPAWN
    var height := WorldData.elevation_at(origin)
    var fixture := Node3D.new()
    fixture.position = Vector3(origin.x, 0, origin.y)
    add_child(fixture)
    _box(fixture, Vector3(0, height - 0.5, 0), Vector3(20, 1, 30))
    for index in range(4):
        var rise := float(index + 1) * 0.22
        _box(fixture, Vector3(0, height + rise * 0.5, -2.0 - index * 0.75), Vector3(3, rise, 0.75))
    _box(fixture, Vector3(0, height + 2.0, -4.9), Vector3(3, 4, 0.4))
    add_child(player)
    player.global_position = Vector3(origin.x, height + 0.08, origin.y)
    player.rotation.y = 0
    player.call("_begin_ground_guard", true)
    for frame in range(90):
        await get_tree().physics_frame
    Input.action_press("move_forward")
    var climbed := false
    for frame in range(900):
        await get_tree().physics_frame
        if player.global_position.z < origin.y - 4.0:
            climbed = true
            break
    if not climbed or player.global_position.y < height + 0.75:
        Input.action_release("move_forward")
        push_error("Player cannot climb supported 22 cm steps: %s" % player.global_position)
        get_tree().quit(1)
        return
    var highest := player.global_position.y
    for frame in range(240):
        await get_tree().physics_frame
        highest = maxf(highest, player.global_position.y)
    Input.action_release("move_forward")
    if highest > height + 1.0 or player.global_position.z < origin.y - 4.75:
        push_error("Player climbs or floats against a tall wall: %s highest=%f" % [player.global_position, highest])
        get_tree().quit(1)
        return
    print("STEP_GROUNDING_OK stairs=22cm wall=no_air_climb maximum_y=", highest)
    get_tree().quit(0)
