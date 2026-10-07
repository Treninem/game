extends Node

const WARMUP_FRAMES := 60
const TRANSITION_FRAMES := 12

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    print("::error title=Offworld streaming smoke::%s" % message.replace("\n", " "))
    push_error("Offworld streaming smoke failed: %s" % message)
    get_tree().quit(code)

func _loaded_count(streamer: Node) -> int:
    var value = streamer.get("loaded_chunks")
    if value is Dictionary:
        return value.size()
    return -1

func _assert_suspended(streamer: Node, phase: String, code: int) -> bool:
    if not bool(streamer.get("streaming_suspended")):
        _fail(code, "%s did not suspend mainland streaming" % phase)
        return false
    if _loaded_count(streamer) != 0:
        _fail(code + 1, "%s kept mainland chunks loaded: %d" % [phase, _loaded_count(streamer)])
        return false
    var generation = streamer.get("generation_queue")
    var collision = streamer.get("collision_queue")
    if generation is Array and not generation.is_empty():
        _fail(code + 2, "%s left visual generation queued" % phase)
        return false
    if collision is Array and not collision.is_empty():
        _fail(code + 3, "%s left collision generation queued" % phase)
        return false
    return true

func _run_test() -> void:
    var tree := get_tree()
    GameState.reset_new_game()

    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "stage1 scene could not be loaded")
        return

    var scene := packed.instantiate()
    tree.root.add_child(scene)
    for _i in range(WARMUP_FRAMES):
        await tree.physics_frame

    var player := scene.get_node_or_null("World/Player") as CharacterBody3D
    var streamer := scene.get_node_or_null("World/WorldStreamer")
    var realm_runtime := scene.get_node_or_null("World/RealmRuntime")
    var dungeon_runtime := scene.get_node_or_null("World/DungeonRuntime")
    if player == null or streamer == null or realm_runtime == null or dungeon_runtime == null:
        _fail(3, "required runtime node is missing")
        return

    if _loaded_count(streamer) <= 0:
        _fail(4, "mainland streaming did not bootstrap before transition")
        return

    if not bool(realm_runtime.call("enter_realm", "ash_abyss", player)):
        _fail(5, "realm transition failed")
        return
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if not _assert_suspended(streamer, "realm", 6):
        return

    if not bool(realm_runtime.call("enter_realm", "main", player)):
        _fail(10, "return from realm failed")
        return
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if bool(streamer.get("streaming_suspended")) or _loaded_count(streamer) <= 0:
        _fail(11, "mainland streaming did not resume after realm return")
        return

    var dungeon_result: Dictionary = ProgressionSystem.start_dungeon("H")
    if not bool(dungeon_result.get("ok", false)):
        _fail(12, "dungeon transition failed: %s" % dungeon_result)
        return
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if not _assert_suspended(streamer, "dungeon", 13):
        return

    dungeon_runtime.call("abort_current_dungeon")
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if bool(streamer.get("streaming_suspended")) or _loaded_count(streamer) <= 0:
        _fail(17, "mainland streaming did not resume after dungeon exit")
        return

    print("OFFWORLD_STREAMING_SMOKE_OK realm=suspended dungeon=suspended mainland=resumed")
    tree.quit(0)
