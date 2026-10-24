extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _hit(world:Node3D,point:Vector3) -> Dictionary:
    return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*3,point-Vector3.UP*.2,1))

func _run() -> void:
    create_timer(180).timeout.connect(func():push_error("CITY_STREETSCAPE_FIXTURE timeout");quit(1))
    assert(DisplayServer.get_name()!="headless","Street asset validation requires actual rendering")
    root.size=Vector2i(1280,720)
    var state:=root.get_node("GameState");state.set_process(false);state.world_minutes=9*60
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var floor_body:=StaticBody3D.new();world.add_child(floor_body)
    var shape:=BoxShape3D.new();shape.size=Vector3(100,.2,110)
    var collision:=CollisionShape3D.new();collision.shape=shape;collision.position=Vector3(CapitalData.CENTER.x,-.075,CapitalData.CENTER.y+10);floor_body.add_child(collision)
    var square:Node3D=load("res://scripts/capital_square_life.gd").new();square.position=Vector3(CapitalData.CENTER.x,0,CapitalData.CENTER.y);world.add_child(square)
    load("res://scripts/capital_market_court.gd").build(square)
    var street:=square.get_node("CapitalStreetscape") as Node3D
    var details:Dictionary=street.get_meta("measured_street_details")
    assert(details.paving_panels==28 and details.planters==6 and details.lantern_posts==4 and details.central_clear_width_m==14)
    var source:Node3D=load("res://assets/production/architecture/city_street/CityStreetKit.glb").instantiate()
    var marker:=source.find_child("LanternAnchor",true,false) as Node3D;assert(marker!=null)
    var anchor:=marker.position;source.free()
    var post:=street.get_node("StreetLanternPost_-1_25") as StaticBody3D
    var lantern:=square.get_node("StreetPostLantern") as Node3D
    var bounds:AABB=square._bounds(lantern,Transform3D.IDENTITY)
    assert(absf(bounds.end.y-square.to_local(post.to_global(anchor)).y)<.003,"Lantern top is detached from Blender bracket marker")
    assert(post.get_child(0).shape is ConcavePolygonShape3D,"Street post lost exact measured geometry")
    var iron:=false;var triangles:=0
    for key:String in ["PavingPanel","LanternPost"]:
        var mesh:Mesh=street.get_node(key).multimesh.mesh
        for slot in range(mesh.get_surface_count()):
            triangles+=mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
            var material:=mesh.surface_get_material(slot) as StandardMaterial3D
            if material.resource_name=="StreetIron":
                assert(material.albedo_color.r<.4 and material.albedo_color.g<.4 and material.albedo_color.b<.4 and material.metallic>.5 and material.roughness>=.7)
                iron=true
    var trough:=street.get_node("PlantedStoneTrough_-1_24") as StaticBody3D
    var planter_mesh:Mesh=trough.get_child(0).mesh
    for slot in range(planter_mesh.get_surface_count()):triangles+=planter_mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
    assert(iron and triangles==8880)
    for frame in range(3):await physics_frame
    var measured:Array=[]
    for data:Array in [[Vector3(16.8,0,21),.064,"MeasuredWalkablePaving"],[Vector3(-8.35,0,24),.365,"PlantedStoneTrough_-1_24"],[Vector3(-8.35+.72,0,24),.615,"PlantedStoneTrough_-1_24"],[Vector3(-17.8+.18,0,25+.18),.174,"StreetLanternPost_-1_25"]]:
        var hit:=_hit(world,square.to_global(data[0]));assert(not hit.is_empty())
        var y:=square.to_local(hit.position).y
        assert(absf(y-float(data[1]))<.006 and String(hit.collider.name)==data[2],"Street physical geometry differs from expected model: "+str(data))
        measured.append({"surface":data[2],"height_m":y})
    var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.20,.27,.33);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color(.8,.87,.95);environment.environment.ambient_light_energy=.6;world.add_child(environment)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-25,0);world.add_child(sun)
    var camera:=Camera3D.new();world.add_child(camera);camera.position=square.to_global(Vector3(11,2.1,20));camera.look_at(square.to_global(Vector3(18,1.5,26)));camera.make_current()
    var render_checks:Array=[]
    for quality:int in [0,1,2,3]:
        root.get_node("SettingsManager").set_quality_preset(quality)
        for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
        var material:=street.get_node("PavingPanel").multimesh.mesh.surface_get_material(0) as StandardMaterial3D
        assert(material.albedo_texture!=null and material.normal_enabled==(quality>=2) and (material.roughness_texture!=null)==(quality>=2))
        var image:=root.get_texture().get_image();assert(image!=null and image.get_width()==1280)
        assert(image.save_png("user://city-street-fixture-quality-%d.png"%quality)==OK)
        render_checks.append({"quality":quality,"normal_enabled":material.normal_enabled,"roughness_map_enabled":material.roughness_texture!=null})
    var report:={"source_triangles":triangles,"details":details,"physical_probes":measured,"blender_marker_matches_lantern_top":true,"iron_material_preserved":iron,"rendered_quality_modes":render_checks,"scope":"Isolated capital public-square fixture, not ordinary gameplay or full city art acceptance"}
    var file:=FileAccess.open("user://city-street-fixture.json",FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(report,"  "));file.close()
    print("CITY_STREETSCAPE_FIXTURE_OK ",JSON.stringify(report))
    world.free();quit(0)
