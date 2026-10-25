extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
    root.size=Vector2i(1280,720)
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.28,.35,.42);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.8,.85,.9);env.environment.ambient_light_energy=.4;world.add_child(env)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-30,0);sun.shadow_enabled=true;world.add_child(sun)
    var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(60,60);ground.mesh=plane;var floor_material:=StandardMaterial3D.new();floor_material.albedo_color=Color(.35,.33,.29);ground.material_override=floor_material;world.add_child(ground)
    var camera:=Camera3D.new();world.add_child(camera);camera.make_current();camera.fov=58
    var facade=load("res://scripts/modular_city_facades.gd").new()
    for stories:int in [2,3]:
        var house=load("res://assets/production/architecture/townhouse/Townhouse_%d.glb"%stories).instantiate();world.add_child(house);var triangles:=0
        for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
            assert(mesh.mesh.get_surface_count()==6)
            for surface in range(mesh.mesh.get_surface_count()):
                var arrays:=mesh.mesh.surface_get_arrays(surface);triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
                assert(arrays[Mesh.ARRAY_TANGENT].size()==arrays[Mesh.ARRAY_VERTEX].size()*4)
                mesh.set_surface_override_material(surface,facade._city_material(mesh.get_active_material(surface)))
        assert(triangles==31040 if stories==2 else triangles==37976)
        for close in [false,true]:
            camera.position=Vector3(12,6,17) if not close else Vector3(7.5,4.2,10)
            camera.look_at(Vector3(0,stories*1.56+1,0) if not close else Vector3(1.8,3.5,4.9))
            await process_frame;await RenderingServer.frame_post_draw
            assert(root.get_texture().get_image().save_png("user://townhouse-%d-%s.png"%[stories,"close" if close else "full"])==OK)
        house.free()
    for quality in range(4):
        root.get_node("SettingsManager").set_quality_preset(quality)
        facade.apply_surface_quality(quality)
        var clay:StandardMaterial3D=facade.photo_materials.clay
        var plaster:StandardMaterial3D=facade.photo_materials.plaster
        assert(clay.normal_enabled==(quality>=2) and plaster.normal_enabled==(quality>=2))
        assert((clay.roughness_texture!=null)==(quality>=2) and (plaster.roughness_texture!=null)==(quality>=2))
    for key:String in ["albedo_texture","normal_texture","roughness_texture"]:
        var texture:Texture2D=facade.photo_materials.clay.get(key);assert(texture!=null and texture.get_image().has_mipmaps())
    print("TOWNHOUSE_SURFACE_OK roles=6 tangents=true houses=2 clay_mip_chains=3 live_quality_levels=4")
    world.free();quit()
