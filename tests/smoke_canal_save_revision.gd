extends SceneTree
const DATA:=preload("res://scripts/capital_canal_data.gd")

func _initialize()->void:call_deferred("_run")
func _run()->void:
    var saves:=root.get_node("SaveManager");var state:=root.get_node("GameState")
    var actor:=Node3D.new();root.add_child(actor)
    var bridge:Vector2=DATA.bridges()[1]
    var cases:Array=[]
    for bad:Variant in [null,{},[],"1",false,-1,0]:
        assert(not DATA.has_current_revision(bad))
        cases.append({"revisions":{"capital_canals":bad},"y":0.,"expected_y":2.28,"realm":"main"})
    for bad:Variant in [null,[],"bad",1]:
        cases.append({"revisions":bad,"y":0.,"expected_y":2.28,"realm":"main"})
    cases.append({"revisions":{"capital_canals":1},"y":-.9,"expected_y":-.9,"realm":"main"})
    cases.append({"revisions":{"capital_canals":1},"y":0.,"expected_y":0.,"realm":"main"})
    cases.append({"revisions":{},"y":0.,"expected_y":0.,"realm":"other"})
    cases.append({"revisions":{},"y":.8,"expected_y":2.28,"realm":"main"})
    cases.append({"revisions":{},"y":1.8,"expected_y":2.28,"realm":"main"})
    cases.append({"revisions":{},"y":2.8,"expected_y":2.8,"realm":"main"})
    assert(not DATA.has_current_revision(NAN) and not DATA.has_current_revision(INF))
    assert(DATA.has_current_revision(1) and DATA.has_current_revision(2))
    state.inventory=state.DEFAULT_INVENTORY.duplicate(true)
    state.inventory.berries=7;state.inventory.water_flask=4;state.inventory.wood=9;state.coins=137
    var inventory:Dictionary=state.inventory.duplicate(true)
    for sample:Dictionary in cases:
        state.set_world_value("current_realm",sample.realm)
        var payload:={"save_version":6,"slot":9,"world_geometry_revisions":sample.revisions,"player":{"position":[bridge.x,sample.y,bridge.y],"rotation_y":.7},"game_state":state.snapshot()}
        # Explicit isolated migration fixture, never an earned gameplay claim.
        assert(saves._write_atomic(saves._slot_path(9),saves._backup_path(9),payload))
        assert(saves.load_game(actor,9))
        assert(Vector2(actor.position.x,actor.position.z)==bridge and absf(actor.position.y-float(sample.expected_y))<.0001)
        assert(absf(actor.rotation.y-.7)<.0001 and state.inventory==inventory and state.coins==137)
    assert(DATA.supported_height(bridge,2.2,-1.2)==2.2)
    assert(DATA.supported_height(bridge,-.9,-1.2)==-1.2)
    assert(is_equal_approx(DATA.legacy_bridge_position(Vector3(bridge.x,-.8,bridge.y)).y,-.8))
    print("CANAL_SAVE_REVISION_OK cases=",cases.size()," new_underarch_not_raised=true malformed_legacy_metadata_safe=true xz_inventory_money_yaw_preserved=true fixture_explicit=true")
    quit(0)
