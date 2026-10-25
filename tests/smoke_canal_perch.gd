extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
    var state:=root.get_node("GameState");state.world_minutes=22*60
    var data:GDScript=load("res://scripts/capital_canal_data.gd")
    var fixture:=Node3D.new();fixture.position=Vector3(data.bridges()[1].x,0,data.bridges()[1].y);root.add_child(fixture);current_scene=fixture
    var ground:=StaticBody3D.new();var floor:=CollisionShape3D.new();var floor_shape:=BoxShape3D.new();floor_shape.size=Vector3(180,.1,30);floor.shape=floor_shape;ground.position.y=-.05;ground.add_child(floor);fixture.add_child(ground)
    load("res://scripts/capital_canals.gd").bridge(fixture,data.bridges()[1])
    var nav:Node3D=load("res://scripts/public_space_navigation.gd").new();nav.name="PublicSpaceNavigation";nav.lower_bound=Vector2(-60,-12);nav.upper_bound=Vector2(60,12);nav.set_meta("commute_navigation",true);fixture.add_child(nav)
    var deadline:=Time.get_ticks_msec()+75000
    while not nav.grid_ready:
        await physics_frame
        if Time.get_ticks_msec()>deadline:push_error("Perch fixture grid timeout");quit(1);return
    var rows:Array=[]
    for height:float in [160,180,200]:
        for side:float in [1,-1]:
            var identity:="perch:fixture:"+str(height)+str(side)
            state.set_world_value("appearance:"+identity,{"sex":"female","height_cm":height})
            var npc:CharacterBody3D=load("res://scripts/settlement_npc.gd").new();npc.name="PerchedCitizen";npc.role="resident";npc.autonomous=true;npc.body_sex="female"
            npc.set_meta("citizen_id",identity);npc.set_meta("routine_places",{"home":Vector3(-55*side,0,0)})
            npc.position=Vector3(0,2.24,0);fixture.add_child(npc)
            for frame in range(8):await physics_frame
            # Exact observed server pose, mirrored as a controlled diagnostic.
            # This single setup assignment is not a recovery implementation.
            var start:=Vector3(36.51758*side,1.97715,-7.804199*side)
            npc.position=start;npc.velocity=Vector3.ZERO;npc.ground_ready=true
            var maximum_drop:=0.;var previous:=npc.position.y;var travelled:=0.;var previous_position:=npc.position;var recovered:=false
            for frame in range(480):
                await physics_frame
                maximum_drop=maxf(maximum_drop,previous-npc.position.y);previous=npc.position.y
                travelled+=Vector2(npc.position.x-previous_position.x,npc.position.z-previous_position.z).length();previous_position=npc.position
                var expected:float=data.deck_height(npc.position.x)
                if Vector2(npc.position.x-start.x,npc.position.z-start.z).length()>1 and absf(npc.position.y-expected)<.12 and npc.is_on_floor():recovered=true;break
            print("PERCH_SAMPLE height=",height," side=",side," position=",npc.position," floor=",npc.is_on_floor()," floor_normal=",npc.get_floor_normal()," max_drop=",maximum_drop," travelled=",travelled)
            assert(recovered,"Citizen remains perched above the navigable bridge deck")
            assert(maximum_drop<.16,"Perch recovery teleported height instead of falling with physics")
            rows.append({"height_cm":height,"side":side,"ordinary_speed":npc.move_speed,"setup_position_assignments":1,"maximum_frame_drop_m":maximum_drop,"walked_m":travelled})
            npc.queue_free();await process_frame
    var file:=FileAccess.open("user://canal-perch.json",FileAccess.WRITE);file.store_string(JSON.stringify({"controlled_physics_fixture":true,"actual_bridge_geometry":true,"rendered_visual_acceptance":false,"cases":rows},"  "));file.close()
    print("CANAL_PERCH_OK ",JSON.stringify(rows));quit(0)
