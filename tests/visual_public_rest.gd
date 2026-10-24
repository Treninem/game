extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(240).timeout.connect(func():push_error("PUBLIC_REST_GPU watchdog");quit(1))
    var state:=root.get_node("GameState");state.world_minutes=9*60
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var ground:=StaticBody3D.new();world.add_child(ground)
    var ground_shape:=CollisionShape3D.new();var floor_box:=BoxShape3D.new();floor_box.size=Vector3(100,.2,110);ground_shape.shape=floor_box;ground_shape.position=Vector3(CapitalData.CENTER.x,-.075,CapitalData.CENTER.y+10);ground.add_child(ground_shape)
    var square:Node3D=load("res://scripts/capital_square_life.gd").new();square.position=Vector3(CapitalData.CENTER.x,0,CapitalData.CENTER.y);world.add_child(square)
    load("res://scripts/capital_market_court.gd").build(square)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-30,0);world.add_child(sun)
    var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.65;world.add_child(environment)
    var camera:=Camera3D.new();world.add_child(camera);camera.position=square.to_global(Vector3(-5,2,8));camera.look_at(square.to_global(Vector3(-10,1,14)));camera.make_current()
    var trader:CharacterBody3D=square.get_node("SquareTrader");var artisan:CharacterBody3D=square.get_node("SquareArtisan")
    state.world_minutes=12*60
    while trader.get_meta("activity","")!="sit" or artisan.get_meta("activity","")!="sit":await physics_frame
    var samples:Array=[]
    for npc in [trader,artisan]:
        assert(npc.has_meta("rest_collision_snapshot"),"Visible seated citizen still has the standing collider")
        var boots:MeshInstance3D=npc.visual.find_child("Boots",true,false)
        var capture:RefCounted=load("res://tests/gpu_skinned_vertex_probe.gd").new();capture.setup(root,boots,0)
        await capture.calibrate();capture.begin_capture();await process_frame;await RenderingServer.frame_post_draw
        var vertices:PackedVector3Array=capture.finish_capture();assert(vertices.size()==3530)
        var minimum:=INF
        for point:Vector3 in vertices:minimum=minf(minimum,boots.to_global(point).y)
        var gap:=minimum-.025
        assert(gap>=-.02 and gap<=.04,"Actual seated citizen GPU soles do not meet paving: "+str(gap))
        var support:RefCounted=npc.visual.find_child("ClothingClearance",true,false).seated_support
        assert(support!=null and support.contacts.size()==2,"Both seated feet are not supported by the final citizen modifier")
        samples.append({"citizen":npc.citizen_id,"boot_vertices":vertices.size(),"gap":gap,"contacts":support.contacts})
        capture.dispose()
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png("user://public-rest-gpu.png")==OK)
    var report:=FileAccess.open("user://public-rest-gpu.json",FileAccess.WRITE);report.store_string(JSON.stringify(samples,"  "));report.close()
    print("PUBLIC_REST_GPU_OK actors=2 boot_vertices=7060 final_npc_modifier=true measured_paving=true")
    world.free();quit(0)
