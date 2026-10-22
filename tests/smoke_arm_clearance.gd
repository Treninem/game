extends SceneTree

class NoClearance extends RefCounted:
    func apply(_visual: Node3D,_skeleton: Skeleton3D) -> void:pass


func _initialize() -> void:call_deferred("_run")

func _arm_triangles(probe: RefCounted,skeleton: Skeleton3D,want_arm: bool) -> PackedInt32Array:
    var result:=PackedInt32Array()
    var selected:=[]
    for row:Array in probe.weights:
        var arm:=0.0
        for influence:Array in row:
            var name:String=skeleton.get_bone_name(probe.bindings[influence[0]][0])
            if "ForeArm" in name or "Hand" in name:arm+=float(influence[1])
        selected.append(arm>.45 if want_arm else arm<.01)
    for i in range(0,probe.complete.size(),3):
        if selected[probe.complete[i]] and selected[probe.complete[i+1]] and selected[probe.complete[i+2]]:
            for j in range(3):result.append(probe.complete[i+j])
    return result

func _limbs(skeleton: Skeleton3D) -> Array:
    var rows:=[]
    for side:String in ["Left","Right"]:
        var a:=skeleton.get_bone_global_pose(skeleton.find_bone(side+"Arm"));var b:=skeleton.get_bone_global_pose(skeleton.find_bone(side+"ForeArm"));var c:=skeleton.get_bone_global_pose(skeleton.find_bone(side+"Hand"))
        rows.append({"upper":a.origin.distance_to(b.origin),"lower":b.origin.distance_to(c.origin),"wrist":c.origin,"orientation":c.basis.orthonormalized().get_rotation_quaternion()})
    return rows

func _compact(result: Dictionary) -> Dictionary:
    return {"pairs":result.crossings_over_half_mm,"edge_plane_depth_m":result.max_edge_plane_depth_m}

func _run() -> void:
    create_timer(280).timeout.connect(func():push_error("ARM_CONTACT timeout");quit(1))
    var world:=Node3D.new();root.add_child(world);current_scene=world
    preload("res://tests/humanoid_layer_intersection_probe.gd").canaries()
    var noop:=NoClearance.new()
    var rows:=[];var after_failures:=0;var regressions:=0;var before_pairs:=0;var after_pairs:=0
    var state:={"requested":false,"limbs":[],"legs":[],"pants":null,"torso":null}
    for sex:String in ["male","female"]:
        for build:float in [0.,-.5,.5,-.35,-.20,.05,.12,.4]:
            var actor:=CharacterBody3D.new();actor.set_meta("preview_animation","Idle");world.add_child(actor)
            var visual:=load("res://scripts/humanoid_visual.gd").new() as Node3D;visual.set("appearance_profile",{"sex":sex,"Build":build});actor.add_child(visual);visual.set_process(false)
            var skeleton:=visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
            var animator:AnimationPlayer=visual.get("animation_player")
            var pants:=preload("res://tests/humanoid_layer_intersection_probe.gd").new();pants.setup(visual,skeleton)
            pants.outer.complete=_arm_triangles(pants.outer,skeleton,true)
            var torso:=preload("res://tests/humanoid_layer_intersection_probe.gd").new();torso.setup(visual,skeleton,"VikingTunic")
            torso.inner.complete=_arm_triangles(torso.inner,skeleton,false);torso.outer=pants.outer
            assert(pants.outer.complete.size()>300 and torso.inner.complete.size()>1000)
            var grip:Node=visual.get("grip_modifier")
            var actual_clearance:RefCounted=grip.get("clearance")
            grip.modification_processed.connect(func():
                if state.requested:
                    state.requested=false;pants.snapshot(skeleton);torso.inner.snapshot(skeleton);torso.snapshots+=1
                    state.limbs=_limbs(skeleton);state.legs=[]
                    for name:String in ["Hips","LeftUpLeg","RightUpLeg","LeftLeg","RightLeg","LeftFoot","RightFoot"]:state.legs.append(skeleton.get_bone_global_pose(skeleton.find_bone(name))))
            for clip:String in ["Idle","Walk","Run","Jump","Airborne","Bow_Attack_Draw","Bow_Attack_Shoot","Axe_Chop","Punch","Cast_Left","Cast_Right","Sitting","Working","WorkStanding","Death"]:
                actor.set_meta("preview_item","short_bow" if clip in ["Bow_Attack_Draw","Bow_Attack_Shoot","Cast_Right"] else ("starter_axe" if clip in ["Axe_Chop","Cast_Left"] else ""));visual.call("_refresh_weapon")
                for phase:float in [.15,.4,.5,.7]:
                    grip.set("clearance",noop);animator.play(clip,0);animator.seek(animator.get_animation(clip).length*phase,true);animator.pause()
                    state.requested=true;skeleton.advance(0);await process_frame;assert(not state.requested)
                    var before:={"pants":_compact(pants.scan()),"torso":_compact(torso.scan())};var limbs_before:Array=state.limbs.duplicate(true);var legs_before:Array=state.legs.duplicate()
                    grip.set("clearance",actual_clearance);animator.play(clip,0);animator.seek(animator.get_animation(clip).length*phase,true);animator.pause()
                    state.requested=true;skeleton.advance(0);await process_frame;assert(not state.requested)
                    var after:={"pants":_compact(pants.scan()),"torso":_compact(torso.scan())}
                    var length_error:=0.0;var angle_error:=0.0;var shift:=0.0
                    for side in range(2):
                        var a:Dictionary=limbs_before[side];var b:Dictionary=state.limbs[side]
                        length_error=maxf(length_error,maxf(absf(a.upper-b.upper),absf(a.lower-b.lower)))
                        angle_error=maxf(angle_error,(a.orientation as Quaternion).angle_to(b.orientation))
                        shift=maxf(shift,(a.wrist as Vector3).distance_to(b.wrist))
                    for i in range(legs_before.size()):assert((legs_before[i] as Transform3D).is_equal_approx(state.legs[i]),"Arm clearance changed supported hips/legs")
                    assert(length_error<.0001 and angle_error<.002 and shift<.101,"Arm correction stretches bones, twists a wrist or exceeds its movement budget")
                    var count_before:int=before.pants.pairs+before.torso.pairs;var count_after:int=after.pants.pairs+after.torso.pairs
                    before_pairs+=count_before;after_pairs+=count_after
                    if count_after>0:after_failures+=1
                    if count_after>count_before:regressions+=1
                    rows.append({"sex":sex,"build":build,"clip":clip,"phase":phase,"before":before,"after":after,"max_wrist_shift_m":shift,"length_error_m":length_error,"wrist_angle_error_rad":angle_error,"clearance_usec":actual_clearance.get("last_usec")})
            print("ARM_CONTACT_BODY sex=",sex," build=",build," cumulative_before_pairs=",before_pairs," after_pairs=",after_pairs," failed_poses=",after_failures)
            actor.free()
    var file:=FileAccess.open("user://arm-contact.json",FileAccess.WRITE);file.store_string(JSON.stringify({"poses":rows,"failed_poses":after_failures,"regressions":regressions,"before_pairs":before_pairs,"after_pairs":after_pairs}))
    print("ARM_CONTACT_RECORDED poses=",rows.size()," before_pairs=",before_pairs," after_pairs=",after_pairs," failed_poses=",after_failures," regressions=",regressions)
    assert(after_failures==0 and regressions==0 and after_pairs==0,"Final forearm geometry intersects trousers/torso")
    var cache:Dictionary=preload("res://scripts/humanoid_arm_clearance.gd").profiles
    assert(cache.size()==2,"Identical human instances rebuild shared clothing profiles")
    print("ARM_CLEARANCE_OK poses=",rows.size()," shared_profiles=",cache.size()," cold_usec=",cache.values().map(func(value):return value.cold_build_usec))
    quit(0)
