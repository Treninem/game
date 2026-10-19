extends Node

func _ready() -> void:
    var streamer := preload("res://scripts/world_streamer.gd").new()
    var failures: Array[String] = []
    var contours := 0
    var maximum_error := 0.0
    var meshes: Array[ArrayMesh] = []
    var level: float = preload("res://scripts/world_geography.gd").START_RIVER_WATER_LEVEL
    var started := Time.get_ticks_msec()
    for coord in [Vector2i(0,-1), Vector2i(0,0)]:
        var mesh: ArrayMesh = streamer.call("_build_terrain_mesh", coord)
        meshes.append(mesh)
        var arrays := mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        var origin := Vector3(coord.x * streamer.CHUNK_SIZE, 0.0, coord.y * streamer.CHUNK_SIZE)
        var base_vertices := (streamer.GRID_RESOLUTION + 1) * (streamer.GRID_RESOLUTION + 1)
        if vertices.size() > base_vertices * 1.35:
            failures.append("Shore refinement exceeded bounded vertex overhead")
        for triangle in range(0, indices.size(), 3):
            for edge in range(3):
                var a := vertices[indices[triangle + edge]] + origin
                var b := vertices[indices[triangle + (edge + 1) % 3]] + origin
                if (a.y-level)*(b.y-level) > 0.0 or absf(a.y-b.y) < 0.000001:
                    continue
                var point := a.lerp(b, clampf((level-a.y)/(b.y-a.y),0.0,1.0))
                var error := absf(WorldData.elevation_at(Vector2(point.x,point.z))-level)
                maximum_error = maxf(maximum_error,error)
                contours += 1
        var physical := mesh.create_trimesh_shape()
        if physical.get_faces().size() != indices.size():
            failures.append("Refined shoreline physics no longer uses the rendered triangles")
    if contours < 80 or maximum_error > 0.002:
        failures.append("Rendered shore misses the physical height field: samples=%s error=%s" % [contours,maximum_error])
    # Both chunks must add the same shore intersections at their common edge.
    var edge_a := _edge_points(meshes[0], streamer.CHUNK_SIZE, Vector3(0,0,-streamer.CHUNK_SIZE))
    var edge_b := _edge_points(meshes[1], 0.0, Vector3.ZERO)
    if edge_a.size() != edge_b.size():
        failures.append("Refinement opens a chunk boundary")
    for key in edge_a:
        if not edge_b.has(key) or (edge_a[key] as Vector3).distance_to(edge_b.get(key,Vector3.INF)) > 0.001:
            failures.append("Refined edge height or normal mismatch")
            break
    streamer.free()
    print("RIVER_SHORELINE_METRICS contours=",contours," max_height_error=",maximum_error," milliseconds=",Time.get_ticks_msec()-started)
    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        get_tree().quit(1)
        return
    print("RIVER_SHORELINE_SMOKE_OK")
    get_tree().quit()

func _edge_points(mesh: ArrayMesh, edge_z: float, origin: Vector3) -> Dictionary:
    var result := {}
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    for i in range(vertices.size()):
        if absf(vertices[i].z-edge_z) < 0.0001:
            var world := vertices[i]+origin
            result[Vector2(roundf(world.x*1000),roundf(world.y*1000))] = normals[i]
    return result
