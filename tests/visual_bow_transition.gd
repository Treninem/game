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
    for sex:String in ["male","female"]:
        var actor:=CharacterBody3D.new();actor.set_meta("preview_animation","Idle");world.add_child(actor)
        var visual:=load("res://scripts/humanoid_visual.gd").new() as Node3D;visual.set("appearance_profile",{"sex":sex,"Build":.5});actor.add_child(visual);visual.set_process(false)
        var skeleton:=visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
        var grip:Node=visual.get("grip_modifier")
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
        animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
        for enabled:bool in [false,true]:
            grip.set("clearance",actual_clearance if enabled else noop)
            actor.process_mode=Node.PROCESS_MODE_INHERIT
            actor.set_meta("preview_item","short_bow");visual.call("_refresh_weapon")
            animator.play("Idle",0);animator.seek(.4,true);animator.advance(0)
            skeleton.advance(0);await process_frame
            visual.set("active_animation","Idle");visual.call("_play","Bow_Attack_Draw",1.0)
            animator.advance(1./60.);state.capture=true;skeleton.advance(0);await process_frame
            assert(not state.capture)
            actor.process_mode=Node.PROCESS_MODE_DISABLED
            var measured:=await gpu.capture();var maximum:=0.0
            for i in range(measured.size()):maximum=maxf(maximum,cloth.to_global(measured[i]).distance_to(state.points[i]))
            assert(maximum<.0001)
            rows.append({"sex":sex,"build":.5,"first_draw_frame":true,"clearance":enabled,"gpu_error_m":maximum})
            camera.position=Vector3(1.8,1.35,-3.2);camera.look_at(Vector3(0,.9,0))
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("user://arm-"+("after-" if enabled else "before-")+sex+"-BowTransition.png");frames+=1
        gpu.dispose();actor.free()
    var file:=FileAccess.open("user://arm-gpu-visual.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows))
    assert(rows.size()==4 and frames==4)
    print("BOW_TRANSITION_GPU_OK samples=",rows.size()," frames=",frames)
    quit(0)
