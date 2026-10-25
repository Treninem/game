extends SceneTree
const DATA:=preload("res://scripts/capital_canal_data.gd")
func _initialize()->void:call_deferred("_run")
func _run()->void:
    assert(DisplayServer.get_name()!="headless")
    create_timer(350).timeout.connect(func():push_error("CANAL_PERFORMANCE timeout");quit(1))
    assert(root.get_node("SaveManager").prepare_load(5))
    change_scene_to_file("res://scenes/world_loading.tscn")
    var player:CharacterBody3D
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or not bool(current_scene.get("startup_state_ready")) or player.ground_guard_active:
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
    current_scene.set_process(false)
    var state:=root.get_node("GameState");var settings:=root.get_node("SettingsManager")
    state.world_minutes=9*60
    var camera:=Camera3D.new();current_scene.add_child(camera)
    camera.global_position=Vector3(14645,4,-7102);camera.look_at(Vector3(14690,1,-7165));camera.fov=66;camera.make_current()
    var parks:=get_nodes_in_group("capital_canal_park");assert(not parks.is_empty())
    var grass_count:=0;var tree_count:=0
    for park:Node3D in parks:
        grass_count+=int(park.get_meta("authored_grass_instances"))
        for tree:Node3D in get_nodes_in_group("map_tree"):
            if park.is_ancestor_of(tree):tree_count+=1
    print("CANAL_PARK_COUNTS grass=",grass_count," trees=",tree_count," parks=",parks.size())
    assert(tree_count>=12 and grass_count>6000)
    var canals:GDScript=load("res://scripts/capital_canals.gd")
    var reports:Array=[]
    for quality:int in [0,1,2,3]:
        settings.set_quality_preset(quality)
        assert(canals.stone.normal_enabled==(quality>=2))
        for enabled:bool in [false,true]:
            for park:Node3D in parks:park.visible=enabled
            for frame in range(40):await process_frame;await RenderingServer.frame_post_draw
            var frames:Array[float]=[];var tick:=Time.get_ticks_usec()
            for frame in range(120):
                await process_frame;await RenderingServer.frame_post_draw
                var now:=Time.get_ticks_usec();frames.append(float(now-tick)/1000);tick=now
            var sum:=0.
            for duration:float in frames:sum+=duration
            frames.sort()
            reports.append({"quality":["Low","Medium","High","Ultra"][quality],"park_rendering":enabled,"mean_frame_ms":sum/frames.size(),"p95_frame_ms":frames[113],"max_frame_ms":frames[119],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"viewport":str(root.size),"scale_3d":root.scaling_3d_scale,"samples":120,"scope":"Same loaded actual canal world and camera; only park visibility toggled. Both cases retain loaded assets, physical geometry and active NPCs. Warm stationary samples, not sustained whole-world FPS."})
            if enabled:assert(root.get_texture().get_image().save_png("user://canal-quality-%d.png"%quality)==OK)
        state.world_minutes=19*60
        var light_count:=0
        for details:Node3D in current_scene.find_children("CanalBankDetails","Node3D",true,false):
            details._process(1.1)
            for lamp:OmniLight3D in details.lamps:
                var nearby:=lamp.global_position.distance_squared_to(player.global_position)<14400
                assert(lamp.visible==(quality>=1 and nearby) and not lamp.shadow_enabled and lamp.omni_range<=5.5)
                light_count+=1
        assert(light_count>=4)
        state.world_minutes=9*60
        for details:Node3D in current_scene.find_children("CanalBankDetails","Node3D",true,false):
            details._process(1.1)
            for lamp:OmniLight3D in details.lamps:assert(not lamp.visible)
    var proof:={"samples":reports,"grass_instances_in_loaded_cells":grass_count,"physical_tree_instances_in_loaded_cells":tree_count,"quality_invariant_world_geometry":true,"bounded_night_lights":true,"driver_position_assignments":0,"manual_play":false,"full_performance_acceptance":false}
    var file:=FileAccess.open("user://canal-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"  "));file.close()
    print("CANAL_PERFORMANCE_OK ",JSON.stringify(proof));quit(0)
