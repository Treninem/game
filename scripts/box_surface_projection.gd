extends RefCounted

# Static, axis-aligned architecture does not need three texture projections
# per fragment. Bake the same world projection into its existing24 vertices.
# Rotated/blended faces retain the original material rather than changing art.
static func build(size: Vector3, frame: Transform3D, uv_scale: Vector3, uv_offset: Vector3) -> ArrayMesh:
    if not frame.is_finite() or frame.basis.determinant() <= 0.000001:
        return null
    var normal_frame := frame.basis.inverse().transposed()
    for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
        var direction := (normal_frame * axis).normalized().abs()
        if maxf(direction.x, maxf(direction.y, direction.z)) < .999999:
            return null
    var source := BoxMesh.new()
    source.size = size
    var arrays := source.get_mesh_arrays()
    var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var coordinates := PackedVector2Array()
    var tangents := PackedFloat32Array()
    coordinates.resize(points.size())
    tangents.resize(points.size() * 4)
    var inverse := frame.basis.inverse()
    for index in range(points.size()):
        var normal := (normal_frame * normals[index]).normalized()
        var point := (frame * points[index]) * uv_scale + uv_offset
        var tangent: Vector3
        var binormal: Vector3
        # Match StandardMaterial3D's world triplanar axes, including its V
        # direction and tangent handedness, while keeping all PBR textures.
        if absf(normal.x) > .999999:
            coordinates[index] = Vector2(-point.z, -point.y)
            tangent = Vector3.FORWARD
            binormal = Vector3.UP
        elif absf(normal.y) > .999999:
            coordinates[index] = Vector2(point.x, point.z)
            tangent = Vector3.RIGHT
            binormal = Vector3.FORWARD
        else:
            coordinates[index] = Vector2(point.x, -point.y)
            tangent = Vector3.RIGHT
            binormal = Vector3.UP
        var local_tangent := inverse * tangent
        # The source mesh normals have already passed through16bit packing.
        # Keep the authored tangent orthogonal before its own packing step.
        local_tangent = (local_tangent - normals[index] * local_tangent.dot(normals[index])).normalized()
        var local_binormal := (inverse * binormal).normalized()
        tangents[index * 4] = local_tangent.x
        tangents[index * 4 + 1] = local_tangent.y
        tangents[index * 4 + 2] = local_tangent.z
        tangents[index * 4 + 3] = signf(normals[index].cross(local_tangent).dot(local_binormal))
    arrays[Mesh.ARRAY_TEX_UV] = coordinates
    arrays[Mesh.ARRAY_TANGENT] = tangents
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return result

static func material(source: StandardMaterial3D) -> StandardMaterial3D:
    var result := source.duplicate(false) as StandardMaterial3D
    result.uv1_triplanar = false
    result.uv1_world_triplanar = false
    # Scale and offset are already baked into the metric UV coordinates.
    result.uv1_scale = Vector3.ONE
    result.uv1_offset = Vector3.ZERO
    return result
