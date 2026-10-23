extends SceneTree

# External harness: execute from the export folder with --main-pack. This
# checks the shipped PCK, not a working copy's files or import cache.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(120).timeout.connect(func(): push_error("EXPORT_RESOURCE_HYGIENE timeout"); quit(1))
    # Godot consumes --main-pack before exposing script command-line args.
    # Inspect the mounted compiled project; setting an environment variable
    # while running the raw source project must not satisfy this contract.
    var pack_path := OS.get_environment("GODOT_SMOKE_PACK")
    assert(not pack_path.is_empty() and FileAccess.file_exists(pack_path),"Resource hygiene requires a physical exported PCK")
    assert(FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot"),"Resource hygiene requires the mounted compiled project")
    print("EXPORT_PACK_MOUNT_OK project_binary=present source_project=absent")
    for folder: String in ["res://docs","res://tests"]:
        assert(not DirAccess.dir_exists_absolute(folder),"Source-only material is present in the game package: "+folder)
    for name: String in ["GameState","SaveManager","WorldData","SettingsManager"]:
        var instance := root.get_node_or_null(name)
        assert(instance != null and instance.get_script() != null,"Packaged autoload is unavailable: "+name)
    var visual := load("res://scripts/humanoid_visual.gd") as GDScript
    assert(visual != null and visual.HUMAN_PATHS.size()==2)
    var bodies := 0
    for sex: String in ["male","female"]:
        var packed := load(visual.HUMAN_PATHS[sex]) as PackedScene
        assert(packed != null,"Dynamic production body is absent from the PCK")
        var model := packed.instantiate() as Node3D
        var body := model.find_child("HumanBody",true,false) as MeshInstance3D
        var clothing := model.find_child("Clothing",true,false) as MeshInstance3D
        var far := model.find_child("HumanBodyFar",true,false) as MeshInstance3D
        var skeletons := model.find_children("*","Skeleton3D",true,false)
        var animations := model.find_children("*","AnimationPlayer",true,false)
        assert(body != null and body.skin != null and body.mesh.get_blend_shape_count()==9)
        assert(clothing != null and far != null and not skeletons.is_empty() and not animations.is_empty())
        for clip: String in ["Axe_Chop","Bow_Attack_Draw","Bow_Attack_Shoot","Death","Idle","Jump","Punch","Run","Walk","Working"]:
            assert((animations[0] as AnimationPlayer).has_animation(clip),"Packaged body loses its source action: "+clip)
        model.free()
        bodies += 1
    assert(visual.EYE_TEXTURES.size()==5,"Packaged eye palette is incomplete")
    for texture: Texture2D in visual.EYE_TEXTURES:
        assert(texture != null and texture.get_width()>0,"Packaged eye atlas is missing")
        var image := texture.get_image()
        assert(image != null and image.has_mipmaps(),"Packaged eye mip chain is missing")
    assert(visual.HAIR_SHADER != null and visual.EYE_SHADER != null)
    var response: Texture2D = visual.TUNIC_RESPONSE
    assert(response != null and response.get_width()==1024 and response.get_image().has_mipmaps(),"Packaged tunic response/mip chain is missing")
    assert(load("res://scripts/character_preview_reflections.gd") is GDScript)
    assert(load("res://scenes/boot_launcher.tscn") is PackedScene)
    var ground_scene := load("res://assets/production/nature/meadow/MeadowGrass.glb") as PackedScene
    assert(ground_scene != null,"Packaged meadow mesh is missing")
    var grass := ground_scene.instantiate()
    var grass_triangles := 0
    for mesh: MeshInstance3D in grass.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):
            var arrays := mesh.mesh.surface_get_arrays(slot)
            grass_triangles += arrays[Mesh.ARRAY_INDEX].size()/3
            assert(arrays[Mesh.ARRAY_COLOR].size()>0,"Packaged grass loses authored blade pigments")
    assert(grass_triangles==130)
    grass.free()
    var roof_scene := load("res://assets/production/exteriors/family_home/CottageShingleRoof.tscn") as PackedScene
    assert(roof_scene!=null,"Packaged family roof wrapper is missing")
    var roof := roof_scene.instantiate()
    var roof_triangles := 0
    var roof_surfaces := 0
    for mesh: MeshInstance3D in roof.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):
            roof_triangles += mesh.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
            roof_surfaces += 1
            var material := mesh.get_active_material(slot) as StandardMaterial3D
            assert(material!=null and material.albedo_texture!=null and material.albedo_texture.get_image().has_mipmaps(),"Packaged roof surface or mip chain is missing")
    assert(roof_triangles==26888 and roof_surfaces==4)
    roof.free()
    var surfaces := load("res://scripts/interior_surface_materials.gd") as GDScript
    for map: Texture2D in [surfaces.PLASTER,surfaces.PLASTER_NORMAL,surfaces.PLASTER_ORM]:
        assert(map!=null and map.get_image().has_mipmaps(),"Packaged lime plaster is missing")
    assert(surfaces.PLASTER_NORMAL.get_width()==512 and surfaces.PLASTER_NORMAL.get_height()==384)
    for stories:int in [2,3]:
        var townhouse_scene:=load("res://assets/production/architecture/townhouse/Townhouse_%d.glb"%stories) as PackedScene
        assert(townhouse_scene!=null,"Packaged authored townhouse is missing")
        var townhouse:=townhouse_scene.instantiate()
        var triangles:=0
        for mesh:MeshInstance3D in townhouse.find_children("*","MeshInstance3D",true,false):
            assert(mesh.mesh.get_surface_count()==6)
            for slot in range(mesh.mesh.get_surface_count()):triangles+=mesh.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
        assert(triangles==(31040 if stories==2 else 37976))
        townhouse.free()
    for name:String in ["albedo","normal","orm"]:
        var map:=load("res://assets/production/architecture/townhouse/clay_%s.png"%name) as Texture2D
        assert(map!=null and map.get_image().has_mipmaps(),"Packaged clay surface or mips missing")
    var fountain_scene:=load("res://assets/production/architecture/market_court/MarketFountain.glb") as PackedScene
    assert(fountain_scene!=null and load("res://scripts/market_fountain.gd") is GDScript and load("res://scripts/capital_market_court.gd") is GDScript)
    var fountain:=fountain_scene.instantiate()
    assert(fountain.find_child("FountainStone",true,false)!=null and fountain.find_child("LowerWater",true,false)!=null and fountain.find_child("UpperWater",true,false)!=null)
    fountain.free()
    var arcade_scene:=load("res://assets/production/architecture/market_arcade/MarketArcade.glb") as PackedScene
    assert(arcade_scene!=null,"Packaged authored market arcade is missing")
    var arcade:=arcade_scene.instantiate()
    var arcade_triangles:=0
    for mesh:MeshInstance3D in arcade.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):arcade_triangles+=mesh.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
    assert(arcade_triangles==32322 and arcade.find_children("LanternMount*","Node3D",true,false).size()==2,"Packaged market roof or measured lantern anchors changed")
    arcade.free()
    for script:String in ["market_structures","public_space_navigation","public_seating","market_goods_display"]:
        assert(load("res://scripts/"+script+".gd") is GDScript,"Packaged public market logic is missing: "+script)
    print("EXPORT_RESOURCE_HYGIENE_OK docs=absent tests=absent bodies=",bodies," morphs=18 clips=20 eyes=5 shaders=2 boot=present wardrobe_response=1 meadow=1 family_roof=1 lime_maps=3 townhouses=2 clay_maps=3 fountain=1 market_arcade=1 public_market_scripts=4 actual_pck=true")
    quit(0)
