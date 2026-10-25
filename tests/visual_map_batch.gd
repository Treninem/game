extends Node

class MapCanvas extends Control:
    var renderer = preload("res://scripts/local_map_renderer.gd").new()
    var center := Vector2.ZERO
    var radius := 100.0
    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO,size),Color(0.04,0.06,0.08))
        renderer.draw_features(self,Rect2(Vector2.ZERO,size),center,radius)

var reports: Array = []

func _ready() -> void:
    call_deferred("_run")

func _wait_draw() -> void:
    for i in range(3): await RenderingServer.frame_post_draw

func _run() -> void:
    get_tree().create_timer(50).timeout.connect(func():push_error("MAP_BATCH timeout");get_tree().quit(1))
    get_window().size = Vector2i(960,540)
    get_viewport().content_scale_size = Vector2i(960,540)
    MapSystem.set_process(false)
    GameState.reset_new_game()
    MapSystem._sync_state_revision()
    var before := GameState.snapshot()
    MapSystem.reveal_around(Vector2i.ZERO,2)
    var saved := {}
    for y in range(27):
        for x in range(37):
            MapSystem._remember_feature(saved,Vector2(-94+x*5.0,-94+y*5.0),"tree",Vector2(5,5),0.0)
    for i in range(6):
        MapSystem._remember_feature(saved,Vector2(-75+i*30,65),["building","fixture","rock","tree","stump","building"][i],Vector2(12,8),float(i)*0.3)
    # Overlap proves actor symbols remain on top of static geometry.
    MapSystem._remember_feature(saved,Vector2(0,75),"building",Vector2(14,14),0.3)
    GameState.set_world_value(MapSystem.FEATURES_KEY,saved)
    MapSystem.dynamic_features.assign([
        {"pos":[-75,86],"kind":"hostile"},{"pos":[-45,86],"kind":"ally"},
        {"pos":[-15,86],"kind":"npc"},{"pos":[15,86],"kind":"resource"},
        {"pos":[0,75],"kind":"hostile"}])
    var snapshot := JSON.stringify(GameState.snapshot())
    var canvas := MapCanvas.new()
    canvas.position=Vector2(20,20);canvas.size=Vector2(480,480)
    add_child(canvas)
    await _wait_draw()
    var rendered := get_viewport().get_texture().get_image()
    rendered.save_png("user://map-batch-markers.png")
    var calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    reports.append({"draw_calls":calls,"features":MapSystem.features_near(Vector2.ZERO,100).size()})
    assert(MapSystem.features_near(Vector2.ZERO,100).size()==1011,"Map lost one or more dense features")
    for sample in [{"pos":Vector2(-75,86),"color":Color(0.95,0.20,0.16)},{"pos":Vector2(-45,86),"color":Color(0.30,0.95,0.53)},{"pos":Vector2(-15,86),"color":Color(0.95,0.78,0.30)},{"pos":Vector2(0,75),"color":Color(0.95,0.20,0.16)}]:
        var point := Vector2i(canvas.position+canvas.renderer.project(Rect2(Vector2.ZERO,canvas.size),Vector2.ZERO,100,sample.pos))
        var pixel := rendered.get_pixelv(point)
        assert(Vector3(pixel.r,pixel.g,pixel.b).distance_to(Vector3(sample.color.r,sample.color.g,sample.color.b))<0.05,"Map symbol missing, recolored or covered")
    assert(JSON.stringify(GameState.snapshot())==snapshot,"Map rendering mutates save data")
    for sample in [{"pos":Vector2(-75,65),"color":Color(0.68,0.53,0.36)},{"pos":Vector2(-45,65),"color":Color(0.48,0.64,0.69)},{"pos":Vector2(-15,65),"color":Color(0.52,0.54,0.52)},{"pos":Vector2(45,65),"color":Color(0.48,0.30,0.16)}]:
        var point := Vector2i(canvas.position+canvas.renderer.project(Rect2(Vector2.ZERO,canvas.size),Vector2.ZERO,100,sample.pos))
        var pixel := rendered.get_pixelv(point)
        assert(Vector3(pixel.r,pixel.g,pixel.b).distance_to(Vector3(sample.color.r,sample.color.g,sample.color.b))<0.05,"Static map marker missing or recolored")
    assert(rendered.get_pixel(34,34).g>0.15,"Dense tree layer missing")
    assert(rendered.get_pixel(296,466).get_luminance()<0.08,"Resource ring must stay hollow")
    assert(rendered.get_pixel(298,466).r>0.65,"Resource ring missing")
    # New save must clear old markers, then disk-shaped JSON restoration must
    # restore those same markers without a live tree/building node.
    var restored:Dictionary=JSON.parse_string(snapshot)
    GameState.load_snapshot({"world_state":{}})
    canvas.queue_redraw()
    await _wait_draw()
    assert(MapSystem.features_near(Vector2.ZERO,100).is_empty())
    var empty := get_viewport().get_texture().get_image()
    empty.save_png("user://map-batch-empty-save.png")
    assert(empty.get_pixel(34,34).get_luminance()<0.08,"Previous save leaves tree pixels on the map")
    GameState.load_snapshot(restored)
    GameState.set_world_value("tree_fallen:forest:-94000:-94000",true)
    canvas.queue_redraw()
    await _wait_draw()
    var features:=MapSystem.features_near(Vector2.ZERO,100)
    assert(features.any(func(f):return f.kind=="stump" and Vector2(float(f.pos[0]),float(f.pos[1])).is_equal_approx(Vector2(-94,-94))),"Felled tree marker did not survive JSON restoration")
    get_viewport().get_texture().get_image().save_png("user://map-batch-restored-felled.png")
    # Repeated map resizing/zooming and disposal must not grow server objects.
    var resources_before := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
    for i in range(8):
        canvas.radius=100.0 if i%2==0 else 200.0
        canvas.size=Vector2(480,480) if i%2==0 else Vector2(300,200)
        canvas.queue_redraw()
        await _wait_draw()
    var resources_after := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
    assert(resources_after<=resources_before+4,"Map redraw leaks retained resources")
    reports.append({"resources_before":resources_before,"resources_after":resources_after,"zoom_resize_cycles":8})
    GameState.load_snapshot(before)
    FileAccess.open("user://map-batch.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
    print("MAP_BATCH_RENDERED ",JSON.stringify(reports))
    if calls >= 40:
        push_error("Dense cartography exceeds render budget: %d calls"%calls)
        get_tree().quit(1)
        return
    print("MAP_BATCH_OK markers=all actors=on_top save=unchanged restored=true felled=true zoom_resize=8")
    get_tree().quit(0)
