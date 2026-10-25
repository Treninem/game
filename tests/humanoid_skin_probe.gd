extends RefCounted

# Independent acceptance oracle: evaluate every existing boot vertex and all
# skin/morph influences, rather than the runtime's sparse support grid.
var boot: MeshInstance3D
var vertices := []
var bindings := []

func points(visual: Node3D, skeleton: Skeleton3D) -> Dictionary:
    var current := visual.find_child("Boots", true, false) as MeshInstance3D
    if not is_instance_valid(boot) or boot != current:
        boot = current
        _cache(skeleton)
    var transforms := []
    for binding: Array in bindings:
        transforms.append(skeleton.get_bone_global_pose(binding[0]) * (binding[1] as Transform3D))
    var blend_weights := []
    for shape in range(boot.get_blend_shape_count()):
        blend_weights.append(boot.get_blend_shape_value(shape))
    var result := {"Left": PackedVector3Array(), "Right": PackedVector3Array()}
    for entry: Array in vertices:
        var vertex: Vector3 = entry[0]
        for shape in range(blend_weights.size()):
            var value: Vector3 = entry[2][shape]
            if (boot.mesh as ArrayMesh).blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED:
                value -= entry[0]
            vertex += value * float(blend_weights[shape])
        var point := Vector3.ZERO
        for influence: Array in entry[1]:
            point += ((transforms[influence[0]] as Transform3D) * vertex) * float(influence[1])
        result[entry[3]].append(skeleton.to_global(point))
    return result

func _cache(skeleton: Skeleton3D) -> void:
    vertices.clear()
    bindings.clear()
    for slot in range(boot.skin.get_bind_count()):
        var bone := boot.skin.get_bind_bone(slot)
        if not boot.skin.get_bind_name(slot).is_empty():
            bone = skeleton.find_bone(boot.skin.get_bind_name(slot))
        bindings.append([bone, boot.skin.get_bind_pose(slot)])
    for surface in range(boot.mesh.get_surface_count()):
        var arrays := boot.mesh.surface_get_arrays(surface)
        var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
        var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
        var shapes: Array = (boot.mesh as ArrayMesh).surface_get_blend_shape_arrays(surface)
        var count := bones.size() / positions.size()
        for vertex in range(positions.size()):
            var influences := []
            var maximum := 0.0
            var side := ""
            for influence in range(count):
                var index := vertex * count + influence
                if weights[index] <= 0:
                    continue
                influences.append([bones[index], weights[index]])
                if weights[index] > maximum:
                    maximum = weights[index]
                    side = "Left" if String(skeleton.get_bone_name(bindings[bones[index]][0])).begins_with("Left") else "Right"
            var values := []
            for shape: Array in shapes:
                values.append((shape[Mesh.ARRAY_VERTEX] as PackedVector3Array)[vertex])
            vertices.append([positions[vertex], influences, values, side])
