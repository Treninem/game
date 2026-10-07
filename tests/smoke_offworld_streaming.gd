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
    var minigame_runtime := scene.get_node_or_null("World/MinigameRuntime")
    if player == null or streamer == null or realm_runtime == null or dungeon_runtime == null or minigame_runtime == null:
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
    if not bool(player.get("instanced_world_mode")):
        _fail(10, "player did not enter instanced-world recovery mode in realm")
        return
    var realm_safe := player.global_position
    player.global_position.y -= 40.0
    player.velocity = Vector3(0.0, -20.0, 0.0)
    for _i in range(6):
        await tree.physics_frame
    if player.global_position.distance_to(realm_safe) > 2.0:
        _fail(11, "realm fall recovery escaped the realm platform: safe=%s recovered=%s" % [realm_safe, player.global_position])
        return

    var realm_dungeon: Dictionary = ProgressionSystem.start_dungeon("H")
    if bool(realm_dungeon.get("ok", false)) or String(realm_dungeon.get("reason", "")) != "realm_active":
        _fail(12, "dungeon entry was not blocked inside realm: %s" % realm_dungeon)
        return
    if bool(minigame_runtime.call("start_minigame", "courier_race")):
        _fail(13, "minigame entry was not blocked inside realm")
        return

    if not bool(realm_runtime.call("enter_realm", "main", player)):
        _fail(14, "return from realm failed")
        return
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if bool(streamer.get("streaming_suspended")) or _loaded_count(streamer) <= 0:
        _fail(15, "mainland streaming did not resume after realm return")
        return
    if bool(player.get("instanced_world_mode")):
        _fail(16, "player remained in instanced-world mode after realm return")
        return

    ProgressionSystem.set_combat_active(true)
    if bool(realm_runtime.call("enter_realm", "echo_edge", player)):
        _fail(17, "realm entry was not blocked during combat")
        return
    ProgressionSystem.set_combat_active(false)

    if not bool(minigame_runtime.call("start_minigame", "courier_race")):
        _fail(18, "mainland minigame did not start for transition guard test")
        return
    if bool(realm_runtime.call("enter_realm", "echo_edge", player)):
        _fail(19, "realm entry was not blocked during active minigame")
        return
    minigame_runtime.call("cancel_active")
    for _i in range(3):
        await tree.process_frame

    if not bool(minigame_runtime.call("start_minigame", "rune_puzzle")):
        _fail(20, "rune minigame did not start")
        return
    for _i in range(4):
        await tree.process_frame
    if not tree.paused:
        _fail(21, "runtime stability guard cancelled the intentional rune-puzzle pause")
        return
    minigame_runtime.call("cancel_active")
    for _i in range(3):
        await tree.process_frame
    if tree.paused:
        _fail(22, "rune-puzzle cancellation did not restore unpaused gameplay")
        return

    var dungeon_result: Dictionary = ProgressionSystem.start_dungeon("H")
    if not bool(dungeon_result.get("ok", false)):
        _fail(23, "dungeon transition failed: %s" % dungeon_result)
        return
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if not _assert_suspended(streamer, "dungeon", 24):
        return
    if not bool(player.get("instanced_world_mode")):
        _fail(28, "player did not enter instanced-world recovery mode in dungeon")
        return

    dungeon_runtime.call("abort_current_dungeon")
    for _i in range(TRANSITION_FRAMES):
        await tree.process_frame
    if bool(streamer.get("streaming_suspended")) or _loaded_count(streamer) <= 0:
        _fail(29, "mainland streaming did not resume after dungeon exit")
        return

    if bool(player.get("instanced_world_mode")):
        _fail(30, "player remained in instanced-world mode after dungeon exit")
        return

    print("OFFWORLD_STREAMING_SMOKE_OK realm=suspended dungeon=suspended mainland=resumed fall_recovery=realm rune_pause=stable transition_guards=active")
    tree.quit(0)
