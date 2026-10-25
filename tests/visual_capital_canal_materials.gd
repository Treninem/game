extends SceneTree
const DATA:=preload("res://scripts/capital_canal_data.gd")
var camera:Camera3D
var images:Array=[]
func _initialize()->void:call_deferred("_run")
func _frame()->Image:
    for index in range(4):await process_frame;await RenderingServer.frame_post_draw
    return root.get_texture().get_image()
func _run()->void:
    assert(DisplayServer.get_name()!="headless")
    create_timer(150).timeout.connect(func():push_error("CANAL_MATERIALS timeout");quit(1))
    root.size=Vector2i(640,480)
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var environment:=WorldEnvironment.new();environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.2,.3,.4)
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=1
    world.add_child(environment)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-25,0);world.add_child(sun)
    camera=Camera3D.new();world.add_child(camera);camera.make_current()
    var canals:GDScript=load("res://scripts/capital_canals.gd")
    var bridge:Node3D=canals.bridge(world,DATA.bridges()[1])
    var anchor:=bridge.global_position
    var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(160,100);ground.mesh=plane
    ground.position=anchor-Vector3.UP*DATA.DEPTH
    var earth:=StandardMaterial3D.new();earth.albedo_color=Color(.15,.23,.12);ground.material_override=earth;world.add_child(ground)
    var water:=MeshInstance3D.new();var water_plane:=PlaneMesh.new();water_plane.size=Vector2(36,100);water.mesh=water_plane;water.position=anchor;water.material_override=canals.liquid;world.add_child(water)
    var geometry:Array=[]
    for part in bridge.get_children():
        if part is MeshInstance3D:geometry.append({"mesh":part.mesh,"transform":part.transform,"triangles":part.mesh.get_faces().size()/3})
    for quality:int in [0,1,2,3]:
        root.get_node("SettingsManager").set_quality_preset(quality)
        root.size=Vector2i(640,480)
        assert(canals.stone.normal_enabled==(quality>=2))
        assert(canals.stone.albedo_texture.get_image().has_mipmaps() and canals.stone.normal_texture.get_image().has_mipmaps())
        var index:=0;var triangle_count:=0
        for part in bridge.get_children():
            if not part is MeshInstance3D:continue
            assert(part.mesh==geometry[index].mesh and part.transform==geometry[index].transform)
            triangle_count+=part.mesh.get_faces().size()/3;index+=1
        assert(triangle_count==40432 and index==4)
        camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=60
        camera.global_position=anchor+Vector3(37,6,35);camera.look_at(anchor+Vector3.UP)
        var image:Image=await _frame();assert(image.save_png("user://canal-material-quality-%d.png"%quality)==OK)
        images.append({"quality":quality,"bridge_triangles":triangle_count,"parts":index,"ashlar_normal":canals.stone.normal_enabled})
    # Same physical location and camera: only the optional moisture policy is
    # changed. This is a material fixture, not an earned world traversal.
    bridge.visible=false;ground.visible=false;water.visible=false
    var sample:=MeshInstance3D.new();var patch:=PlaneMesh.new();patch.size=Vector2(6,6);sample.mesh=patch
    var point:=DATA.CENTER+Vector2(-36,30);sample.position=Vector3(point.x,0,point.y)
    var material:=ShaderMaterial.new();material.shader=load("res://assets/shaders/environment/terrain_ground.gdshader")
    material.set_shader_parameter("grass_texture",load("res://assets/production/materials/ground/grass_meadow.jpg"))
    material.set_shader_parameter("rock_texture",load("res://assets/production/materials/ground/lichen_rock.jpg"))
    material.set_shader_parameter("freshwater_center",DATA.CENTER);material.set_shader_parameter("freshwater_half_length",DATA.HALF_LENGTH);material.set_shader_parameter("freshwater_half_width",DATA.HALF_WIDTH)
    sample.material_override=material;world.add_child(sample)
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4
    camera.global_position=sample.position+Vector3.UP*5;camera.look_at(sample.position,Vector3.BACK)
    material.set_shader_parameter("freshwater_bank",false);var before:Image=await _frame()
    material.set_shader_parameter("freshwater_bank",true);var after:Image=await _frame()
    assert(before.get_size()==after.get_size())
    var changed:=0;var green_gain:=0.;var sampled:=0
    for x in range(int(before.get_width()*.25),int(before.get_width()*.75),4):
        for y in range(int(before.get_height()*.2),int(before.get_height()*.8),4):
            var a:=before.get_pixel(x,y);var b:=after.get_pixel(x,y)
            sampled+=1
            if absf(a.g-b.g)>.01:changed+=1
            green_gain+=b.g-a.g
    assert(sampled>100 and changed>sampled*.65 and green_gain>sampled*.008,"Dry zero-height bank still uses the legacy wet-soil palette")
    assert(before.save_png("user://canal-ground-moisture-before.png")==OK and after.save_png("user://canal-ground-moisture-after.png")==OK)
    print("CAPITAL_CANAL_MATERIALS_OK quality_views=",images.size()," bridge_triangles=40432 parts=4 shared_maps_mipmapped=true geometry_invariant=true changed_ground_pixels=",changed," green_gain=",green_gain," fixture_only=true")
    world.free();quit(0)
