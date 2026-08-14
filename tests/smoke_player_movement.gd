extends SceneTree

const MIN_DISTANCE := 0.75
const WARMUP_FRAMES := 45
const MOVE_FRAMES := 45
const RECOVERY_FRAMES := 45
const SURFACE_TOLERANCE := 0.70
const VOID_DROP := 25.0

func _initialize() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Player surface smoke::%s" % clean)
    push_error("Movement smoke failed: %s" % message)
    quit(code)

func _run_test() -> void:
    var world_data := root.get_node_or_null("WorldData")
    if world_data == null:
        _fail(12, "WorldData autoload node is missing from standalone test tree")
        return

    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "main stage scene could not be loaded")
        return

    var scene := packed.instantiate()
    root.add_child(scene)
    for _i in range(WARMUP_FRAMES):
        await physics_frame

    var player := scene.get_node_or_null("World/Player") as CharacterBody3D
    if player == null:
        _fail(3, "player node missing")
        return

    if bool(player.get("ground_guard_active")):
        _fail(10, "spawn guard never acquired a real physical surface")
        return
    if not _assert_surface_under_player(player, world_data, "spawn"):
        _fail(5, "no physical world surface below player at spawn")
        return

    var spawn_xz := Vector2(player.global_position.x, player.global_position.z)
    var spawn_terrain_y := float(world_data.call("elevation_at", spawn_xz))
    if player.global_position.y < spawn_terrain_y - 0.10 or player.global_position.y > spawn_terrain_y + SURFACE_TOLERANCE:
        _fail(6, "player spawn height is outside terrain tolerance; player_y=%s terrain_y=%s" % [player.global_position.y, spawn_terrain_y])
        return

    var before_void := player.global_position
    player.global_position.y = spawn_terrain_y - VOID_DROP
    player.velocity = Vector3(0.0, -20.0, 0.0)
    for _i in range(RECOVERY_FRAMES):
        await physics_frame

    var recovered_xz := Vector2(player.global_position.x, player.global_position.z)
    var recovered_terrain_y := float(world_data.call("elevation_at", recovered_xz))
    print("Void recovery smoke: before=", before_void, " recovered=", player.global_position, " terrain_y=", recovered_terrain_y)
    if bool(player.get("ground_guard_active")):
        _fail(11, "void recovery returned to coordinates but never reacquired physical ground")
        return
    if player.global_position.y < recovered_terrain_y - 0.10:
        _fail(7, "player remained below world after void recovery")
        return
    if recovered_xz.distance_to(Vector2(before_void.x, before_void.z)) > 2.0:
        _fail(8, "void recovery moved player to unrelated XZ; distance=%s" % recovered_xz.distance_to(Vector2(before_void.x, before_void.z)))
        return
    if not _assert_surface_under_player(player, world_data, "recovery"):
        _fail(9, "no physical world surface below player after void recovery")
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
        _fail(4, "player walked in place after surface recovery; distance=%s" % distance)
        return
    print("Movement + surface + void recovery smoke passed")
    quit(0)

func _assert_surface_under_player(player: CharacterBody3D, world_data: Node, phase: String) -> bool:
    var xz := Vector2(player.global_position.x, player.global_position.z)
    var terrain_y := float(world_data.call("elevation_at", xz))
    var from := player.global_position + Vector3.UP * 1.0
    var to := Vector3(player.global_position.x, minf(player.global_position.y - 0.2, terrain_y - 2.5), player.global_position.z)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player.get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = false
    var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return false
    print("Surface smoke [", phase, "]: collider=", hit.get("collider"), " position=", hit.get("position"), " terrain_y=", terrain_y)
    return true
