extends SceneTree

func _initialize()->void:call_deferred("_run")

func _picture(label:String)->Image:
    await process_frame
    await RenderingServer.frame_post_draw
    var image:=root.get_texture().get_image()
    assert(image.save_png("user://region-surfaces-"+label+".png")==OK)
    image.convert(Image.FORMAT_RGBA8)
    return image

func _run()->void:
    create_timer(240).timeout.connect(func():push_error("REGION_SURFACES timeout");quit(1))
    root.size=Vector2i(1280,720)
    root.msaa_3d=Viewport.MSAA_4X
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var environment:=WorldEnvironment.new();environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color(.19,.24,.29)
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color(.8,.85,.9)
    environment.environment.ambient_light_energy=.4
    world.add_child(environment)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-38,-25,0);world.add_child(sun)
    var camera:=Camera3D.new();world.add_child(camera);camera.make_current()
    var legacy=load("res://assets/production/nature/woodland/Grass_Ground.glb").instantiate()
    var texture:Texture2D
    for mesh:MeshInstance3D in legacy.find_children("*","MeshInstance3D",true,false):
        var material:=mesh.mesh.surface_get_material(0) as StandardMaterial3D
        if material!=null and material.albedo_texture!=null:texture=material.albedo_texture
    assert(texture!=null)
    legacy.free()
    var quad:=MeshInstance3D.new();quad.mesh=QuadMesh.new();quad.position.y=.8;world.add_child(quad)
    camera.position=Vector3(0,.8,2);camera.look_at(quad.position)
    var pictures:Array[Image]=[]
    for shader_path:String in ["res://tests/fixtures/foliage_pre_meadow.gdshader","res://assets/shaders/environment/foliage_wind.gdshader"]:
        var material:=ShaderMaterial.new();material.shader=load(shader_path)
        material.set_shader_parameter("albedo_texture",texture)
        material.set_shader_parameter("wind_strength",0.0)
        quad.material_override=material
        pictures.append(await _picture("legacy-"+str(pictures.size())))
    var a:=pictures[0].get_data();var b:=pictures[1].get_data();var altered:=0;var visible_pixels:=0
    var background:=pictures[0].get_pixel(0,0)
    for y in range(720):
        for x in range(1280):
            var i:=(y*1280+x)*4
            if absi(a[i]-b[i])+absi(a[i+1]-b[i+1])+absi(a[i+2]-b[i+2])>3:altered+=1
            if pictures[0].get_pixel(x,y)!=background:visible_pixels+=1
    assert(visible_pixels>10000 and altered<32,"Opt-in blade color changed the old cutout foliage")
    quad.free()
    var grass=load("res://assets/production/nature/meadow/MeadowGrass.glb").instantiate()
    world.add_child(grass)
    var triangles:=0;var min_y:=INF;var max_y:=-INF;var pigments:=0
    for mesh:MeshInstance3D in grass.find_children("*","MeshInstance3D",true,false):
        for surface in range(mesh.mesh.get_surface_count()):
            var arrays:=mesh.mesh.surface_get_arrays(surface)
            triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
            var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
            var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
            assert(colors.size()==points.size())
            for i in range(points.size()):
                assert(points[i].is_finite())
                min_y=minf(min_y,points[i].y);max_y=maxf(max_y,points[i].y)
                assert(colors[i].r>=0 and colors[i].g<=1 and colors[i].b>=0)
                if colors[i].g>colors[i].r:pigments+=1
    assert(triangles==130 and triangles<=180 and absf(min_y)<.0001 and absf(max_y-.38)<.0001 and pigments>100,"Blade envelope, budget or raw-Y wind anchors changed")
    load("res://scripts/production_nature.gd").prepare(grass)
    for mesh:MeshInstance3D in grass.find_children("*","MeshInstance3D",true,false):
        var material:=mesh.get_active_material(0) as ShaderMaterial
        assert(material!=null and material.get_shader_parameter("authored_blade_color")==true and material.get_shader_parameter("height_anchor")==true)
    camera.position=Vector3(.6,.35,.8);camera.look_at(Vector3(0,.17,0))
    await _picture("meadow-close")
    grass.free()
    var home=load("res://scripts/enterable_building.gd").new()
    home.configure(Vector3(12,3.2,10),1,"Surface review")
    world.add_child(home)
    load("res://scripts/cottage_exterior.gd").build(home)
    assert(home.window_count==6 and home.get_node("HouseRooms").room_doors.size()==3)
    var roof:Node3D=home.get_node("RealPackRoof");var roof_triangles:=0;var gable_surfaces:=0
    for mesh:MeshInstance3D in roof.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):
            roof_triangles+=mesh.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
            var material:=mesh.get_active_material(slot) as StandardMaterial3D
            assert(material!=null and material.albedo_texture!=null)
            if material==home._wall_material():gable_surfaces+=1
    assert(roof_triangles==26888 and gable_surfaces==1)
    assert(absf(roof.position.y-(home.wall_height-.01))<.0001,"Roof/wall seam is open")
    await physics_frame
    for side in [-1,1]:
        var query:=PhysicsRayQueryParameters3D.create(Vector3(side*3.0,12,0),Vector3(side*3.0,4,0))
        var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
        assert(not hit.is_empty() and String(hit.collider.name).begins_with("RoofCollision"),"Rendered roof has no physical support")
        assert(hit.position.y>6.15 and hit.position.y<6.45,"Roof collision is an invisible box or detached plane")
    var roof_body:StaticBody3D=home.get_node("RoofCollision")
    var owned_shape:Shape3D=roof_body.get_child(0).shape
    var shape_ref:WeakRef=weakref(owned_shape)
    assert(owned_shape.has_meta("navigation_local_bounds"))
    var roof_bounds:AABB=owned_shape.get_meta("navigation_local_bounds")
    for point:Vector3 in (owned_shape as ConcavePolygonShape3D).get_faces():
        assert(roof_bounds.grow(.0001).has_point(point),"Cached roof bounds omit physical geometry")
    assert(roof_bounds.position.y>home.floor_thickness+1.85,"Roof intrudes into headroom")
    var twin=load("res://scripts/enterable_building.gd").new()
    twin.configure(Vector3(12,3.2,10),1,"Shape sharing control")
    twin.position.x=30
    world.add_child(twin)
    assert(twin.get_node("RoofCollision").get_child(0).shape==owned_shape,"Equal roofs duplicate their physical triangles")
    owned_shape=null
    twin.free()
    camera.position=Vector3(9,1.7,14);camera.look_at(Vector3(0,3,0))
    var settings:=root.get_node("SettingsManager");var original_quality:int=settings.get_value("graphics","quality_preset")
    var surfaces=load("res://scripts/interior_surface_materials.gd")
    assert(surfaces.PLASTER_NORMAL.get_width()==512 and surfaces.PLASTER_NORMAL.get_height()==384)
    for texture_map:Texture2D in [surfaces.PLASTER,surfaces.PLASTER_NORMAL,surfaces.PLASTER_ORM]:assert(texture_map.get_image().has_mipmaps())
    for quality in range(4):
        settings.set_quality_preset(quality)
        var wall:StandardMaterial3D=home._wall_material()
        assert(wall.normal_enabled==(quality>=2) and wall.ao_enabled==(quality>=2) and (wall.roughness_texture!=null)==(quality>=2))
        await _picture("home-quality-"+str(quality))
    settings.set_quality_preset(original_quality)
    print("REGION_SURFACES_OK legacy_visible_pixels=",visible_pixels," legacy_changed_pixels=",altered," grass_triangles=",triangles," roof_triangles=",roof_triangles," front_windows=2 quality_views=4 shared_gable_material=true physical_roof=true released_shape=true")
    home.free()
    await process_frame
    assert(shape_ref.get_ref()==null,"Roof cache retained an unloaded home shape")
    world.free();quit()
