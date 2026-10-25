extends SceneTree
const DATA:=preload("res://scripts/capital_canal_data.gd")
func _initialize()->void:call_deferred("_run")
func _run()->void:
    assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self))
    var saves:=root.get_node("SaveManager")
    var payload:Dictionary=saves._read_save(saves._slot_path(5))
    # Isolated legacy-in-air fixture. No original checkpoint is changed and
    # this is not an earned journey or a driver teleport in live gameplay.
    payload.player.position[1]=.8;payload.erase("world_geometry_revisions")
    assert(saves._write_atomic(saves._slot_path(5),saves._backup_path(5),payload))
    change_scene_to_file("res://scenes/world_loading.tscn")
    var player:CharacterBody3D;var center:Vector2=DATA.bridges()[1]
    var deadline:=Time.get_ticks_msec()+90000
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or Vector2(player.global_position.x,player.global_position.z).distance_to(center)>.2:
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec()>deadline:push_error("Legacy airborne fixture did not load its actual saved position");quit(1);return
    assert(player.global_position.y>=DATA.BRIDGE_DECK_TOP,"Old mid-jump save remains embedded below the new bridge and cannot acquire support")
    while player.ground_guard_active or not bool(current_scene.startup_state_ready) or not player.is_on_floor():
        await physics_frame
        if Time.get_ticks_msec()>deadline:push_error("Legacy airborne bridge guard never acquired the real deck");quit(1);return
    assert(absf(player.global_position.y-DATA.BRIDGE_DECK_TOP)<.1)
    var state:=root.get_node("GameState")
    assert(state.coins==int(payload.game_state.coins))
    for item:String in payload.game_state.inventory:assert(int(state.inventory[item])==int(payload.game_state.inventory[item]))
    print("CANAL_LEGACY_AIRBORNE_OK old_jump_height=.8 actual_scene_load=true new_deck_supported=true xz_inventory_money_preserved=true explicit_migration_fixture=true")
    quit(0)
