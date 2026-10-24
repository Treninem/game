extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(240).timeout.connect(func():push_error("PUBLIC_MARKET_LIFE watchdog");quit(1))
    var state:=root.get_node("GameState");state.world_minutes=9*60
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var ground:=StaticBody3D.new();world.add_child(ground)
    var ground_shape:=CollisionShape3D.new();var floor_box:=BoxShape3D.new();floor_box.size=Vector3(100,.2,110);ground_shape.shape=floor_box;ground_shape.position=Vector3(CapitalData.CENTER.x,-.075,CapitalData.CENTER.y+10);ground.add_child(ground_shape)
    var square:Node3D=load("res://scripts/capital_square_life.gd").new();square.position=Vector3(CapitalData.CENTER.x,0,CapitalData.CENTER.y);world.add_child(square)
    load("res://scripts/capital_market_court.gd").build(square)
    var quality:int=root.get_node("SettingsManager").get_value("graphics","quality_preset")
    var arcade_mounts:=square.get_node("MarketArcade").find_children("LanternMount*","Node3D",true,false)
    assert(arcade_mounts.size()==2,"Authored arcade lost its two actual Blender mounts")
    state.world_minutes=20*60
    for preset:int in [0,1]:
        root.get_node("SettingsManager").set_quality_preset(preset)
        square._process(1.1)
        var checked_lights:=0
        var checked_street:=0
        var occupied_mounts:Dictionary={}
        for lamp:OmniLight3D in square.lamps:
            if lamp.get_meta("medium_only",false):
                assert(lamp.visible==(preset>=1) and not lamp.shadow_enabled)
                # Quality policy is not fixture identity. Locate the original
                # arcade lights by actual Blender mounts, including uniqueness.
                var anchor_id:=0
                for mount:Node3D in arcade_mounts:
                    var expected:=square.to_local(mount.global_position)+Vector3(0,.25,.15)
                    if lamp.position.distance_to(expected)<.003:anchor_id=mount.get_instance_id();break
                if anchor_id!=0:
                    assert(not occupied_mounts.has(anchor_id),"Two arcade lamps share one measured mount")
                    occupied_mounts[anchor_id]=true
                    checked_lights+=1
                else:
                    assert(String(lamp.name).begins_with("StreetPostLight_") and lamp.omni_range<=5.5,"Unknown optional light is not an authored street post")
                    checked_street+=1
        assert(checked_lights==2,"Arcade lanterns lost their measured mounts")
        assert(checked_street==4,"Authored street lights lost coverage")
    root.get_node("SettingsManager").set_quality_preset(quality);state.world_minutes=9*60
    var nav:Node=square.get_node("PublicSpaceNavigation")
    while not nav.grid_ready:await physics_frame
    var path_start:Vector2i=nav._nearest(nav._cell(Vector3(-10,0,-2)))
    var path_finish:Vector2i=nav._nearest(nav._cell(Vector3(-10,0,7)))
    var original_path: Array[Vector2i]=nav.grid.get_id_path(path_start,path_finish)
    var obstacle:=StaticBody3D.new();obstacle.position=square.to_global(Vector3(-10,1.025,3));world.add_child(obstacle)
    var obstacle_collision:=CollisionShape3D.new();var obstacle_box:=BoxShape3D.new();obstacle_box.size=Vector3(3,2,3);obstacle_collision.shape=obstacle_box;obstacle.add_child(obstacle_collision)
    for frame in range(2):await physics_frame
    assert(not nav.grid_ready,"New nearby geometry did not invalidate public navigation")
    while not nav.grid_ready:await physics_frame
    assert(nav.grid.get_id_path(path_start,path_finish).size()>original_path.size(),"Public route did not detour around the actual new obstacle")
    obstacle.queue_free()
    for frame in range(2):await physics_frame
    assert(not nav.grid_ready,"Removed geometry did not invalidate public navigation")
    while not nav.grid_ready:await physics_frame
    assert(nav.grid.get_id_path(path_start,path_finish).size()==original_path.size())
    assert(get_nodes_in_group("public_rest_furniture").size()==6)
    var arcade:StaticBody3D=square.get_node("MarketArcade")
    assert(arcade.scale.is_equal_approx(Vector3.ONE) and arcade.get_node("MeasuredStructureCollision").shape is ConcavePolygonShape3D)
    var triangles:=0
    for mesh:MeshInstance3D in arcade.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):triangles+=mesh.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
    assert(triangles==32322)
    var excluded:Array[RID]=[]
    for npc:CollisionObject3D in get_nodes_in_group("settlement_npc"):excluded.append(npc.get_rid())
    var roof_query:=PhysicsRayQueryParameters3D.create(arcade.to_global(Vector3(4.5,10,2)),arcade.to_global(Vector3(4.5,1,2)),1,excluded)
    var hit:=world.get_world_3d().direct_space_state.intersect_ray(roof_query)
    assert(not hit.is_empty() and hit.collider==arcade and arcade.to_local(hit.position).y>7.2,"Arcade roof is not solid at the selected ridge")
    var open_query:=PhysicsRayQueryParameters3D.create(arcade.to_global(Vector3(6,1.8,-5)),arcade.to_global(Vector3(6,1.8,5)),1,excluded)
    assert(world.get_world_3d().direct_space_state.intersect_ray(open_query).is_empty(),"Arcade has a closed invisible room box")
    var stalls:=get_nodes_in_group("capital_square_stall")
    assert(stalls.size()==2)
    assert(stalls[0].get_node("MeasuredStructureCollision").shape==stalls[1].get_node("MeasuredStructureCollision").shape,"Identical normalized counters do not share their structural shape")
    var counter:StaticBody3D=stalls[0]
    var gap_query:=PhysicsRayQueryParameters3D.create(counter.to_global(Vector3(0,1.55,-2)),counter.to_global(Vector3(0,1.55,2)),1,excluded)
    assert(world.get_world_3d().direct_space_state.intersect_ray(gap_query).is_empty(),"Counter still has an invisible wall above its tabletop")
    var trader:CharacterBody3D=square.get_node("SquareTrader");var artisan:CharacterBody3D=square.get_node("SquareArtisan")
    var walked:={trader.name:0.0,artisan.name:0.0}
    state.world_minutes=12*60
    for frame in range(6500):
        var before_a:=trader.global_position;var before_b:=artisan.global_position
        await physics_frame
        walked[trader.name]+=before_a.distance_to(trader.global_position);walked[artisan.name]+=before_b.distance_to(artisan.global_position)
        if trader.get_meta("activity","")=="sit" and artisan.get_meta("activity","")=="sit":break
        if frame==6499:
            push_error("Public residents did not reach seats: %s / %s"%[trader.global_position,artisan.global_position]);quit(1);return
    assert(trader.used_furniture!=artisan.used_furniture and trader.used_furniture.is_in_group("public_rest_furniture") and artisan.used_furniture.is_in_group("public_rest_furniture"))
    assert(trader.is_on_floor() and artisan.is_on_floor())
    assert(trader.visual.top_level and artisan.visual.top_level)
    for frame in range(180):await physics_frame
    var a:Dictionary=state.get_world_value("public_rest:"+trader.citizen_id,{})
    var b:Dictionary=state.get_world_value("public_rest:"+artisan.citizen_id,{})
    assert(a.seat!=b.seat and float(a.seated_seconds)>1 and float(b.seated_seconds)>1)
    var actor:=Node3D.new();world.add_child(actor);actor.global_position=square.to_global(Vector3(0,0,4))
    assert(root.get_node("SaveManager").save_game(actor,4))
    state.set_world_value("public_rest:"+trader.citizen_id,{})
    assert(root.get_node("SaveManager").load_game(actor,4))
    assert(state.get_world_value("public_rest:"+trader.citizen_id,{}).seat==a.seat)
    state.world_minutes=9*60
    for frame in range(6500):
        await physics_frame
        var trader_goal:Vector3=square.to_global(trader.get_meta("routine_places").work)
        var artisan_goal:Vector3=square.to_global(artisan.get_meta("routine_places").work)
        if Vector2(trader.global_position.x-trader_goal.x,trader.global_position.z-trader_goal.z).length()<.35 and Vector2(artisan.global_position.x-artisan_goal.x,artisan.global_position.z-artisan_goal.z).length()<.35:break
        if frame==6499:
            push_error("Residents could not leave public benches and return to real workplaces: %s / %s"%[trader.global_position,artisan.global_position]);quit(1);return
    assert(not trader.visual.top_level and not artisan.visual.top_level)
    for bench in get_nodes_in_group("public_rest_furniture"):assert(bench.occupant.is_empty())
    state.world_minutes=18*60
    for frame in range(6500):
        await physics_frame
        if trader.get_meta("activity","")=="sit" and artisan.get_meta("activity","")=="sit":break
        if frame==6499:
            push_error("Residents did not reach public evening seats");quit(1);return
    assert(trader.used_furniture!=artisan.used_furniture)
    assert(trader.visual.global_position.distance_to(artisan.visual.global_position)<4,"Evening seats do not allow an actual nearby conversation")
    print("PUBLIC_MARKET_LIFE_OK arcade_triangles=32322 counters_shared=true counter_gap=true automatic_obstacle_rebuild=true ordinary_npc_movement=true exclusive_seats=true physical_support=true state_disk_restore=true return_to_work=true evening_social=true walked=",walked)
    world.free();quit(0)
