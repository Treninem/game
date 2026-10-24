extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(300).timeout.connect(func():push_error("STREETSCAPE_PERFORMANCE timeout");quit(1))
    assert(DisplayServer.get_name()!="headless")
    assert(root.get_node("SaveManager").prepare_load(1))
    change_scene_to_file("res://scenes/world_loading.tscn")
    var player:CharacterBody3D
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or bool(player.get("ground_guard_active")):
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
    current_scene.set_process(false);root.get_node("GameState").world_minutes=9*60
    var square:Node3D=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO].get_node("CapitalSquareLife")
    var decoration:Array[Node3D]=[square.get_node("CapitalStreetscape")]
    for body in square.get_children():
        if not body is Node3D:continue
        if String(body.name).begins_with("StreetPostLantern") or String(body.name).begins_with("StreetPostLight"):
            decoration.append(body)
        else:
            for visual in body.get_children():
                if visual is Node3D and visual.scene_file_path=="res://assets/production/nature/temperate/TemperateBush.glb":
                    decoration.append(body);break
    assert(decoration.size()==15,"Performance comparison omits some street decoration")
    var camera:=Camera3D.new();current_scene.add_child(camera)
    camera.global_position=square.to_global(Vector3(6,2.2,16));camera.look_at(square.to_global(Vector3(18,1.6,32)));camera.make_current()
    var reports:Array=[]
    for quality:int in [0,1,2,3]:
        root.get_node("SettingsManager").set_quality_preset(quality)
        for enabled:bool in [false,true]:
            for node:Node3D in decoration:node.visible=enabled and not node is OmniLight3D
            for i in range(45):await process_frame;await RenderingServer.frame_post_draw
            var frames:Array[float]=[];var tick:=Time.get_ticks_usec()
            for i in range(120):
                await process_frame;await RenderingServer.frame_post_draw
                var now:=Time.get_ticks_usec();frames.append(float(now-tick)/1000);tick=now
            var mean:=0.
            for frame:float in frames:mean+=frame
            frames.sort()
            reports.append({"quality":["Low","Medium","High","Ultra"][quality],"decoration_enabled":enabled,"frames":frames.size(),"mean_frame_ms":mean/frames.size(),"p95_frame_ms":frames[113],"max_frame_ms":frames[119],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"scale_3d":root.scaling_3d_scale,"viewport":str(root.size),"scope":"Paired same loaded world and street camera; toggled only new decoration visibility. NPCs remain active. Assets loaded in both samples. Warm stationary samples, not sustained traversal or isolated CPU/GPU profiling.","player_position_assignments":0})
            assert(root.get_texture().get_image().save_png("user://street-performance-%d-%s.png"%[quality,str(enabled)])==OK)
    var file:=FileAccess.open("user://street-performance.json",FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(reports,"  "));file.close()
    print("STREETSCAPE_PERFORMANCE_OK ",JSON.stringify(reports));quit(0)
