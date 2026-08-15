extends Node3D

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    print("::error title=Settlement streaming smoke::%s" % message.replace("\n", " "))
    push_error("Settlement streaming smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var streamer := SETTLEMENTS_SCRIPT.new() as WorldSettlements
    streamer.name = "SettlementStreamingProbe"
    add_child(streamer)

    var fake_player := Node3D.new()
    fake_player.name = "StreamingProbePlayer"
    add_child(fake_player)
    streamer.player = fake_player
    await get_tree().process_frame

    var village_a: Dictionary = streamer.settlement_spec("border_village_01")
    var village_b: Dictionary = streamer.settlement_spec("border_village_02")
    var town: Dictionary = streamer.settlement_spec("first_fortified_town")
    if village_a.is_empty() or village_b.is_empty() or town.is_empty():
        _fail(2, "established settlement coordinates are unavailable")
        return

    _move_probe(fake_player, village_a.get("center", Vector2.ZERO))
    streamer._update_streaming()
    await get_tree().process_frame
    if streamer.loaded_settlement_count() != 1 or not streamer.loaded.has("border_village_01"):
        _fail(3, "approaching first village did not load exactly that settlement")
        return
    var first_root := streamer.loaded.get("border_village_01") as Node3D
    if _npc_count(first_root) != 5:
        _fail(4, "first village stream did not include its five NPCs")
        return

    _move_probe(fake_player, Vector2(65.0, 48.0))
    streamer._update_streaming()
    await get_tree().process_frame
    await get_tree().process_frame
    if streamer.loaded_settlement_count() != 0:
        _fail(5, "settlement stayed loaded beyond unload radius")
        return
    if is_instance_valid(first_root) and not first_root.is_queued_for_deletion():
        _fail(6, "unloaded village root and NPC population were not released")
        return

    _move_probe(fake_player, town.get("center", Vector2.ZERO))
    streamer._update_streaming()
    await get_tree().process_frame
    if streamer.loaded_settlement_count() != 1 or not streamer.loaded.has("first_fortified_town"):
        _fail(7, "approaching fortified town did not load exactly the town")
        return
    var town_root := streamer.loaded.get("first_fortified_town") as Node3D
    if _npc_count(town_root) != 10:
        _fail(8, "fortified town stream did not include ten residents/guards")
        return

    _move_probe(fake_player, village_b.get("center", Vector2.ZERO))
    streamer._update_streaming()
    await get_tree().process_frame
    await get_tree().process_frame
    if streamer.loaded_settlement_count() != 1 or not streamer.loaded.has("border_village_02"):
        _fail(9, "moving between distant settlements did not unload old town and load river village")
        return
    var second_root := streamer.loaded.get("border_village_02") as Node3D
    if _npc_count(second_root) != 5:
        _fail(10, "river village stream did not include its five NPCs")
        return
    if is_instance_valid(town_root) and not town_root.is_queued_for_deletion():
        _fail(11, "fortified town remained resident after player moved to distant village")
        return
    if streamer.materialized_npcs != 20:
        _fail(12, "streaming sequence should have created 20 NPC instances cumulatively; got %d" % streamer.materialized_npcs)
        return

    print("SETTLEMENT_STREAMING_SMOKE_OK max_loaded=1 sequence=village-town-village cumulative_npcs=", streamer.materialized_npcs)
    get_tree().quit(0)

func _move_probe(player: Node3D, world_pos: Vector2) -> void:
    player.global_position = Vector3(world_pos.x, WorldData.elevation_at(world_pos) + 0.1, world_pos.y)

func _npc_count(root: Node3D) -> int:
    if root == null:
        return 0
    var count := 0
    for child in root.get_children():
        if child is SettlementNPC:
            count += 1
    return count
