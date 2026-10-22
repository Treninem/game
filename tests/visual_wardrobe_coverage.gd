extends SceneTree

var camera: Camera3D
var world: Node3D
var overlay: MeshInstance3D
var black: StandardMaterial3D
var red: StandardMaterial3D
var rows := []
var failed_views := 0
var saved_failures := 0
var worst_pixels := 0
var first_red := Vector2i.ZERO
var image_dimensions := Vector2.ZERO

func _initialize() -> void:call_deferred("_run")

func _red_pixels() -> int:
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    picture.convert(Image.FORMAT_RGBA8)
    image_dimensions=picture.get_size()
    var data := picture.get_data()
    var count := 0
    for i in range(0,data.size(),4):
        if data[i]>210 and data[i+1]<45 and data[i+2]<45:
            if count==0:
                var pixel := i>>2
                first_red=Vector2i(pixel%picture.get_width(),pixel/picture.get_width())
            count+=1
    return count

func _overlay(points: PackedVector3Array,indices: PackedInt32Array) -> void:
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=points
    arrays[Mesh.ARRAY_INDEX]=indices
    var mesh := ArrayMesh.new()
    if not indices.is_empty():mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    overlay.mesh=mesh

func _run() -> void:
    create_timer(260).timeout.connect(func():push_error("WARDROBE_COVERAGE watchdog");quit(1))
    root.size=Vector2i(640,480)
    world=Node3D.new()
    root.add_child(world)
    current_scene=world
    var environment := WorldEnvironment.new()
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color(.18,.22,.27)
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color.WHITE
    environment.environment.ambient_light_energy=.65
    world.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-35,-25,0)
    light.light_energy=1.2
    world.add_child(light)
    camera=Camera3D.new()
    camera.fov=42
    world.add_child(camera)
    camera.make_current()
    black=StandardMaterial3D.new()
    black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    black.albedo_color=Color.BLACK
    black.cull_mode=BaseMaterial3D.CULL_DISABLED
    red=black.duplicate() as StandardMaterial3D
    red.albedo_color=Color.RED
    overlay=MeshInstance3D.new()
    overlay.material_override=red
    world.add_child(overlay)
    for sex: String in ["male","female"]:
        for build: float in [0.0,-.5,.5]:
            var actor := CharacterBody3D.new()
            actor.set_meta("preview_animation","Idle")
            world.add_child(actor)
            var visual := load("res://scripts/humanoid_visual.gd").new() as Node3D
            visual.set("appearance_profile",{"sex":sex,"Build":build})
            actor.add_child(visual)
            visual.set_process(false)
            var skeleton := visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
            var animator: AnimationPlayer=visual.get("animation_player")
            var probe := preload("res://tests/humanoid_clothed_skin_probe.gd").new()
            probe.cache(visual,skeleton)
            var snapshot := {"requested":false,"points":PackedVector3Array(),"frame":-1,"active":false,"full":false}
            var modifier: Node=visual.get("grip_modifier")
            modifier.modification_processed.connect(func():
                if bool(snapshot.requested):
                    snapshot.points=probe.snapshot(skeleton)
                    snapshot.frame=Engine.get_process_frames()
                # Rebuild the diagnostic mesh in the very same final modifier
                # callback that supplies the GPU pose, on EVERY diagnostic frame.
                if bool(snapshot.active):
                    _overlay(probe.snapshot(skeleton),probe.complete if bool(snapshot.full) else probe.clothed)
            )
            var clothing := visual.find_child("Clothing",true,false) as MeshInstance3D
            var boots := visual.find_child("Boots",true,false) as MeshInstance3D
            for clip: String in ["Idle","Walk","Run","Jump","Airborne","Bow_Attack_Draw","Bow_Attack_Shoot","Axe_Chop","Punch","Cast_Left","Cast_Right","Sitting","Working","WorkStanding","Death"]:
                actor.set_meta("preview_item","short_bow" if clip in ["Bow_Attack_Draw","Bow_Attack_Shoot","Cast_Right"] else ("starter_axe" if clip in ["Axe_Chop","Cast_Left"] else ""))
                visual.call("_refresh_weapon")
                for phase: float in [.15,.4,.7]:
                    # Observe every modifier evaluation until this render has
                    # completed, including synchronous seek evaluations.
                    snapshot.requested=true
                    snapshot.frame=-1
                    animator.play(clip,0)
                    animator.seek(animator.get_animation(clip).length*phase,true)
                    animator.pause()
                    skeleton.advance(0)
                    await RenderingServer.frame_post_draw
                    assert(int(snapshot.frame)==Engine.get_process_frames(),"Missing same-frame final rendered modifier snapshot")
                    snapshot.requested=false
                    var points: PackedVector3Array=snapshot.points
                    assert(points.size()>1000 and probe.complete.size()>3000)
                    var label := "%s-build%s-%s-%.2f" % [sex,build,clip,phase]
                    camera.position=Vector3(1.5,1.3,-2.4)
                    camera.look_at(Vector3(0,.98,0))
                    if build==0 and is_equal_approx(phase,.4):
                        overlay.visible=false
                        await RenderingServer.frame_post_draw
                        root.get_texture().get_image().save_png("user://wardrobe-normal-"+label+".png")
                    probe.body.visible=false
                    clothing.material_override=black
                    boots.material_override=black
                    overlay.visible=true
                    snapshot.active=true
                    if clip=="Idle" and build==0 and is_equal_approx(phase,.15):
                        snapshot.full=true
                        _overlay(points,probe.complete)
                        clothing.visible=false
                        boots.visible=false
                        var control := await _red_pixels()
                        assert(control>300,"Renderer/skin positive control is blank")
                        clothing.visible=true
                        boots.visible=true
                    snapshot.full=false
                    _overlay(points,probe.clothed)
                    for angle in range(3):
                        camera.position=[Vector3(1.5,1.3,-2.4),Vector3(-1.6,1.3,-2.3),Vector3(.8,1.3,2.6)][angle]
                        camera.look_at(Vector3(0,.98,0))
                        var count := await _red_pixels()
                        rows.append({"sex":sex,"build":build,"clip":clip,"phase":phase,"angle":angle,"visible_clothed_skin_pixels":count})
                        if count>0:
                            if sex=="female" and build==0 and clip=="Working" and is_equal_approx(phase,.4):
                                print("WARDROBE_SKIN_DIAGNOSTIC ",JSON.stringify(probe.diagnose(camera,Vector2(first_red),image_dimensions)))
                            failed_views+=1
                            if count>worst_pixels:
                                worst_pixels=count
                                root.get_texture().get_image().save_png("user://wardrobe-worst.png")
                            if saved_failures<12:
                                root.get_texture().get_image().save_png("user://wardrobe-leak-"+label+"-view%d.png" % angle)
                                saved_failures+=1
                    snapshot.active=false
                    overlay.visible=false
                    probe.body.visible=true
                    clothing.material_override=null
                    boots.material_override=null
            actor.free()
    var file := FileAccess.open("user://wardrobe-coverage.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"views":rows,"failed_views":failed_views}))
    file.close()
    print("WARDROBE_COVERAGE views=",rows.size()," failed_views=",failed_views," final_modifiers=true bodies=2 builds=3 angles=3")
    if failed_views>0:
        push_error("Actual rendered skin breaks through covered torso/limbs in %d views" % failed_views)
        quit(1)
    else:
        print("WARDROBE_COVERAGE_OK")
        quit(0)
