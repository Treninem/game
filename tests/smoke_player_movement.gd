extends SceneTree

const MIN_DISTANCE := 0.75
const WARMUP_FRAMES := 20
const MOVE_FRAMES := 45
const RECOVERY_FRAMES := 32
const SURFACE_TOLERANCE := 0.70
const VOID_DROP := 25.0

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

    if not _assert_surface_under_player(player, "spawn"):
        quit(5)
        return

    var spawn_xz := Vector2(player.global_position.x, player.global_position.z)
    var spawn_terrain_y := WorldData.elevation_at(spawn_xz)
    if player.global_position.y < spawn_terrain_y - 0.10 or player.global_position.y > spawn_terrain_y + SURFACE_TOLERANCE:
        push_error("Movement smoke failed: player did not spawn on terrain; player_y=%s terrain_y=%s" % [player.global_position.y, spawn_terrain_y])
        quit(6)
        return

    # Reproduce the old regression deliberately: place the body deep below the
    # authoritative surface and prove that runtime recovery returns it to world.
    var before_void := player.global_position
    player.global_position.y = spawn_terrain_y - VOID_DROP
    player.velocity = Vector3(0.0, -20.0, 0.0)
    for _i in range(RECOVERY_FRAMES):
        await physics_frame

    var recovered_xz := Vector2(player.global_position.x, player.global_position.z)
    var recovered_terrain_y := WorldData.elevation_at(recovered_xz)
    print("Void recovery smoke: before=", before_void, " recovered=", player.global_position, " terrain_y=", recovered_terrain_y)
    if player.global_position.y < recovered_terrain_y - 0.10:
        push_error("Movement smoke failed: player remained below world after void recovery")
        quit(7)
        return
    if recovered_xz.distance_to(Vector2(before_void.x, before_void.z)) > 2.0:
        push_error("Movement smoke failed: void recovery moved player to an unrelated XZ")
        quit(8)
        return
    if not _assert_surface_under_player(player, "recovery"):
        quit(9)
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
    print("Movement + surface + void recovery smoke passed")
    quit(0)

func _assert_surface_under_player(player: CharacterBody3D, phase: String) -> bool:
    var from := player.global_position + Vector3.UP * 1.0
    var to := player.global_position + Vector3.DOWN * 3.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player.get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = false
    var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        push_error("Movement smoke failed: no physical world surface below player during %s" % phase)
        return false
    print("Surface smoke [", phase, "]: collider=", hit.get("collider"), " position=", hit.get("position"))
    return true
