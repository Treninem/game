extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const MIN_DISTANCE := 0.75
const WARMUP_FRAMES := 60
const MOVE_FRAMES := 45
const RECOVERY_FRAMES := 45
const SURFACE_TOLERANCE := 0.70
const VOID_DROP := 25.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Player runtime smoke::%s" % clean)
    push_error("Movement smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var tree := get_tree()
    var world_data := get_node_or_null("/root/WorldData")
    if world_data == null:
        _fail(12, "WorldData autoload node is missing from normal project tree")
        return

    var packed := load("res://scenes/stage1.tscn") as PackedScene
    if packed == null:
        _fail(2, "main stage scene could not be loaded")
        return

    var scene := packed.instantiate()
    tree.root.add_child(scene)
    for _i in range(WARMUP_FRAMES):
        await tree.physics_frame

    var player := scene.get_node_or_null("World/Player") as CharacterBody3D
    if player == null:
        _fail(3, "player node missing")
        return

    if bool(player.get("ground_guard_active")):
        _fail(10, "spawn guard never acquired a physical surface")
        return
    if not _assert_surface_under_player(player, world_data, "spawn"):
        _fail(5, "no physical world surface below player at spawn")
        return

    if not _assert_story_start_world(scene, world_data, player):
        _fail(13, "story start is not the required Asterna forest river region")
        return
    if not _assert_hud(scene):
        _fail(14, "gameplay HUD/minimap/quickbar is missing or outside the viewport")
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
        await tree.physics_frame

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

    var physical_w := _physical_key_event(KEY_W, true)
    if not physical_w.is_action_pressed("move_forward"):
        _fail(15, "physical W is not mapped to move_forward")
        return

    var start := Vector2(player.global_position.x, player.global_position.z)
    Input.action_press("move_forward", 1.0)
    for _i in range(MOVE_FRAMES):
        await tree.physics_frame
    Input.action_release("move_forward")
    await tree.physics_frame

    var finish := Vector2(player.global_position.x, player.global_position.z)
    var distance := start.distance_to(finish)
    print("Mapped-W movement smoke: start=", start, " finish=", finish, " distance=", distance)
    if distance < MIN_DISTANCE:
        _fail(4, "mapped move_forward leaves the player walking in place; distance=%s" % distance)
        return

    var menu := scene.get_node_or_null("UI/GameMenu") as Control
    if menu == null:
        _fail(16, "game menu node missing")
        return
    _send_physical_key(KEY_ESCAPE, true)
    _send_physical_key(KEY_ESCAPE, false)
    for _i in range(3):
        await tree.process_frame
    if not tree.paused or not menu.visible:
        _fail(17, "physical ESC did not open and pause the game menu")
        return

    _send_physical_key(KEY_ESCAPE, true)
    _send_physical_key(KEY_ESCAPE, false)
    for _i in range(3):
        await tree.process_frame
    if tree.paused or menu.visible:
        _fail(18, "second physical ESC did not close the menu and resume gameplay")
        return

    print("Forest river story start + physical key mapping + ESC + HUD + surface + void recovery smoke passed")
    tree.quit(0)

func _physical_key_event(code: Key, pressed: bool) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    event.echo = false
    return event

func _send_physical_key(code: Key, pressed: bool) -> void:
    Input.parse_input_event(_physical_key_event(code, pressed))

func _assert_story_start_world(scene: Node, world_data: Node, player: CharacterBody3D) -> bool:
    var spawn_xz := Vector2(player.global_position.x, player.global_position.z)
    var expected := GEOGRAPHY.START_SPAWN
    if spawn_xz.distance_to(expected) > 6.0:
        print("Story spawn mismatch: actual=", spawn_xz, " expected=", expected)
        return false
    if String(world_data.call("biome_at", spawn_xz)) != "forest":
        print("Story start biome is not forest")
        return false
    if String(world_data.call("state_id_at", spawn_xz)) != "astern":
        print("Story start political region is not Asterna")
        return false
    if GEOGRAPHY.distance_to_start_river(spawn_xz) > GEOGRAPHY.START_RIVER_BANK_WIDTH + 4.0:
        print("Story spawn is not on the river bank")
        return false
    if expected.distance_to(GEOGRAPHY.ASTERN_CAPITAL) < 8000.0:
        print("Asterna capital is not sufficiently far from the prologue spawn")
        return false

    var start_region := scene.get_node_or_null("World/StartRegion")
    if start_region == null:
        return false
    if start_region.get_node_or_null("StartRiver") == null or start_region.get_node_or_null("OldFord") == null:
        return false
    var river_count := int(start_region.get("river_segment_count"))
    var ford_count := int(start_region.get("ford_stone_count"))
    if river_count < 20 or ford_count < 8:
        print("Start region incomplete: river_segments=", river_count, " ford_stones=", ford_count)
        return false

    var city := scene.get_node_or_null("World/CityDistrict")
    if city == null:
        return false
    var loaded = city.get("loaded_cells")
    if not (loaded is Dictionary):
        return false
    if not loaded.is_empty():
        print("Capital cells incorrectly loaded at forest spawn: ", loaded.size())
        return false
    if scene.get_node_or_null("World/StoryStartSurface") == null:
        return false

    print("Story world smoke: spawn=", spawn_xz, " river_segments=", river_count, " ford_stones=", ford_count, " capital_distance=", expected.distance_to(GEOGRAPHY.ASTERN_CAPITAL))
    return true

func _assert_hud(scene: Node) -> bool:
    var hud := scene.get_node_or_null("UI/HUD") as Control
    if hud == null or not hud.visible:
        return false
    var available := hud.size
    if available.x < 100.0 or available.y < 100.0:
        return false
    for child_name in ["VitalsCard", "MinimapCard", "Quickbar"]:
        var control := hud.get_node_or_null(child_name) as Control
        if control == null or not control.visible:
            return false
        var rect := control.get_global_rect()
        if rect.position.x < -1.0 or rect.position.y < -1.0:
            return false
        if rect.end.x > available.x + 1.0 or rect.end.y > available.y + 1.0:
            print("HUD overflow: ", child_name, " rect=", rect, " available=", available)
            return false
    print("HUD runtime smoke: size=", available)
    return true

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
