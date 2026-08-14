extends SceneTree

const MIN_DISTANCE := 0.75
const WARMUP_FRAMES := 12
const MOVE_FRAMES := 45

func _initialize() -> void:
    call_deferred("_run_test")

func _run_test() -> void:
    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        push_error("Movement smoke: main stage scene could not be loaded")
        quit(2)
        return

    var scene := packed.instantiate()
    root.add_child(scene)
    for _i in range(WARMUP_FRAMES):
        await physics_frame

    var player := scene.get_node_or_null("World/Player") as CharacterBody3D
    if player == null:
        push_error("Movement smoke: player node missing")
        quit(3)
        return

    var start := Vector2(player.global_position.x, player.global_position.z)
    Input.action_press("move_forward", 1.0)
    for _i in range(MOVE_FRAMES):
        await physics_frame
    Input.action_release("move_forward")
    await physics_frame

    var finish := Vector2(player.global_position.x, player.global_position.z)
    var distance := start.distance_to(finish)
    print("Movement smoke: start=", start, " finish=", finish, " distance=", distance)
    if distance < MIN_DISTANCE:
        push_error("Movement smoke failed: player walked in place")
        quit(4)
        return
    print("Movement smoke passed")
    quit(0)
