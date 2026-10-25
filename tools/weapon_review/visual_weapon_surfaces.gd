extends SceneTree

const FAMILY="res://assets/production/weapons/woodland_refined/"
var world:Node3D
var camera:Camera3D

func _initialize():call_deferred("_run")

func _picture(label:String):
    await process_frame
    await RenderingServer.frame_post_draw
    var image=root.get_texture().get_image()
    assert(image.save_png("user://weapon-"+label+".png")==OK)
    return image

func _bounds(model:Node3D)->AABB:
    var result=AABB()
    var first=true
    for mesh in model.find_children("*","MeshInstance3D",true,false):
        var box=mesh.global_transform*mesh.get_aabb()
        result=box if first else result.merge(box)
        first=false
    assert(not first)
    return result

func _run():
    create_timer(210).timeout.connect(func():push_error("WEAPON_SURFACES timeout");quit(1))
    root.size=Vector2i(1280,720)
    root.msaa_3d=Viewport.MSAA_4X
    world=Node3D.new();root.add_child(world);current_scene=world
    var environment=WorldEnvironment.new();environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color(.12,.15,.18)
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color(.78,.83,.88)
    environment.environment.ambient_light_energy=.32
    preload("res://scripts/character_preview_reflections.gd").configure(environment.environment)
    world.add_child(environment)
    var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-28,155,0);light.light_energy=.85;world.add_child(light)
    camera=Camera3D.new();camera.fov=35;world.add_child(camera);camera.make_current()
    var rows=[]
    for label:String in ["Axe_small","Dagger","Bow_Wooden","Arrow"]:
        var before=load("res://assets/production/weapons/woodland/"+label+".glb").instantiate()
        world.add_child(before)
        var original=_bounds(before)
        var target=original.get_center()
        camera.position=target+Vector3(.19,.10,1.1)*maxf(original.size.length(),.45)*1.6
        camera.look_at(target)
        var previous=await _picture(label+"-before")
        before.free()
        var after=load(FAMILY+label+".tscn").instantiate();world.add_child(after)
        var revised=_bounds(after)
        if label=="Dagger":
            assert(absf(original.size.y-revised.size.y)<.001 and revised.size.x<.07 and revised.size.z<.035,"Stone knife length or grip envelope changed")
        else:assert(original.position.distance_to(revised.position)<.004 and original.size.distance_to(revised.size)<.007,"Normalized weapon bounds changed: "+label)
        var triangles=0;var surfaces=0
        for mesh:MeshInstance3D in after.find_children("*","MeshInstance3D",true,false):
            for slot in range(mesh.mesh.get_surface_count()):
                surfaces+=1
                var material=mesh.get_active_material(slot) as StandardMaterial3D
                assert(material!=null and not String(material.resource_name).contains("placeholder"))
                var arrays=mesh.mesh.surface_get_arrays(slot)
                var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
                assert(uv.size()==points.size(),"Missing authored UVs: "+label)
                for p in points:assert(p.is_finite())
                for p in uv:assert(p.is_finite())
                triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
                if String(material.resource_name) in ["LightWood","DarkWood","Flint"]:
                    assert(material.albedo_texture!=null and material.normal_enabled and material.normal_texture!=null)
                    assert(material.normal_texture==material.roughness_texture and material.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_ALPHA)
                    assert(material.albedo_texture.get_image().has_mipmaps() and material.normal_texture.get_image().has_mipmaps())
                if String(material.resource_name).contains("Steel"):assert(material.metallic>.8 and material.normal_enabled)
        assert(triangles<6000)
        if label=="Dagger":assert(after.find_child("StoneBlade",true,false)!=null and after.find_child("BladeLashing",true,false)!=null)
        var current=await _picture(label+"-after")
        previous.convert(Image.FORMAT_RGB8);current.convert(Image.FORMAT_RGB8)
        var a=previous.get_data();var b=current.get_data();var changed=0
        for i in range(0,a.size(),3):
            if absi(a[i]-b[i])+absi(a[i+1]-b[i+1])+absi(a[i+2]-b[i+2])>12:changed+=1
        assert(changed>150,"No visible weapon revision: "+label)
        rows.append({"model":label,"triangles":triangles,"surfaces":surfaces,"changed_pixels":changed,"bounds":str(revised)})
        after.free()
    for sex:String in ["male","female"]:
        var actor=CharacterBody3D.new();actor.set_meta("preview_animation","Idle");world.add_child(actor)
        var pivot=Node3D.new();pivot.name="CameraPivot";actor.add_child(pivot)
        var visual=load("res://weapon_candidate_visual.gd").new()
        visual.appearance_profile={"sex":sex};actor.add_child(visual);visual.set_process(false)
        var skeleton=visual.find_children("*","Skeleton3D",true,false)[0]
        for item:String in ["starter_axe","stone_knife","short_bow"]:
            actor.set_meta("preview_item",item);visual.call("_refresh_weapon")
            var clip="Axe_Chop" if item=="starter_axe" else ("Bow_Attack_Draw" if item=="short_bow" else "Punch")
            visual.animation_player.play(clip)
            visual.animation_player.seek(.396,true);visual.animation_player.pause()
            skeleton.advance(1.0/60)
            await process_frame
            assert(is_instance_valid(visual.held_weapon))
            camera.position=Vector3(1.45,1.35,-2.2);camera.look_at(Vector3(0,1.25,0))
            if item=="short_bow":
                assert(visual.bow_cords.size()==2 and is_instance_valid(visual.nocked_arrow))
                for mesh:MeshInstance3D in visual.held_weapon.find_children("*","MeshInstance3D",true,false):
                    if not String(mesh.name).begins_with("Bow_Wooden"):continue
                    for slot in range(mesh.mesh.get_surface_count()):
                        var mat=mesh.get_active_material(slot) as StandardMaterial3D
                        assert(mat!=null and not String(mat.resource_name).contains("placeholder"),"Bow cleanup lost shared surfaces")
            await _picture(sex+"-"+item)
        actor.free()
    var file=FileAccess.open("user://weapon-surface-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close()
    print("WEAPON_SURFACES_OK paired_models=4 actor_actions=6 shared_maps=5 ",JSON.stringify(rows))
    world.free();quit()
