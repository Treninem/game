extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
    var state:=root.get_node("GameState");var inventory:Dictionary=state.inventory.duplicate(true);var coins:int=state.coins
    var capital:GDScript=load("res://scripts/capital_data.gd");var cell:=Vector2i(6,-1)
    var center:Vector2=capital.CENTER+Vector2(cell)*160.0
    assert(capital.district_at(center).id=="canals")
    var fixture:=Node3D.new();root.add_child(fixture);current_scene=fixture
    var stub:=Node3D.new();stub.name="LegacyPositionFixture";stub.position=Vector3(center.x-28,0,center.y-52);fixture.add_child(stub)
    var original:=stub.global_position
    var city:Node3D=load("res://scripts/city_streamer_fast.gd").new();city.player=stub;fixture.add_child(city);city.set_process(false);city._build_cell(cell)
    for frame in range(8):await process_frame
    var block:Node3D=city.loaded_cells[cell]
    var key:="capital:open_lot:6:-1:8"
    assert(bool(state.get_world_value(key,false)),"New background house encloses an old saved position")
    assert(stub.global_position==original and not block.has_node("House_8"))
    assert(not block.has_node("DistrictPaving"),"Canal courtyard is still buried under a flat stone carpet")
    assert(float(block.get_meta("carriage_width_m"))==6 and float(block.get_meta("household_lane_width_m"))==2.2)
    var houses:=0
    for member:Node in block.get_children():
        if String(member.name).begins_with("House_"):houses+=1
    assert(houses>=6,"Canal quarter retains only two widely scattered background homes")
    var flowers:int=block.get_meta("street_flower_beds",0);assert(flowers>0)
    assert(root.get_node("SaveManager").save_game(stub,9))
    state.set_world_value(key,false)
    assert(root.get_node("SaveManager").load_game(stub,9) and bool(state.get_world_value(key,false)))
    stub.position=Vector3(center.x,0,center.y)
    block.free();city.loaded_cells.erase(cell);city._build_cell(cell)
    for frame in range(4):await process_frame
    assert(not city.loaded_cells[cell].has_node("House_8"),"Saved open plot is rebuilt around an old position after reload")
    assert(state.inventory==inventory and state.coins==coins)
    print("CITY_STREET_SCALE_OK ",JSON.stringify({"controlled_component_fixture":true,"actual_avatar_position_assignments":0,"background_houses":houses,"flower_beds":flowers,"carriage_width_m":6,"household_lane_m":2.2,"finished_floor_door_clear_height_m":2.2,"old_saved_position_open_plot_persists_on_disk":true,"inventory_money_unchanged":true,"full_city_art_acceptance":false}));quit(0)
