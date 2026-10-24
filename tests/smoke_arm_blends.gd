extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _triangles(probe: RefCounted,skeleton: Skeleton3D,want_arm: bool) -> PackedInt32Array:
    var selected:=[];var result:=PackedInt32Array()
    for row:Array in probe.weights:
        var weight:=0.0
        for influence:Array in row:
            var name:String=skeleton.get_bone_name(probe.bindings[influence[0]][0])
            if "ForeArm" in name or "Hand" in name:weight+=float(influence[1])
        selected.append(weight>.45 if want_arm else weight<.01)
    for i in range(0,probe.complete.size(),3):
        if selected[probe.complete[i]] and selected[probe.complete[i+1]] and selected[probe.complete[i+2]]:
            for j in range(3):result.append(probe.complete[i+j])
    return result

func _run() -> void:
    create_timer(180).timeout.connect(func():push_error("ARM_BLEND timeout");quit(1))
    preload("res://tests/humanoid_layer_intersection_probe.gd").canaries()
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var rows:=[];var failed:=0
    for sex:String in ["male","female"]:
        for build:float in [-.5,0.,.5]:
            var actor:=CharacterBody3D.new();actor.set_meta("preview_animation","Idle");world.add_child(actor)
            var visual:=load("res://scripts/humanoid_visual.gd").new() as Node3D
            visual.set("appearance_profile",{"sex":sex,"Build":build});actor.add_child(visual);visual.set_process(false)
            var skeleton:=visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
            var animator:AnimationPlayer=visual.get("animation_player")
            animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
            var pants:=preload("res://tests/humanoid_layer_intersection_probe.gd").new();pants.setup(visual,skeleton)
            pants.outer.complete=_triangles(pants.outer,skeleton,true)
            var torso:=preload("res://tests/humanoid_layer_intersection_probe.gd").new();torso.setup(visual,skeleton,"VikingTunic")
            torso.inner.complete=_triangles(torso.inner,skeleton,false);torso.outer=pants.outer
            assert(pants.outer.complete.size()>300 and torso.inner.complete.size()>1000,"Missing actual arm/torso geometry in transition probe")
            var state:={"requested":false}
            visual.get("grip_modifier").modification_processed.connect(func():
                if state.requested:
                    state.requested=false;pants.snapshot(skeleton);torso.inner.snapshot(skeleton);torso.snapshots+=1)
            for pair:Array in [["Idle","Bow_Attack_Draw"],["Bow_Attack_Shoot","Idle"],["Idle","Cast_Left"],["Axe_Chop","Idle"],["Working","Idle"],["Idle","Sitting"]]:
                actor.set_meta("preview_item","short_bow" if "Bow" in str(pair) else ("starter_axe" if "Axe" in str(pair) else ""));visual.call("_refresh_weapon")
                animator.play(pair[0],0);animator.seek(animator.get_animation(pair[0]).length*.4,true);animator.advance(0)
                skeleton.advance(0);await process_frame
                visual.set("active_animation",pair[0]);visual.call("_play",pair[1],1.0)
                for frame in range(14):
                    animator.advance(1./60.);state.requested=true;skeleton.advance(0);await process_frame;assert(not state.requested)
                    var a:Dictionary=pants.scan();var b:Dictionary=torso.scan();var crossings:int=a.crossings_over_half_mm+b.crossings_over_half_mm
                    if crossings>0:failed+=1
                    rows.append({"sex":sex,"build":build,"from":pair[0],"to":pair[1],"frame":frame,"pairs":crossings})
                print("ARM_BLEND_PHASE sex=",sex," transition=",pair," failed=",failed)
            actor.free()
    var file:=FileAccess.open("user://arm-blends.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows))
    print("ARM_BLEND_CONTACT_RECORDED poses=",rows.size()," failed=",failed)
    assert(rows.size()==504 and failed==0,"Arm/clothing intersection during actual runtime crossfades")
    print("ARM_BLEND_CONTACT_OK poses=",rows.size()," bodies=2 builds=3 transitions=6 runtime_play=true")
    quit(0)
