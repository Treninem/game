extends SceneTree

# External harness: execute from the export folder with --main-pack. This
# checks the shipped PCK, not a working copy's files or import cache.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(120).timeout.connect(func(): push_error("EXPORT_RESOURCE_HYGIENE timeout"); quit(1))
    assert(OS.get_cmdline_args().has("--main-pack"),"Resource hygiene requires the actual exported PCK")
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
    assert(load("res://scenes/boot_launcher.tscn") is PackedScene)
    print("EXPORT_RESOURCE_HYGIENE_OK docs=absent tests=absent bodies=",bodies," morphs=18 clips=20 eyes=5 shaders=2 boot=present actual_pck=true")
    quit(0)
