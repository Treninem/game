extends SceneTree

var results: Array = []
var player: CharacterBody3D

func _initialize() -> void:
    call_deferred("_run")

func _sample(label: String) -> void:
    for i in range(8): await process_frame
    var values: Array[float] = []
    var cpu := 0.0
    var physics := 0.0
    var last := Time.get_ticks_usec()
    for i in range(30):
        await RenderingServer.frame_post_draw
        var now := Time.get_ticks_usec()
        values.append(float(now - last) / 1000.0)
        last = now
        cpu += Performance.get_monitor(Performance.TIME_PROCESS)
        physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
    values.sort()
    var sum := 0.0
    for value in values: sum += value
    var row := {"label":label,"frames":values.size(),"mean_ms":sum/values.size(),"p50_ms":values[15],"p95_ms":values[28],"cpu_ms":cpu*1000/values.size(),"physics_ms":physics*1000/values.size(),"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"video_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)}
    results.append(row)
    print("WORLD_RENDER_PROFILE ",JSON.stringify(row))
    root.get_texture().get_image().save_png("user://profile-"+label+".png")

func _run() -> void:
    create_timer(150).timeout.connect(func():push_error("World render profile timeout");quit(1))
    root.get_node("SettingsManager").call("set_quality_preset",1)
    root.get_node("SettingsManager").call("set_value","graphics","vsync",false)
    change_scene_to_file("res://scenes/stage1.tscn")
    await process_frame
    player = get_first_node_in_group("player") as CharacterBody3D
    while player == null or bool(player.get("ground_guard_active")):
        await physics_frame
        player = get_first_node_in_group("player") as CharacterBody3D
    for i in range(65): await process_frame
    var inventory := {}
    for node in root.find_children("*","GeometryInstance3D",true,false):
        var group := String(node.get_parent().name)
        var item:Dictionary = inventory.get(group,{"nodes":0,"instances":0})
        item.nodes += 1
        item.instances += node.multimesh.instance_count if node is MultiMeshInstance3D and node.multimesh != null else 1
        inventory[group] = item
    print("WORLD_RENDER_GEOMETRY groups=",inventory.size())
    await _sample("baseline")
    if "--map-only" in OS.get_cmdline_user_args():
        var maps: Array[Control] = []
        for control: Control in root.find_children("*","Control",true,false):
            if control.get_script() != null and control.get_script().resource_path == "res://scripts/minimap_view.gd":
                maps.append(control)
                control.hide()
        assert(maps.size() == 1)
        await _sample("without-minimap")
        for control in maps: control.show()
        await _sample("restored")
        FileAccess.open("user://world-render-profile.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":results,"geometry":inventory,"manual_play":false,"quality":1},"  "))
        print("WORLD_RENDER_PROFILE_OK")
        quit(0)
        return
    var nature := get_nodes_in_group("quality_nature")
    var visible_before: Array[bool] = []
    for node in nature:
        visible_before.append(node.visible)
        node.visible = false
    await _sample("without-nature")
    for i in range(nature.size()): nature[i].visible = visible_before[i]
    var lights := root.find_children("*","DirectionalLight3D",true,false)
    for node in lights: node.shadow_enabled = false
    await _sample("without-shadows")
    root.get_node("SettingsManager").call("apply_world_quality")
    await _sample("restored")
    FileAccess.open("user://world-render-profile.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":results,"geometry":inventory,"manual_play":false,"quality":1},"  "))
    print("WORLD_RENDER_PROFILE_OK")
    quit(0)
