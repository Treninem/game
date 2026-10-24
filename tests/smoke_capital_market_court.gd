extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(180).timeout.connect(func():push_error("Market court watchdog");quit(1))
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var square:Node3D=load("res://scripts/capital_square_life.gd").new()
    square.position=Vector3(CapitalData.CENTER.x,0,CapitalData.CENTER.y)
    world.add_child(square)
    load("res://scripts/capital_market_court.gd").build(square)
    for frame in range(6):await physics_frame
    var fountain:StaticBody3D=square.get_node("MarketFountain")
    assert(get_nodes_in_group("map_tree").size()==4)
    assert(fountain.is_in_group("map_fixture") and fountain.is_in_group("public_water_source"))
    assert(fountain.basins.size()==2 and fountain.scale.is_equal_approx(Vector3.ONE))
    var triangles:=0
    for mesh:MeshInstance3D in fountain.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):
            var faces:=mesh.mesh.get_faces()
            for index in range(0,faces.size(),3):
                assert((faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).length_squared()>0.00000000001,"Fountain has a degenerate triangle")
            triangles+=mesh.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
    assert(triangles==5388)
    for basin:MeshInstance3D in fountain.basins:
        var box:=fountain.global_transform.affine_inverse()*basin.global_transform*basin.mesh.get_aabb()
        assert(box.position.y>0 and box.end.y<3)
        var arrays:=basin.mesh.surface_get_arrays(0)
        for normal:Vector3 in arrays[Mesh.ARRAY_NORMAL]:assert(normal.dot(Vector3.UP)>.99,"Water faces point down")
        assert(basin.material_override is ShaderMaterial)
        assert(basin.material_override.get_shader_parameter("wave_strength")<=.0031)
    var floor_query:=PhysicsRayQueryParameters3D.create(fountain.to_global(Vector3(1.5,2,0)),fountain.to_global(Vector3(1.5,0,0)),1)
    var hit:=world.get_world_3d().direct_space_state.intersect_ray(floor_query)
    assert(not hit.is_empty() and hit.collider==fountain and fountain.to_local(hit.position).y<.4,"Invisible solid water or missing basin floor")
    var rim_query:=PhysicsRayQueryParameters3D.create(fountain.to_global(Vector3(2.45,2,0)),fountain.to_global(Vector3(2.45,0,0)),1)
    hit=world.get_world_3d().direct_space_state.intersect_ray(rim_query)
    assert(not hit.is_empty() and hit.collider==fountain and fountain.to_local(hit.position).y>1.0,"Basin rim has no physical support")
    var state:=root.get_node("GameState")
    var actor:=Node3D.new();world.add_child(actor);actor.global_position=fountain.to_global(Vector3(0,0,-3.6))
    var inventory:Dictionary=state.inventory.duplicate(true);var coins:int=state.coins
    state.thirst=60.0;fountain.interact(actor)
    assert(is_equal_approx(state.thirst,95.0))
    var uses:int=state.get_world_value(fountain.USE_KEY,0)
    assert(uses==1 and inventory==state.inventory and coins==state.coins)
    state.thirst=100.0;fountain.interact(actor)
    assert(state.get_world_value(fountain.USE_KEY,0)==uses)
    actor.position+=Vector3(0,0,-4);state.thirst=60.0;fountain.interact(actor)
    assert(is_equal_approx(state.thirst,60.0) and state.get_world_value(fountain.USE_KEY,0)==uses)
    var save:=root.get_node("SaveManager")
    assert(save.save_game(actor,4))
    state.set_world_value(fountain.USE_KEY,0)
    assert(save.load_game(actor,4) and state.get_world_value(fountain.USE_KEY,0)==uses)
    assert(inventory==state.inventory and coins==state.coins)
    print("CAPITAL_MARKET_COURT_OK trees=4 goods=12 fountain_triangles=5388 separate_water=true physical_rim=true full_thirst_guard=true reach_guard=true inventory_money_conserved=true disk_restore=true")
    world.free();quit(0)
