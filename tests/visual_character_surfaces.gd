extends SceneTree

var rows: Array = []
var probe_camera: Camera3D

func _initialize() -> void:
    call_deferred("_run")

func _image() -> Image:
    await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _save(image: Image, name: String) -> void:
    assert(image.save_png("user://character-surface-" + name + ".png") == OK)

func _pixel(image: Image, uv: Vector2) -> Color:
    # Project the actual quad. Window stretch may retain the project's 16:9
    # viewport even when the test asks the OS for a square window.
    var point := probe_camera.unproject_position(Vector3((uv.x-.5)*2.0,(.5-uv.y)*2.0,0))
    point *= Vector2(image.get_size()) / probe_camera.get_viewport().get_visible_rect().size
    return image.get_pixel(clampi(int(point.x),0,image.get_width()-1),clampi(int(point.y),0,image.get_height()-1))

func _shader_checks() -> bool:
    root.size = Vector2i(512,512)
    # Prior tests may leave the user's Low preset in settings.cfg. Color/UV
    # probes require native pixels, rather than a filtered 70% reconstruction.
    # This changes the test viewport only; the saved preset is untouched.
    root.scaling_3d_scale = 1.0
    var world := Node3D.new()
    root.add_child(world)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color.BLACK
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color.WHITE
    env.environment.ambient_light_energy = 1.0
    world.add_child(env)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.0
    camera.position.z = 3
    world.add_child(camera)
    probe_camera = camera
    camera.make_current()
    var quad := MeshInstance3D.new()
    quad.mesh = QuadMesh.new()
    quad.mesh.size = Vector2(2,2)
    world.add_child(quad)
    var texture := Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var value := 0.06 if (x / 2) % 2 == 0 else 0.22
            texture.set_pixel(x,y,Color(value,value,value,1.0 if y < 32 else float(x)/63.0))
    texture.generate_mipmaps()
    var hair := ShaderMaterial.new()
    hair.shader = load("res://assets/shaders/characters/hair_strands.gdshader")
    hair.set_shader_parameter("hair_texture",ImageTexture.create_from_image(texture))
    hair.set_shader_parameter("hair_color",Color(.65,.48,.33))
    hair.set_shader_parameter("eyebrows",true)
    hair.set_shader_parameter("strand_contrast",0.0)
    quad.material_override = hair
    var plain := await _image()
    print("SURFACE_PROBE_VIEWPORT logical=",root.get_visible_rect().size," pixels=",plain.get_size()," scale=",root.scaling_3d_scale)
    _save(plain,"strand-control")
    hair.set_shader_parameter("strand_contrast",.85)
    var detailed := await _image()
    _save(detailed,"strand-detail")
    # Fine strands are narrower than the neighborhood mip footprint. Wide
    # flat band centers have no local detail and must not be used as strands.
    var low := Vector2(8.5/64.0,.25)
    var high := Vector2(10.5/64.0,.25)
    var before := _pixel(plain,high).get_luminance() - _pixel(plain,low).get_luminance()
    var after := _pixel(detailed,high).get_luminance() - _pixel(detailed,low).get_luminance()
    print("STRAND_CONTRAST before=",before," after=",after)
    assert(before > .01 and after > before * 1.12,"Authored local strands lose their visible separation")
    var mean_before := (_pixel(plain,high).get_luminance() + _pixel(plain,low).get_luminance())*.5
    var mean_after := (_pixel(detailed,high).get_luminance() + _pixel(detailed,low).get_luminance())*.5
    assert(mean_after < mean_before*1.35,"Detail adjustment overexposes the whole pigment")
    for msaa in [Viewport.MSAA_DISABLED,Viewport.MSAA_4X]:
        root.msaa_3d = msaa
        var edge := await _image()
        var transparent := _pixel(edge,Vector2(.0625,.75)).get_luminance()
        var surviving := _pixel(edge,Vector2(.8125,.75)).get_luminance()
        assert(transparent < .005 and surviving > .015,"Hair loses cutout/depth coverage with a graphics preset")
        _save(edge,"alpha-"+str(msaa))
    var eyes := ShaderMaterial.new()
    eyes.shader = load("res://assets/shaders/characters/human_iris.gdshader")
    eyes.set_shader_parameter("eye_texture",load("res://assets/production/characters/realistic/eyes/brown_eye.png"))
    eyes.set_shader_parameter("brown_iris",false)
    quad.material_override = eyes
    var source := await _image()
    eyes.set_shader_parameter("brown_iris",true)
    var corrected := await _image()
    _save(corrected,"brown-iris")
    var a := _pixel(source,Vector2(.784,.322))
    var b := _pixel(corrected,Vector2(.784,.322))
    print("IRIS_PIGMENT source=",a," corrected=",b)
    assert(a.r > a.g*1.8 and b.r > b.g*1.1 and b.r < b.g*1.9,"Brown iris remains red or becomes green")
    var perimeter := 0
    # Independent positions measured from source pixels, including the formerly
    # uncorrected north/east crescents. Both globes must pass every sector.
    for center: Vector2 in [Vector2(.28959326,.71127206),Vector2(.70542749,.29916668)]:
        for sector in range(16):
            var angle := TAU*float(sector)/16.0
            var color := _pixel(corrected,center+Vector2(cos(angle),sin(angle))*.105)
            assert(color.r > color.g*1.1 and color.r < color.g*1.9,"An iris sector retains the red source crescent: center=%s sector=%d color=%s" % [center,sector,color])
            perimeter += 1
    var white_a := _pixel(source,Vector2(.5,.5))
    var white_b := _pixel(corrected,Vector2(.5,.5))
    assert(Vector3(white_a.r,white_a.g,white_a.b).distance_to(Vector3(white_b.r,white_b.g,white_b.b)) < .005,"Iris correction dyes the sclera")
    rows.append({"kind":"shader","contrast_before":before,"contrast_after":after,"mean_before":mean_before,"mean_after":mean_after,"iris_source":str(a),"iris_corrected":str(b),"iris_perimeter_sectors":perimeter,"msaa_modes":2})
    world.free()
    return true

func _material(visual: Node3D, name: String) -> Material:
    var mesh := visual.find_child(name,true,false) as MeshInstance3D
    assert(mesh != null)
    return mesh.get_active_material(0)

func _run() -> void:
    create_timer(240).timeout.connect(func(): push_error("CHARACTER_SURFACES timeout"); quit(1))
    if not await _shader_checks():
        push_error("CHARACTER_SURFACES shader measurements did not finish")
        quit(1)
        return
    root.size = Vector2i(1280,720)
    root.msaa_3d = Viewport.MSAA_4X
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(.12,.15,.18)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color(.78,.83,.88)
    env.environment.ambient_light_energy = .25
    world.add_child(env)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-28,155,0)
    key.light_energy = .65
    world.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20,-25,0)
    fill.light_energy = .12
    world.add_child(fill)
    var camera := Camera3D.new()
    camera.fov = 30
    world.add_child(camera)
    camera.make_current()
    var appearance := load("res://scripts/character_appearance.gd")
    var type := load("res://scripts/humanoid_visual.gd")
    for sex: String in ["male","female"]:
        var actor := CharacterBody3D.new()
        actor.set_meta("preview_animation","Idle")
        world.add_child(actor)
        var visual := type.new() as Node3D
        visual.set("appearance_profile",{"sex":sex})
        actor.add_child(visual)
        visual.set_process(false)
        var animation: AnimationPlayer = visual.get("animation_player")
        animation.play("Idle",0)
        animation.seek(.3,true)
        animation.pause()
        var skin := _material(visual,"HumanBody") as StandardMaterial3D
        assert(is_equal_approx(skin.metallic_specular,.32) and is_equal_approx(skin.roughness,.64))
        assert((_material(visual,"Brows") as ShaderMaterial).get_shader_parameter("eyebrows") == true)
        var reference_hair := _material(visual,"HairShort")
        var reference_skin := _material(visual,"HumanBody")
        for i in range(25):
            visual.call("apply_appearance",{"sex":sex,"cloth":i%5,"eye_color":i/5,"hair":i%2,"Build":float(i%3-1)*.35,"height_cm":160.0+i})
            assert(_material(visual,"HairShort") == reference_hair,"Unrelated appearance choices duplicate a hair material")
            assert(_material(visual,"HumanBody") == reference_skin,"Unrelated appearance choices duplicate a skin material")
        for color in range(5):
            var profile: Dictionary = appearance.normalized({"sex":sex,"hair":0 if sex=="male" else 1,"hair_color":color,"skin":color%3,"cloth":color,"eye_color":color})
            visual.call("apply_appearance",profile)
            assert(appearance.save_look(profile)==OK and appearance.load_look()==profile,"Pigment choices do not survive disk restoration")
            var hair := _material(visual,"HairShort") as ShaderMaterial
            var eyes := _material(visual,"Eyes") as ShaderMaterial
            assert(hair.shader == type.HAIR_SHADER and hair.get_shader_parameter("hair_color") == appearance.HAIR[color])
            assert(eyes.shader == type.EYE_SHADER and eyes.get_shader_parameter("eye_texture") == type.EYE_TEXTURES[color])
            assert(eyes.get_shader_parameter("brown_iris") == (color==0))
            var skeleton := visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
            skeleton.advance(0)
            await process_frame
            var head := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin)+Vector3.UP*.10
            camera.position = head+Vector3(.55,.02,-.72)
            camera.look_at(head)
            _save(await _image(),sex+"-pigment-"+str(color))
            rows.append({"kind":"portrait","sex":sex,"color":color,"skin":color%3,"saved":true})
        # Reapplying the same categories cannot expand the cache again.
        var cached: int = type.palette_materials.size()
        for i in range(25):
            visual.call("apply_appearance",{"sex":sex,"cloth":i%5,"eye_color":i/5,"hair":i%2,"Build":float(i%3-1)*.35,"height_cm":160.0+i})
        assert(type.palette_materials.size()==cached,"Repeated category selection grows the material cache")
        actor.free()
    assert(type.palette_materials.size() <= 70,"Appearance cache still multiplies unrelated pigments")
    rows.append({"kind":"cache","materials":type.palette_materials.size(),"unrelated_profile_checks":50,"repeat_checks":50})
    var report := FileAccess.open("user://character-surfaces.json",FileAccess.WRITE)
    report.store_string(JSON.stringify(rows,"  "))
    print("CHARACTER_SURFACES_OK portraits=10 pigments_saved=10 unrelated_profiles=50 repeated_profiles=50 cached_materials=",type.palette_materials.size())
    quit(0)
