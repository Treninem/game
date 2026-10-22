extends RefCounted

# Independent anatomical oracle. Build-time garment coverage uses surface
# proximity; this probe selects clothed torso/limbs from bone influences and
# measures their ACTUAL final deformed pixels against the rendered garments.
var body: MeshInstance3D
var positions := PackedVector3Array()
var weights := []
var deltas := []
var bindings := []
var clothed := PackedInt32Array()
var complete := PackedInt32Array()
var identities := []
var last_points := PackedVector3Array()
var cached_morphs := []
var morphed := PackedVector3Array()

func cache(visual: Node3D,skeleton: Skeleton3D) -> void:
    body = visual.find_child("HumanBody",true,false) as MeshInstance3D
    for slot in range(body.skin.get_bind_count()):
        var bone := body.skin.get_bind_bone(slot)
        if not body.skin.get_bind_name(slot).is_empty():
            bone=skeleton.find_bone(body.skin.get_bind_name(slot))
        bindings.append([bone,body.skin.get_bind_pose(slot)])
    var allowed := ["Spine","Spine1","Spine2","Hips"]
    for side: String in ["Left","Right"]:
        for part: String in ["Arm","ForeArm","UpLeg","Leg","Foot","ToeBase"]:allowed.append(side+part)
    var left := skeleton.get_bone_global_rest(skeleton.find_bone("LeftHand")).origin
    var right := skeleton.get_bone_global_rest(skeleton.find_bone("RightHand")).origin
    # The V-shaped collar intentionally exposes upper chest skin. Exclude its
    # 18cm neck region from the clothed anatomical oracle, as well as wrists.
    var neck := skeleton.get_bone_global_rest(skeleton.find_bone("Neck")).origin
    for surface in range(body.mesh.get_surface_count()):
        var arrays := body.mesh.surface_get_arrays(surface)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
        var values: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
        var shapes := (body.mesh as ArrayMesh).surface_get_blend_shape_arrays(surface)
        var count := bones.size()/vertices.size()
        var offset := positions.size()
        var selected: Array[bool] = []
        for vertex in range(vertices.size()):
            positions.append(vertices[vertex])
            var influences := []
            var largest := -1.0
            var dominant := ""
            var rest := Vector3.ZERO
            for influence in range(count):
                var index := vertex*count+influence
                if values[index]<=0:continue
                var slot := bones[index]
                influences.append([slot,values[index]])
                var bone: int = bindings[slot][0]
                rest += (skeleton.get_bone_global_rest(bone)*(bindings[slot][1] as Transform3D)*vertices[vertex])*values[index]
                if values[index]>largest:
                    largest=values[index]
                    dominant=String(skeleton.get_bone_name(bone))
            weights.append(influences)
            var changes := PackedVector3Array()
            for shape: Array in shapes:
                var point: Vector3 = shape[Mesh.ARRAY_VERTEX][vertex]
                if (body.mesh as ArrayMesh).blend_shape_mode==Mesh.BLEND_SHAPE_MODE_NORMALIZED:point-=vertices[vertex]
                changes.append(point)
            deltas.append(changes)
            selected.append(dominant in allowed and minf(rest.distance_to(left),rest.distance_to(right))>.09 and rest.distance_to(neck)>.18)
            identities.append({"dominant":dominant,"rest":[rest.x,rest.y,rest.z],"neck_delta":[rest.x-neck.x,rest.y-neck.y,rest.z-neck.z]})
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        for i in range(0,indices.size(),3):
            for j in range(3):complete.append(indices[i+j]+offset)
            if not (selected[indices[i]] and selected[indices[i+1]] and selected[indices[i+2]]):continue
            for j in range(3):clothed.append(indices[i+j]+offset)

func snapshot(skeleton: Skeleton3D) -> PackedVector3Array:
    var transforms := []
    for binding: Array in bindings:transforms.append(skeleton.get_bone_global_pose(binding[0])*(binding[1] as Transform3D))
    var morphs := []
    for shape in range(body.get_blend_shape_count()):morphs.append(body.get_blend_shape_value(shape))
    if cached_morphs!=morphs or morphed.size()!=positions.size():
        cached_morphs=morphs.duplicate()
        morphed.resize(positions.size())
        for i in range(positions.size()):
            var point := positions[i]
            for shape in range(morphs.size()):
                if not is_zero_approx(float(morphs[shape])):point+=(deltas[i] as PackedVector3Array)[shape]*float(morphs[shape])
            morphed[i]=point
    var result := PackedVector3Array()
    result.resize(positions.size())
    for i in range(positions.size()):
        var point := morphed[i]
        var deformed := Vector3.ZERO
        for influence: Array in weights[i]:deformed+=((transforms[influence[0]] as Transform3D)*point)*float(influence[1])
        result[i]=skeleton.to_global(deformed)
    last_points=result
    return result

func diagnose(camera: Camera3D,pixel: Vector2,dimensions: Vector2) -> Dictionary:
    var screen := (pixel+Vector2.ONE*.5)*camera.get_viewport().get_visible_rect().size/dimensions
    var origin := camera.project_ray_origin(screen)
    var direction := camera.project_ray_normal(screen)
    var closest := INF
    var result := {}
    for i in range(0,clothed.size(),3):
        var a := clothed[i]
        var b := clothed[i+1]
        var c := clothed[i+2]
        var hit: Variant=Geometry3D.ray_intersects_triangle(origin,direction,last_points[a],last_points[b],last_points[c])
        if hit==null:continue
        var point: Vector3=hit
        var distance := point.distance_squared_to(origin)
        if distance>=closest:continue
        closest=distance
        result={"pixel":str(pixel),"triangle":[a,b,c],"vertices":[identities[a],identities[b],identities[c]],"hit":str(point)}
    return result
