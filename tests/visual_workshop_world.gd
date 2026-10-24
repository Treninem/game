extends "res://tests/visual_house_concept_world.gd"

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://workshop-"+label+".png")

func _run() -> void:
    assert(root.get_node("SaveManager").call("prepare_load",1),"Requires earned capital arrival checkpoint")
    change_scene_to_file("res://scenes/world_loading.tscn")
    deadline=Time.get_ticks_msec()+240000
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or bool(player.get("ground_guard_active")):
        await physics_frame
        player=get_first_node_in_group("player") as CharacterBody3D
        assert(Time.get_ticks_msec()<deadline)
    current_scene.set_process(false)
    root.get_node("GameState").set("world_minutes",9.0*60)
    root.get_node("SettingsManager").call("set_quality_preset",1)
    for offset in [Vector2(-8,4),Vector2(-8,-4),Vector2(-16,-4),Vector2(-16,-6.9)]:
        if not await _walk(offset):return
    var square:Node3D=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO].get_node("CapitalSquareLife")
    var trader:Node3D=square.get_node("SquareTrader")
    if not await _interact(trader,trader.global_position+Vector3.UP*1.1):return
    assert(root.get_node("DialogueManager").get("is_open"))
    await _capture("merchant-dialogue")
    root.get_node("DialogueManager").call("close_dialogue")
    var state:Node=root.get_node("GameState")
    # Real trade methods and finite recipe; setup adds only the two input items.
    state.call("add_item","wood",1);state.call("add_item","stone",1)
    var stock:Dictionary=trader.call("_shop_stock")
    assert(int(stock.get("wood",0))==0 and int(stock.get("stone",0))==0,"Arrival fixture must have idle, unsupplied production")
    var arrows_before:=int(stock.get("arrow",0))
    var coins_before:=int(state.get("coins"))
    assert(trader.call("complete_trade","wood",true) and trader.call("complete_trade","stone",true))
    assert(int(state.get("coins"))==coins_before+2)
    # Pass north of the real barrel at (-21,-6), with capsule clearance.
    for offset in [Vector2(-16,-3.4),Vector2(-23,-3.4),Vector2(-23,-8.3)]:
        if not await _walk(offset):return
    var artisan:Node3D=square.get_node("SquareArtisan")
    var animator:AnimationPlayer=artisan.get("visual").get("animation_player")
    var camera:=Camera3D.new();current_scene.add_child(camera);camera.fov=43;camera.make_current()
    camera.global_position=artisan.global_position+Vector3(2.2,1.9,-2.0)
    camera.look_at(artisan.global_position+Vector3.UP*1.0)
    assert(artisan.get_meta("activity")=="work" and animator.current_animation=="WorkStanding")
    await _capture("standing-production")
    var bench:Node3D=square.get_node("SquareWorkbench")
    assert(bench.get_node("ArrowWorkpieces").visible)
    var skeleton:=artisan.get("visual").find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
    for side:String in ["Left","Right"]:
        var hand:=bench.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(side+"HandMiddle3")).origin))
        print("WORKSHOP_FINGERTIP bench_local=",hand," side=",side," authored_top=",bench.get_meta("authored_height"))
    assert(root.get_node("SaveManager").call("save_game",player,6))
    assert(root.get_node("SaveManager").call("prepare_load",6))
    change_scene_to_file("res://scenes/world_loading.tscn")
    player=null
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or bool(player.get("ground_guard_active")):
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        assert(Time.get_ticks_msec()<deadline)
    current_scene.set_process(false)
    state.set("world_minutes",9.0*60)
    square=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i.ZERO].get_node("CapitalSquareLife")
    trader=square.get_node("SquareTrader");artisan=square.get_node("SquareArtisan")
    for frame in range(900):
        await physics_frame
        if int(trader.call("_shop_stock").get("arrow",0))==arrows_before+5:break
    assert(int(trader.call("_shop_stock").get("arrow",0))==arrows_before+5,"Saved production did not resume exactly once")
    for frame in range(180):await physics_frame
    assert(artisan.get_meta("activity")=="idle")
    assert(int(trader.call("_shop_stock").get("arrow",0))==arrows_before+5,"Empty workshop minted extra stock")
    var sample_start:=Time.get_ticks_usec()
    for frame in range(120):await process_frame
    print("WORKSHOP_FRAME_SAMPLE frames=120 mean_ms=",float(Time.get_ticks_usec()-sample_start)/120000.0,
        " reported_video_bytes=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
        " draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
    print("WORKSHOP_WORLD_OK earned_checkpoint=true player_position_assignments=0 walked_m=",walked," trade_paid=true standing_recipe=true disk_resume=true finite_stock=true quality=Medium clock_fixture=09:00")
    quit(0)
