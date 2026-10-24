extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _picture() -> Image:
    await process_frame
    await RenderingServer.frame_post_draw
    var image:=root.get_texture().get_image()
    image.convert(Image.FORMAT_RGBA8)
    return image

func _run() -> void:
    create_timer(240).timeout.connect(func():push_error("WARDROBE_RESPONSE timeout");quit(1))
    root.size=Vector2i(1280,720)
    root.scaling_3d_scale=1.0
    root.msaa_3d=Viewport.MSAA_4X
    var world:=Node3D.new()
    root.add_child(world)
    current_scene=world
    var environment:=WorldEnvironment.new()
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color(.12,.15,.18)
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color(.78,.83,.88)
    environment.environment.ambient_light_energy=.32
    preload("res://scripts/character_preview_reflections.gd").configure(environment.environment)
    world.add_child(environment)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-28,155,0)
    light.light_energy=.65
    world.add_child(light)
    var camera:=Camera3D.new()
    camera.fov=30
    world.add_child(camera)
    camera.make_current()
    for i in range(4):await process_frame
    var type:=load("res://scripts/humanoid_visual.gd")
    var appearance:=load("res://scripts/character_appearance.gd")
    var map:Texture2D=type.TUNIC_RESPONSE
    # Verify actual reflected pixels, rather than accepting a configured Sky
    # object whose cubemap might never be sampled by the selected renderer.
    var sphere:=MeshInstance3D.new()
    var shape:=SphereMesh.new()
    shape.radius=.25
    shape.height=.5
    sphere.mesh=shape
    var chrome:=StandardMaterial3D.new()
    chrome.albedo_color=Color(.7,.7,.7)
    chrome.metallic=1
    chrome.roughness=.28
    sphere.material_override=chrome
    sphere.position=Vector3(0,1.38,0)
    world.add_child(sphere)
    light.visible=false
    camera.position=Vector3(0,1.38,-1.3)
    camera.look_at(sphere.position)
    environment.environment.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
    var unlit:=await _picture()
    environment.environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
    for i in range(4):await process_frame
    var reflected:=await _picture()
    var unlit_pixel:=unlit.get_pixel(unlit.get_width()/2,unlit.get_height()/2)
    var reflected_pixel:=reflected.get_pixel(reflected.get_width()/2,reflected.get_height()/2)
    print("PREVIEW_REFLECTION_PIXELS disabled=",unlit_pixel," sky=",reflected_pixel)
    assert(unlit.save_png("user://preview-reflection-disabled.png")==OK and reflected.save_png("user://preview-reflection-sky.png")==OK)
    assert(reflected_pixel.r+reflected_pixel.g+reflected_pixel.b>unlit_pixel.r+unlit_pixel.g+unlit_pixel.b+.15,"Preview sky is configured but does not illuminate metal")
    assert(unlit.get_pixel(0,0)==reflected.get_pixel(0,0),"Reflections replaced the plain editor backdrop")
    sphere.free()
    light.visible=true
    environment.environment.ambient_light_energy=.32
    var image:=map.get_image()
    assert(image!=null and image.get_width()==1024 and image.has_mipmaps())
    image.convert(Image.FORMAT_RGBA8)
    var bytes:=image.get_data()
    var metal_pixels:=0
    var rough_min:=255
    for i in range(1024*1024):
        if bytes[i*4]>25:metal_pixels+=1
        rough_min=mini(rough_min,bytes[i*4+1])
    assert(metal_pixels>60000 and metal_pixels<80000 and rough_min>=120 and rough_min<=125)
    assert(bytes[0]==0 and bytes[1]>=222 and bytes[1]<=226,"Cloth response became metallic or polished")
    var rows:Array=[]
    for sex:String in ["male","female"]:
        var actor:=CharacterBody3D.new()
        actor.set_meta("preview_animation","Idle")
        world.add_child(actor)
        var visual:=type.new() as Node3D
        visual.set("appearance_profile",{"sex":sex})
        actor.add_child(visual)
        visual.set_process(false)
        var animation:AnimationPlayer=visual.get("animation_player")
        animation.play("Idle",0)
        animation.seek(.3,true)
        animation.pause()
        for color in range(5):
            var profile:Dictionary=appearance.normalized({"sex":sex,"cloth":color,"hair_color":color,"eye_color":color})
            visual.call("apply_appearance",profile)
            assert(appearance.save_look(profile)==OK and appearance.load_look()==profile)
            var tunic:StandardMaterial3D
            for mesh:MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
                for slot in range(mesh.mesh.get_surface_count()):
                    var material:=mesh.get_active_material(slot) as StandardMaterial3D
                    if material==null:continue
                    if String(material.resource_name)=="VikingTunic":tunic=material
                    elif String(material.resource_name) in ["VikingPants","VikingBoots"]:assert(is_zero_approx(material.metallic))
            assert(tunic!=null and tunic.metallic_texture==map and tunic.roughness_texture==map)
            assert(is_equal_approx(tunic.metallic,1) and is_equal_approx(tunic.roughness,1))
            assert(tunic.metallic_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_RED and tunic.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_GREEN)
            assert(tunic.normal_enabled and tunic.ao_enabled and tunic.albedo_texture!=null)
            camera.position=Vector3(.8,1.48,-1)
            camera.look_at(Vector3(0,1.38,0))
            tunic.metallic=0
            tunic.roughness=.9
            tunic.roughness_texture=null
            var before:=await _picture()
            tunic.metallic=1
            tunic.roughness=1
            tunic.roughness_texture=map
            var after:=await _picture()
            var a:=before.get_data()
            var b:=after.get_data()
            var changed:=0
            var maximum:=0
            for y in range(0,after.get_height(),4):
                for x in range(0,after.get_width(),4):
                    var offset:=(y*after.get_width()+x)*4
                    var difference:=maxi(absi(a[offset]-b[offset]),maxi(absi(a[offset+1]-b[offset+1]),absi(a[offset+2]-b[offset+2])))
                    if difference>2:changed+=1
                    maximum=maxi(maximum,difference)
            assert(changed>20 and maximum>3,"New UV response has no visible effect on the rendered tunic")
            var file:="user://wardrobe-response-%s-%d.png"%[sex,color]
            assert(after.save_png(file)==OK)
            rows.append({"sex":sex,"cloth":color,"changed_samples":changed,"maximum_channel_difference":maximum,"file":file,"saved":true})
            print("WARDROBE_RESPONSE_SAMPLE ",JSON.stringify(rows.back()))
        actor.free()
    var creator:=load("res://scenes/character_creator.tscn").instantiate() as Control
    root.add_child(creator)
    await process_frame
    var preview:SubViewport=creator.get("viewport")
    var preview_environment:=preview.find_children("*","WorldEnvironment",true,false)[0] as WorldEnvironment
    assert(preview_environment.environment.background_mode==Environment.BG_COLOR)
    assert(preview_environment.environment.reflected_light_source==Environment.REFLECTION_SOURCE_SKY)
    assert(preview_environment.environment.sky!=null and preview_environment.environment.sky.radiance_size==Sky.RADIANCE_SIZE_64)
    for preset in [0,5]:
        creator.call("select_preset",preset)
        creator.set("zoom",1.35)
        creator.set("camera_height",1.35)
        creator.call("_camera")
        var picture:=await _picture()
        assert(picture.save_png("user://wardrobe-creator-%d.png"%preset)==OK)
    creator.free()
    var report:=FileAccess.open("user://wardrobe-response.json",FileAccess.WRITE)
    report.store_string(JSON.stringify({"metal_pixels":metal_pixels,"roughness_minimum_byte":rough_min,"samples":rows},"  "))
    print("WARDROBE_RESPONSE_OK bodies=2 saved_palettes=10 one_shared_map=true visible_controls=10 creator_views=2 reflection_size=64")
    quit(0)
