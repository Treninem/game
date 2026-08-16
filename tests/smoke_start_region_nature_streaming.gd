extends Node

const START_REGION_STREAMER := preload("res://scripts/start_region_streamer.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const MAX_DETAIL_CELLS := 25

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Start-region nature smoke::%s" % clean)
    push_error("Start-region nature smoke: %s" % message)
    get_tree().quit(code)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _run_test() -> void:
    var player := CharacterBody3D.new()
    player.name = "NatureStreamingTestPlayer"
    player.add_to_group("player")
    player.position = Vector3(GEOGRAPHY.START_SPAWN.x, 3.0, GEOGRAPHY.START_SPAWN.y)
    add_child(player)

    var streamer := START_REGION_STREAMER.new() as Node3D
    if streamer == null:
        _fail(2, "start-region streamer could not be instantiated")
        return
    streamer.name = "StartRegionStreamerUnderTest"
    add_child(streamer)

    await _wait_frames(38)
    var first_center: Vector2i = streamer.call("detail_center_cell")
    var first_cells := int(streamer.call("loaded_detail_cell_count"))
    if first_cells <= 0 or first_cells > MAX_DETAIL_CELLS:
        _fail(3, "initial detail-cell budget invalid: %d" % first_cells)
        return
    if int(streamer.get("real_tree_count")) <= 0 or int(streamer.get("real_nature_detail_count")) <= 0:
        _fail(4, "production nature did not materialize around the start spawn")
        return

    player.position = Vector3(1000.0, 3.0, 800.0)
    await _wait_frames(38)
    var moved_center: Vector2i = streamer.call("detail_center_cell")
    var moved_cells := int(streamer.call("loaded_detail_cell_count"))
    if moved_center == first_center:
        _fail(5, "detail streamer did not follow player movement")
        return
    if moved_cells <= 0 or moved_cells > MAX_DETAIL_CELLS:
        _fail(6, "moving detail-cell budget invalid: %d" % moved_cells)
        return
    if int(streamer.get("real_nature_detail_count")) <= 0:
        _fail(7, "near-field production nature disappeared while still inside start region")
        return

    player.position = Vector3(3000.0, 3.0, 3000.0)
    await _wait_frames(4)
    if int(streamer.call("loaded_detail_cell_count")) != 0:
        _fail(8, "detail cells were retained after leaving the start region")
        return
    if int(streamer.get("real_tree_count")) != 0 or int(streamer.get("real_nature_detail_count")) != 0:
        _fail(9, "detail counters did not clear after leaving the start region")
        return

    player.position = Vector3(GEOGRAPHY.START_SPAWN.x, 3.0, GEOGRAPHY.START_SPAWN.y)
    await _wait_frames(32)
    var rebuilt_cells := int(streamer.call("loaded_detail_cell_count"))
    if rebuilt_cells <= 0 or rebuilt_cells > MAX_DETAIL_CELLS:
        _fail(10, "detail streamer did not rebuild within budget after re-entering")
        return
    if int(streamer.get("real_nature_detail_count")) <= 0:
        _fail(11, "production nature did not rebuild after re-entering")
        return

    print("Start-region nature smoke passed: production detail follows player, stays bounded and unloads outside region")
    get_tree().quit(0)
