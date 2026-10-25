extends RefCounted

static func ensure_legacy_checkpoint(tree:SceneTree)->bool:
    var saves:=tree.root.get_node("SaveManager")
    if OS.get_environment("IMPULS_CANAL_CONTROLLED_FIXTURE")!="1":return saves.prepare_load(5)
    var state:=tree.root.get_node("GameState")
    state.inventory=state.DEFAULT_INVENTORY.duplicate(true)
    state.inventory.berries=11;state.inventory.water_flask=9;state.inventory.wood=0;state.inventory.stone=0
    state.coins=20;state.world_minutes=9*60;state.set_world_value("current_realm","main")
    var bridge:Vector2=preload("res://scripts/capital_canal_data.gd").bridges()[1]
    var payload:={"save_version":6,"slot":5,"player":{"position":[bridge.x,0.,bridge.y],"rotation_y":0.},"game_state":state.snapshot()}
    assert(saves._write_atomic(saves._slot_path(5),saves._backup_path(5),payload))
    print("CANAL_CONTROLLED_LEGACY_FIXTURE not_earned_arrival=true ci_only=true")
    return saves.prepare_load(5)
