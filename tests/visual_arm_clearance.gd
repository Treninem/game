extends SceneTree

class NoClearance extends RefCounted:
    func apply(_visual: Node3D,_skeleton: Skeleton3D) -> void:pass


func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(150).timeout.connect(func():push_error("ARM_VISUAL timeout");quit(1))
    root.size=Vector2i(1280,720)
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.2;light.shadow_enabled=true;world.add_child(light)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR
    env.environment.background_color=Color(.2,.24,.28);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.6;world.add_child(env)
    var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();(floor.mesh as PlaneMesh).size=Vector2(8,8);floor.position.y=-.02
    var material:=StandardMaterial3D.new();material.albedo_color=Color(.26,.29,.31);material.roughness=.9;floor.material_override=material;world.add_child(floor)
    var camera:=Camera3D.new();camera.fov=40;world.add_child(camera);camera.make_current()
    var frames:=0;var rows:=[];var noop:=NoClearance.new()
    for body_mode:String in ["male_preview","female_preview","male_citizen","female_citizen"]:
        var sex:String=body_mode.get_slice("_",0)
        var citizen:=body_mode.ends_with("citizen")
        var prefix:="arm-citizen-" if citizen else "arm-"
        var actor:=CharacterBody3D.new()
        if citizen:actor.name="CitizenFixture"
        else:actor.set_meta("preview_animation","Idle")
        world.add_child(actor)
        var visual:=load("res://scripts/humanoid_visual.gd").new() as Node3D;visual.set("appearance_profile",{"sex":sex,"Build":.5 if sex=="female" else 0.0});actor.add_child(visual);visual.set_process(false)
        var skeleton:=visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
        var grip:Node=skeleton.get_node("ClothingClearance") if citizen else visual.get("grip_modifier")
        var actual_clearance:RefCounted=grip.get("clearance")
        var cloth:=visual.find_child("Clothing",true,false) as MeshInstance3D;var slot:=-1
        for i in range(cloth.mesh.get_surface_count()):
            if cloth.mesh.surface_get_material(i).resource_name=="VikingTunic":slot=i
        var cpu:=preload("res://tests/humanoid_clothed_skin_probe.gd").new();cpu.cache(visual,skeleton,"Clothing","VikingTunic")
        var state:={"capture":false,"points":PackedVector3Array()}
        grip.modification_processed.connect(func():
            if state.capture:state.capture=false;state.points=cpu.snapshot(skeleton))
        var gpu:=preload("res://tests/gpu_skinned_vertex_probe.gd").new();gpu.setup(root,cloth,slot);await gpu.calibrate()
        var animator:AnimationPlayer=visual.get("animation_player")
        for clip:String in ["Idle","Walk","Run","Jump","Bow_Attack_Draw","Axe_Chop","Cast_Left","Cast_Right","Working","WorkStanding","Sitting"]:
            if citizen and clip not in ["Idle","Walk","Run","Sitting","Working","WorkStanding"]:continue
            actor.set_meta("preview_item","short_bow" if clip in ["Bow_Attack_Draw","Cast_Right"] else ("starter_axe" if clip in ["Axe_Chop","Cast_Left"] else ""));visual.call("_refresh_weapon")
            var phase:=.5 if clip=="Jump" else .4
            if clip in ["Idle","Axe_Chop","Cast_Left","Working","Sitting"]:
                grip.set("clearance",noop);actor.process_mode=Node.PROCESS_MODE_INHERIT
                animator.play(clip,0);animator.seek(animator.get_animation(clip).length*phase,true);animator.pause()
                skeleton.advance(0);await process_frame
                camera.position=Vector3(1.8,1.35,-3.2);camera.look_at(Vector3(0,.9,0))
                await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://"+prefix+"before-"+sex+"-"+clip+".png");frames+=1
            grip.set("clearance",actual_clearance);actor.process_mode=Node.PROCESS_MODE_INHERIT
            animator.play(clip,0);animator.seek(animator.get_animation(clip).length*phase,true);animator.pause()
            state.capture=true;skeleton.advance(0);await process_frame;assert(not state.capture)
            actor.process_mode=Node.PROCESS_MODE_DISABLED
            var measured:=await gpu.capture();var maximum:=0.0
            for i in range(measured.size()):maximum=maxf(maximum,cloth.to_global(measured[i]).distance_to(state.points[i]))
            assert(maximum<.0001,"Actual GPU vertices differ from corrected final arm pose")
            rows.append({"sex":sex,"citizen":citizen,"build":visual.get("current_profile").Build,"clip":clip,"vertices":measured.size(),"gpu_error_m":maximum})
            camera.position=Vector3(1.8,1.35,-3.2);camera.look_at(Vector3(0,.9,0))
            await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://"+prefix+"after-"+sex+"-"+clip+".png");frames+=1
            if clip in ["Idle","Working","Sitting"]:
                camera.position=Vector3(-1.8,1.35,3.2);camera.look_at(Vector3(0,.9,0))
                await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://"+prefix+"after-"+sex+"-"+clip+"-back.png");frames+=1
        gpu.dispose();actor.free()
    var file:=FileAccess.open("user://arm-gpu-visual.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows))
    print("ARM_GPU_VISUAL_OK poses=",rows.size()," frames=",frames)
    quit(0)
