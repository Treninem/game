extends Node3D

const PATHS := preload("res://scripts/terrain_paths.gd")
const STREAMER := preload("res://scripts/world_streamer.gd")
const ROADS := preload("res://scripts/world_roads.gd")
const SETTLEMENTS := preload("res://scripts/world_settlements.gd")

func _ready() -> void:
    get_tree().create_timer(60).timeout.connect(func(): push_error("Terrain paths watchdog"); get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    var generator := STREAMER.new()
    assert(STREAMER.CHUNK_SIZE/float(STREAMER.GRID_RESOLUTION)==PATHS.GRID)
    var roads := ROADS.new()
    add_child(roads)
    var chunks: Array[Node3D] = []
    for coord in [Vector2i(8,-3),Vector2i(9,-3)]:
        var chunk := Node3D.new()
        chunk.position = Vector3(coord.x*192.0,0,coord.y*192.0)
        add_child(chunk)
        chunks.append(chunk)
        var ground := generator.call("_build_terrain_mesh",coord) as ArrayMesh
        var body := StaticBody3D.new()
        var shape := CollisionShape3D.new()
        shape.shape = ground.create_trimesh_shape()
        chunk.add_child(body)
        body.add_child(shape)
        roads.call("_materialize_chunk",chunk)
    await get_tree().physics_frame
    await get_tree().physics_frame
    var checked := 0
    var max_gap := 0.0
    var seam: Array[PackedVector3Array] = []
    for chunk in chunks:
        var visual := chunk.get_node_or_null("RoadSurface") as MeshInstance3D
        assert(visual != null,"Actual road missing in selected terrain chunk")
        var arrays := visual.mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        var edge := PackedVector3Array()
        for vertex in vertices:
            assert(vertex.x >= -0.005 and vertex.x <=192.005 and vertex.z>=-0.005 and vertex.z<=192.005,"Road leaks beyond its owning chunk")
            var point := visual.to_global(vertex)
            if absf(point.x-1728.0)<0.005: edge.append(point)
        seam.append(edge)
        for triangle in range(0,indices.size(),3):
            var point := visual.to_global((vertices[indices[triangle]]+vertices[indices[triangle+1]]+vertices[indices[triangle+2]])/3.0)
            assert(not PATHS.settlement_owns(Vector2(point.x,point.z)),"World road duplicates the village street layer")
            var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*4,point-Vector3.UP*4)
            var hit := get_world_3d().direct_space_state.intersect_ray(query)
            assert(not hit.is_empty(),"Road has no physical ground beneath it")
            var gap: float = point.y-Vector3(hit.position).y
            assert(absf(gap-PATHS.LIFT)<0.006,"Road floats/sinks relative to actual physical triangles: %s" % gap)
            max_gap = maxf(max_gap,gap)
            checked += 1
    assert(not seam[0].is_empty() and not seam[1].is_empty(),"Road does not reach shared streaming edge")
    for point in seam[0]:
        var nearest := INF
        for other in seam[1]: nearest = minf(nearest,point.distance_to(other))
        assert(nearest<0.006,"Road shared-edge crack: %s" % nearest)
    generator.free()
    var settlements := SETTLEMENTS.new()
    add_child(settlements)
    var homes := 0
    for id in ["border_village_01","border_village_02"]:
        var village: Node3D = settlements.materialize_settlement_for_test(id)
        var expected := 7 if id=="border_village_01" else 8
        assert(int(village.get_meta("connected_home_entrances",0))==expected,"An actual home has no street access")
        assert(village.has_node("VillageLanes"))
        var paving := village.to_global(Vector3(-4,0,10))
        paving.y = WorldData.elevation_at(Vector2(paving.x,paving.z))
        assert(WorldVFX.surface_at(paving)=="stone","Paved village square is treated as grass for footsteps")
        var gravel := village.global_position
        assert(WorldVFX.surface_at(gravel)=="dirt","Loose village road uses grass/stone feedback")
        print("VILLAGE_PATH_BUILD ",id," milliseconds=",village.get_meta("path_build_ms"))
        for access: MeshInstance3D in village.find_children("HomeAccess_*","MeshInstance3D",false,false):
            var path: PackedVector2Array = access.get_meta("local_path")
            var home := get_node(NodePath(access.get_meta("home_path"))) as EnterableBuilding
            var threshold := home.to_local(village.to_global(Vector3(path[0].x,0,path[0].y)))
            assert(absf(threshold.x)<0.01 and absf(threshold.z-home.footprint.y*0.5-0.15)<0.01,"Path misses the actual front door")
            for point in path:
                var world := village.to_global(Vector3(point.x,0,point.y))
                for child in village.get_children():
                    if child is EnterableBuilding:
                        var p: Vector3 = child.to_local(world)
                        assert(absf(p.x)>child.footprint.x*0.5 or absf(p.z)>child.footprint.y*0.5,"Street access cuts through a house")
            homes += 1
    assert(homes==15)
    var signs := preload("res://scripts/start_civilization_signs.gd").new()
    add_child(signs)
    var track := signs.get_node("OldCartTrack/TrackBed") as MeshInstance3D
    assert(track!=null and track.mesh is ArrayMesh,"Forest cart spur still uses floating boxes")
    for vertex: Vector3 in track.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
        assert(vertex.x<654.0,"Legacy cart layer still extends over the primary road into the village")
    assert(signs.road_segment_count>=35,"Forest evidence spur lost its materialized road sections")
    for kind in ["paving","gravel","soil"]:
        var material := PATHS.material(kind)
        assert(material.albedo_texture!=null)
        assert(material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC)
    print("TERRAIN_PATHS_OK physical_triangle_samples=",checked," max_gap_m=",max_gap," chunk_seam=true entrances=",homes," materials=3")
    get_tree().quit(0)
