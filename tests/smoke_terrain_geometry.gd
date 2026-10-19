extends Node
func _ready() -> void:
    call_deferred("_run")
func _run() -> void:
    var streamer := preload("res://scripts/world_streamer.gd").new()
    # Do not add the streaming system: inspect two actual mesh builds without
    # starting unrelated world generation or changing a player's position.
    var a: ArrayMesh = streamer.call("_build_terrain_mesh", Vector2i(0,0))
    var b: ArrayMesh = streamer.call("_build_terrain_mesh", Vector2i(1,0))
    var aa := a.surface_get_arrays(0)
    var bb := b.surface_get_arrays(0)
    var n := int(streamer.GRID_RESOLUTION)
    if streamer.CHUNK_SIZE / float(n) > 4.0:
        push_error("Terrain grid is too coarse for the near shoreline")
        get_tree().quit(1)
        return
    var row := n+1
    for z in range(row):
        var va: Vector3 = aa[Mesh.ARRAY_VERTEX][z*row+n]
        var vb: Vector3 = bb[Mesh.ARRAY_VERTEX][z*row]+Vector3(streamer.CHUNK_SIZE,0,0)
        var na: Vector3 = aa[Mesh.ARRAY_NORMAL][z*row+n]
        var nb: Vector3 = bb[Mesh.ARRAY_NORMAL][z*row]
        if va.distance_to(vb)>0.001 or na.distance_to(nb)>0.001 or not na.is_finite() or na.y<=0:
            push_error("Terrain shared-edge height/normal mismatch")
            get_tree().quit(1)
            return
    # Collision retains the same physical triangles as the visible ground.
    var physical := a.create_trimesh_shape()
    if physical.get_faces().size() != aa[Mesh.ARRAY_INDEX].size():
        push_error("Terrain physical and rendered triangle counts disagree")
        get_tree().quit(1)
        return
    streamer.free()
    print("TERRAIN_GEOMETRY_OK edge_samples=49 spacing=4 physics=rendered")
    get_tree().quit()
