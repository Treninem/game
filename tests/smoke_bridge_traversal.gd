extends Node

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    var player := world.get_node("World/Player") as CharacterBody3D
    var direction := WorldHydrology.ROAD_BRIDGE_DIRECTION.normalized()
    var center := WorldHydrology.ROAD_BRIDGE_CENTER
    var start := center - direction * 68.0
    player.global_position = Vector3(start.x, WorldData.elevation_at(start) + 0.08, start.y)
    player.rotation.y = atan2(-direction.x, -direction.y)
    player.call("_begin_ground_guard", true)
    for frame in range(180):
        await get_tree().physics_frame
    Input.action_press("move_forward")
    Input.action_press("sprint")
    var crossed := false
    for frame in range(1800):
        await get_tree().physics_frame
        var position := Vector2(player.global_position.x, player.global_position.z)
        if (position - center).dot(direction) > 66.0:
            crossed = true
            break
    Input.action_release("move_forward")
    Input.action_release("sprint")
    if not crossed or not player.is_on_floor():
        push_error("Player cannot continuously traverse bridge and both banks: %s" % player.global_position)
        get_tree().quit(1)
        return
    print("BRIDGE_TRAVERSAL_OK bank_to_bank=continuous player=grounded position=", player.global_position)
    world.queue_free()
    await get_tree().create_timer(0.15, true).timeout
    get_tree().quit(0)
