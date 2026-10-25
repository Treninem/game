extends "res://tests/capture_streamed_home_door.gd"

var mode := "baseline"
var rows:Array=[]
var saved_materials:Dictionary={}
var saved_lights:Dictionary={}

func _run() -> void:
    var state := root.get_node("GameState")
    print("HOUSE_COST_DIAGNOSTIC_ONLY unchanged_acceptance_test=tests/profile_continuous_home_door.gd")
    state.world_minutes=22*60
    root.get_node("SettingsManager").set_value("graphics","vsync",false)
    fixture=Node3D.new()
    var center:Vector2=load("res://scripts/capital_data.gd").CENTER
    var elevation:float=root.get_node("WorldData").elevation_at(center)
    fixture.position=Vector3(center.x,elevation+.025,center.y)
    root.add_child(fixture);current_scene=fixture
    var ground:=StaticBody3D.new()
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new();shape.size=Vector3(150,.2,150)
    collision.shape=shape;collision.position.y=-.1;ground.add_child(collision);fixture.add_child(ground)
    _build_square()
    await process_frame
    var geometry:Array=[]
    for node:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
        if node.mesh==null:continue
        var triangles:=0
        for i in range(node.mesh.get_surface_count()):
            var arrays:=node.mesh.surface_get_arrays(i)
            triangles+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3
            var mat:=node.get_active_material(i) as StandardMaterial3D
            if mat!=null and not saved_materials.has(mat):saved_materials[mat]={"normal":mat.normal_enabled,"ao":mat.ao_enabled}
        geometry.append({"path":str(node.get_path()),"surfaces":node.mesh.get_surface_count(),"triangles":triangles})
    for light:Light3D in root.find_children("*","Light3D",true,false):
        saved_lights[light]={"visible":light.visible,"shadow":light.shadow_enabled,"energy":light.light_energy}
    RenderingServer.frame_pre_draw.connect(_override)
    for label in ["baseline","without-shadow-maps","without-local-lights","without-normal-ao","restored"]:
        mode=label
        await _sample(label)
    var lights:Array=[]
    for light in saved_lights:lights.append({"path":str(light.get_path()),"state":saved_lights[light]})
    FileAccess.open("user://home-cost-profile.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":rows,"geometry":geometry,"lights":lights,"diagnostic_ablation_only":true},"  "))
    quit(0)

func _override() -> void:
    for light:Light3D in saved_lights:
        light.shadow_enabled=bool(saved_lights[light].shadow) and mode!="without-shadow-maps"
        light.visible=bool(saved_lights[light].visible) and (mode!="without-local-lights" or light is DirectionalLight3D)
    for mat:StandardMaterial3D in saved_materials:
        mat.normal_enabled=bool(saved_materials[mat].normal) and mode!="without-normal-ao"
        mat.ao_enabled=bool(saved_materials[mat].ao) and mode!="without-normal-ao"

func _sample(label:String) -> void:
    for i in range(8):await RenderingServer.frame_post_draw
    var times:Array[float]=[]
    var last:=Time.get_ticks_usec()
    for i in range(30):
        await RenderingServer.frame_post_draw
        var now:=Time.get_ticks_usec();times.append(float(now-last)/1000.0);last=now
    times.sort()
    var total:=0.0
    for t in times:total+=t
    var row:Dictionary={"mode":label,"mean_ms":total/times.size(),"p50_ms":times[15],"p95_ms":times[28],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)}
    rows.append(row);print("HOME_COST ",JSON.stringify(row))
    root.get_texture().get_image().save_png("user://home-cost-"+label+".png")
