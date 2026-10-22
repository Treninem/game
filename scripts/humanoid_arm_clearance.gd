extends RefCounted

# Native garment bounds are measured once per shared mesh/skin, across the
# supported Build range. Endpoint interpolation conservatively bounds the
# linear position morph; no per-frame mesh scans or mutable palette materials.
static var profiles: Dictionary = {}
const PROFILE_BUILDS := [-.5,0.,.5]
const MAX_SHIFT := .10
var mesh_ref: WeakRef
var hips := -1
var rest_basis := Basis.IDENTITY
var rest_axes := Basis.IDENTITY
var arms := []
var legs := []
var data := {}
var build_index := -1
var last_changed_arms := 0
var last_max_shift_m := 0.0
var last_usec := 0

func _geometry(cloth: MeshInstance3D,skeleton: Skeleton3D) -> Dictionary:
    var key:="%d:%d" % [cloth.mesh.get_instance_id(),cloth.skin.get_instance_id()]
    if profiles.has(key):return profiles[key]
    var profile_started:=Time.get_ticks_usec()
    var bindings:=[]
    for slot in range(cloth.skin.get_bind_count()):
        var bone:=cloth.skin.get_bind_bone(slot)
        if not cloth.skin.get_bind_name(slot).is_empty():bone=skeleton.find_bone(cloth.skin.get_bind_name(slot))
        bindings.append([skeleton.get_bone_global_rest(bone)*cloth.skin.get_bind_pose(slot),String(skeleton.get_bone_name(bone))])
    var origin:=skeleton.get_bone_global_rest(hips).origin
    var to_actor:=rest_axes.inverse()
    var boxes:=[Vector4(INF,-INF,INF,-INF),Vector4(INF,-INF,INF,-INF),Vector4(INF,-INF,INF,-INF)]
    var cuffs:=[Vector2(.025,.025),Vector2(.025,.025),Vector2(.025,.025)]
    var cuff_counts:=[0,0]
    var leg_radii:=[PackedFloat32Array([.035,.035,.035,.035,.035,.035]),PackedFloat32Array([.035,.035,.035,.035,.035,.035]),PackedFloat32Array([.035,.035,.035,.035,.035,.035])]
    var leg_counts:=[0,0,0,0,0,0]
    var waist_count:=0
    for surface in range(cloth.mesh.get_surface_count()):
        var label:String=cloth.mesh.surface_get_material(surface).resource_name
        if label not in ["VikingPants","VikingTunic"]:continue
        var arrays:=cloth.mesh.surface_get_arrays(surface)
        var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var bone_ids:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
        var values:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
        var stride:int=bone_ids.size()/points.size()
        var delta:PackedVector3Array=(cloth.mesh as ArrayMesh).surface_get_blend_shape_arrays(surface)[build_index][Mesh.ARRAY_VERTEX]
        var normalized:bool=(cloth.mesh as ArrayMesh).blend_shape_mode==Mesh.BLEND_SHAPE_MODE_NORMALIZED
        for i in range(points.size()):
            var p:=Vector3.ZERO;var d:=Vector3.ZERO;var arm_weight:=0.0;var forearm:=[0.0,0.0];var leg_weight:=[0.0,0.0]
            var change:Vector3=delta[i]-points[i] if normalized else delta[i]
            for j in range(stride):
                var weight:float=values[i*stride+j]
                if weight<=0:continue
                var binding:Array=bindings[bone_ids[i*stride+j]];var frame:Transform3D=binding[0];var name:String=binding[1]
                p+=(frame*points[i])*weight;d+=(frame.basis*change)*weight
                if "Arm" in name or "Hand" in name or "Shoulder" in name:arm_weight+=weight
                for side in range(2):
                    var prefix:String=["Left","Right"][side]
                    if name.begins_with(prefix) and ("ForeArm" in name or "Hand" in name):forearm[side]+=weight
                    if name in [prefix+"UpLeg",prefix+"Leg",prefix+"Foot"]:leg_weight[side]+=weight
            var center:=to_actor*(p-origin);var movement:=to_actor*d
            if arm_weight<.05 and minf(center.y+movement.y*.5,center.y-movement.y*.5)<.19 and maxf(center.y+movement.y*.5,center.y-movement.y*.5)>-.23:
                waist_count+=1
                for profile in range(3):
                    var q:Vector3=center+movement*float(PROFILE_BUILDS[profile]);var box:Vector4=boxes[profile]
                    box.x=minf(box.x,q.x);box.y=maxf(box.y,q.x);box.z=minf(box.z,q.z);box.w=maxf(box.w,q.z);boxes[profile]=box
            if label=="VikingPants":
                for segment in range(legs.size()):
                    var row:Dictionary=legs[segment]
                    if float(leg_weight[row.side_index])<.35:continue
                    var a:=skeleton.get_bone_global_rest(row.a).origin;var b:=skeleton.get_bone_global_rest(row.b).origin;var axis:=b-a
                    var along:float=(p-a).dot(axis)/axis.length_squared()
                    if along<float(row.start) or along>float(row.finish):continue
                    leg_counts[segment]+=1
                    for profile in range(3):
                        var q:Vector3=p+d*float(PROFILE_BUILDS[profile]);var radius:float=q.distance_to(a+axis*((q-a).dot(axis)/axis.length_squared()))
                        leg_radii[profile][segment]=maxf(leg_radii[profile][segment],radius)
            if label!="VikingTunic":continue
            for side in range(2):
                if forearm[side]<.4:continue
                var a:Vector3=skeleton.get_bone_global_rest(arms[side].elbow).origin
                var b:Vector3=skeleton.get_bone_global_rest(arms[side].wrist).origin;var axis:=b-a
                var along:float=(p-a).dot(axis)/axis.length_squared()
                if along<.55 or along>1.05:continue
                cuff_counts[side]+=1
                for profile in range(3):
                    var q:Vector3=p+d*float(PROFILE_BUILDS[profile]);var radius:float=q.distance_to(a+axis*((q-a).dot(axis)/axis.length_squared()))
                    var pair:Vector2=cuffs[profile];pair[side]=maxf(pair[side],radius);cuffs[profile]=pair
    assert(waist_count>100 and cuff_counts[0]>8 and cuff_counts[1]>8,"Missing actual clothing envelope samples")
    for count:int in leg_counts:assert(count>8,"Missing actual trouser section samples")
    for profile in range(3):
        var box:Vector4=boxes[profile];var radius:Vector2=cuffs[profile]
        assert(box.y-box.x>.15 and box.y-box.x<.7 and box.w-box.z<.6 and radius.x<.12 and radius.y<.12,"Invalid anatomical garment envelope")
        for value:float in leg_radii[profile]:assert(value<.25,"Invalid trouser section radius")
    data={"boxes":boxes,"cuffs":cuffs,"waist_samples":waist_count,"cuff_samples":cuff_counts,"leg_radii":leg_radii,"leg_samples":leg_counts}
    if profiles.size()>=16:profiles.erase(profiles.keys()[0])
    data["cold_build_usec"]=Time.get_ticks_usec()-profile_started
    profiles[key]=data
    return data

func _setup(visual: Node3D,skeleton: Skeleton3D) -> bool:
    var cloth:=visual.find_child("Clothing",true,false) as MeshInstance3D
    if cloth==null or cloth.skin==null:return false
    build_index=cloth.find_blend_shape_by_name("Build")
    if build_index<0:return false
    var labels:=[]
    for surface in range(cloth.mesh.get_surface_count()):labels.append(String(cloth.mesh.surface_get_material(surface).resource_name))
    if "VikingPants" not in labels or "VikingTunic" not in labels:return false
    hips=skeleton.find_bone("Hips")
    if hips<0:return false
    for side:String in ["Left","Right"]:
        for part:String in ["Arm","ForeArm","Hand","UpLeg","Leg","Foot"]:
            if skeleton.find_bone(side+part)<0:return false
    mesh_ref=weakref(cloth)
    rest_basis=skeleton.get_bone_global_rest(hips).basis
    rest_axes=(skeleton.global_basis.inverse()*visual.global_basis).orthonormalized()
    var origin:=skeleton.get_bone_global_rest(hips).origin;arms=[];legs=[]
    for side:String in ["Left","Right"]:
        var wrist:=skeleton.find_bone(side+"Hand")
        arms.append({"side":side,"upper":skeleton.find_bone(side+"Arm"),"elbow":skeleton.find_bone(side+"ForeArm"),"wrist":wrist,"sign":signf((rest_axes.inverse()*(skeleton.get_bone_global_rest(wrist).origin-origin)).x)})
        var thigh:=skeleton.find_bone(side+"UpLeg");var knee:=skeleton.find_bone(side+"Leg");var foot:=skeleton.find_bone(side+"Foot")
        for section:Array in [[thigh,knee,.25,.65],[thigh,knee,.65,1.02],[knee,foot,.05,.95]]:legs.append({"a":section[0],"b":section[1],"start":section[2],"finish":section[3],"side_index":arms.size()-1})
    data=_geometry(cloth,skeleton)
    return true

# Rotate a complete two-bone chain and restore the original global palm
# orientation. The subsequent grip pass closes fingers and places the weapon.
func _solve(visual: Node3D,skeleton: Skeleton3D,row: Dictionary,target: Vector3,body_frame: Transform3D) -> void:
    var shoulder:=skeleton.get_bone_global_pose(row.upper).origin
    var elbow:=skeleton.get_bone_global_pose(row.elbow).origin
    var wrist:=skeleton.get_bone_global_pose(row.wrist).origin
    var hand_basis:=skeleton.get_bone_global_pose(row.wrist).basis.orthonormalized()
    var a:=shoulder.distance_to(elbow);var b:=elbow.distance_to(wrist)
    var direction:Vector3=(target-shoulder).normalized()
    var reach:=clampf(shoulder.distance_to(target),absf(a-b)+.001,a+b-.001)
    target=shoulder+direction*reach
    var bend:Vector3=(elbow-shoulder)-direction*(elbow-shoulder).dot(direction)
    if bend.length_squared()<.000001:
        var pole:Vector3=body_frame.basis*Vector3(float(row.sign)*.3,.05,-1.)
        bend=pole-direction*pole.dot(direction)
    bend=bend.normalized()
    var along:float=(a*a-b*b+reach*reach)/(2.*reach)
    var joint:=shoulder+direction*along+bend*sqrt(maxf(0.,a*a-along*along))
    var to_visual:=visual.global_basis.inverse()*skeleton.global_basis
    visual.call("_align_sitting_bone",skeleton,row.side+"Arm",row.side+"ForeArm",to_visual*(joint-shoulder))
    elbow=skeleton.get_bone_global_pose(row.elbow).origin
    visual.call("_align_sitting_bone",skeleton,row.side+"ForeArm",row.side+"Hand",to_visual*(target-elbow))
    var rotation:=skeleton.get_bone_pose_rotation(row.wrist)
    var frame:=skeleton.get_bone_global_pose(row.wrist).basis.orthonormalized()*Basis(rotation).inverse()
    skeleton.set_bone_pose_rotation(row.wrist,((frame.inverse()*hand_basis).get_rotation_quaternion()).normalized())
    skeleton.force_update_all_bone_transforms()

func _sphere_exit(p: Vector3,direction: Vector3,center: Vector3,radius: float) -> float:
    var q:=p-center;var projection:=q.dot(direction)
    return maxf(0.,-projection+sqrt(maxf(0.,projection*projection-q.length_squared()+radius*radius)))

func _capsule_exit(p: Vector3,direction: Vector3,a: Vector3,b: Vector3,radius: float) -> float:
    var axis:=b-a;var length_squared:=axis.length_squared();var q:=p-a
    var along:=clampf(q.dot(axis)/length_squared,0.,1.)
    if p.distance_squared_to(a+axis*along)>=radius*radius:return 0.
    var axis_direction:=axis.dot(direction);var axis_point:=axis.dot(q)
    var aa:=length_squared-axis_direction*axis_direction
    if aa<.000001:return _sphere_exit(p,direction,a if axis_direction<0 else b,radius)
    var bb:=length_squared*q.dot(direction)-axis_point*axis_direction
    var cc:=length_squared*(q.length_squared()-radius*radius)-axis_point*axis_point
    var distance:=(-bb+sqrt(maxf(0.,bb*bb-aa*cc)))/aa
    var hit:=axis_point+distance*axis_direction
    return maxf(0.,distance) if hit>=0 and hit<=length_squared else _sphere_exit(p,direction,a if hit<0 else b,radius)

func apply(visual: Node3D,skeleton: Skeleton3D) -> void:
    var started:=Time.get_ticks_usec();last_changed_arms=0;last_max_shift_m=0.
    var clip:String=visual.get("animation_player").assigned_animation
    if clip in ["Bow_Attack_Draw","Bow_Attack_Shoot","Sleeping","Death"]:last_usec=Time.get_ticks_usec()-started;return
    if mesh_ref==null or not is_instance_valid(mesh_ref.get_ref()):
        if not _setup(visual,skeleton):return
    var cloth:=mesh_ref.get_ref() as MeshInstance3D
    var build:=clampf(cloth.get_blend_shape_value(build_index),-.5,.5)
    var low:=0 if build<0 else 1;var amount:float=(build-float(PROFILE_BUILDS[low]))/.5
    var box:Vector4=(data.boxes[low] as Vector4).lerp(data.boxes[low+1],amount)
    var cuff:Vector2=(data.cuffs[low] as Vector2).lerp(data.cuffs[low+1],amount)
    var hip_pose:=skeleton.get_bone_global_pose(hips)
    var body_frame:=Transform3D((hip_pose.basis*rest_basis.inverse()*rest_axes).orthonormalized(),hip_pose.origin)
    var inverse:=body_frame.affine_inverse();var center:=Vector2((box.x+box.y)*.5,(box.z+box.w)*.5)
    var half:=Vector2((box.y-box.x)*.5,(box.w-box.z)*.5)
    var capsules:=[]
    for i in range(legs.size()):
        var row:Dictionary=legs[i];var a:=skeleton.get_bone_global_pose(row.a).origin;var b:=skeleton.get_bone_global_pose(row.b).origin
        var radius:float=lerpf(float(data.leg_radii[low][i]),float(data.leg_radii[low+1][i]),amount)
        capsules.append([a.lerp(b,float(row.start)),a.lerp(b,float(row.finish)),radius])
    for side in range(2):
        var row:Dictionary=arms[side];var original:=skeleton.get_bone_global_pose(row.wrist).origin
        var changed:=false
        for iteration in range(2):
            var elbow:=skeleton.get_bone_global_pose(row.elbow).origin;var wrist:=skeleton.get_bone_global_pose(row.wrist).origin;var push:=0.0
            for t:float in [.5,.8,1.]:
                var point:=elbow.lerp(wrist,t);var p:Vector3=inverse*point
                var height:=smoothstep(-.26,-.20,p.y)*(1.-smoothstep(.16,.24,p.y))
                var depth:float=absf(p.z-center.y)/(half.y+float(cuff[side])+.005)
                if height>0 and depth<1.:
                    var width:=half.x*sqrt(maxf(0.,1.-depth*depth))+float(cuff[side])+.005
                    push=maxf(push,(width-float(row.sign)*(p.x-center.x))*height/maxf(t,.6))
                for capsule:Array in capsules:
                    var distance:=_capsule_exit(point,body_frame.basis.x*float(row.sign),capsule[0],capsule[1],float(capsule[2])+float(cuff[side])+.004)
                    push=maxf(push,distance/maxf(t,.6))
            var budget:=maxf(0.,MAX_SHIFT-wrist.distance_to(original));push=minf(push,budget)
            if push<.0001:break
            _solve(visual,skeleton,row,wrist+body_frame.basis.x*float(row.sign)*push,body_frame);changed=true
        if changed:last_changed_arms+=1;last_max_shift_m=maxf(last_max_shift_m,skeleton.get_bone_global_pose(row.wrist).origin.distance_to(original))
    last_usec=Time.get_ticks_usec()-started
