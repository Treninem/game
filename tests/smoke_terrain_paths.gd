extends Node3D

const PATHS := preload("res://scripts/terrain_paths.gd")
const STREAMER := preload("res://scripts/world_streamer.gd")
const ROADS := preload("res://scripts/world_roads.gd")
const SETTLEMENTS := preload("res://scripts/world_settlements.gd")
const TERRAIN_ONLY := 1<<29

func _ready() -> void:
    get_tree().create_timer(60).timeout.connect(func(): push_error("Terrain paths watchdog"); get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    var generator := STREAMER.new()
    assert(STREAMER.CHUNK_SIZE/float(STREAMER.GRID_RESOLUTION)==PATHS.GRID)
    var roads := ROADS.new()
    add_child(roads)
    var chunks: Array[Node3D] = []
    var ground_chunks := {}
    for coord in [Vector2i(8,-3),Vector2i(9,-3)]:
        var chunk := Node3D.new()
        chunk.position = Vector3(coord.x*192.0,0,coord.y*192.0)
        add_child(chunk)
        chunks.append(chunk)
        var ground := generator.call("_build_terrain_mesh",coord) as ArrayMesh
        var body := StaticBody3D.new()
        body.collision_layer=TERRAIN_ONLY
        var shape := CollisionShape3D.new()
        shape.shape = ground.create_trimesh_shape()
        chunk.add_child(body)
        body.add_child(shape)
        roads.call("_materialize_chunk",chunk)
        ground_chunks[coord]=true
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
            query.collision_mask=TERRAIN_ONLY
            var hit := get_world_3d().direct_space_state.intersect_ray(query)
            assert(not hit.is_empty(),"Road has no physical ground beneath it")
            var gap: float = point.y-Vector3(hit.position).y
            assert(absf(gap-PATHS.LIFT)<0.0005,"Road floats/sinks relative to actual physical triangles: %s" % gap)
            assert(gap>0.002 and gap<0.0125,"Road buries soles or intersects terrain")
            max_gap = maxf(max_gap,gap)
            checked += 1
    assert(not seam[0].is_empty() and not seam[1].is_empty(),"Road does not reach shared streaming edge")
    for point in seam[0]:
        var nearest := INF
        for other in seam[1]: nearest = minf(nearest,point.distance_to(other))
        assert(nearest<0.006,"Road shared-edge crack: %s" % nearest)
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
    # Include actual village lanes, squares, door approaches and garden/rut
    # overlays. Dedicated reference-ground collision avoids hitting furniture,
    # plants or a porch instead of the terrain whose support owns these paths.
    var samples := []
    var kinds := {}
    var surface_count := 0
    for surface: MeshInstance3D in get_tree().get_nodes_in_group("terrain_path_surface"):
        var kind := String(surface.get_meta("path_kind",""))
        assert(kind in ["paving","gravel","soil"])
        kinds[kind]=true
        var lift := float(surface.get_meta("path_lift"))
        assert(lift>=0.006 and lift<=0.012,"Surface is too far above physical support: %s" % surface.get_path())
        var arrays := surface.mesh.surface_get_arrays(0)
        var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var ids: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
        var triangles := ids.size()/3
        for triangle: int in [0,int(triangles/2),triangles-1]:
            var i := triangle*3
            var point := surface.to_global((points[ids[i]]+points[ids[i+1]]+points[ids[i+2]])/3.0)
            samples.append({"point":point,"lift":lift,"surface":str(surface.get_path())})
            var coord := Vector2i(floori(point.x/192.0),floori(point.z/192.0))
            if not ground_chunks.has(coord):
                var body := StaticBody3D.new()
                body.collision_layer=TERRAIN_ONLY
                body.position=Vector3(coord.x*192.0,0,coord.y*192.0)
                add_child(body)
                var shape := CollisionShape3D.new()
                shape.shape=(generator.call("_build_terrain_mesh",coord) as ArrayMesh).create_trimesh_shape()
                body.add_child(shape)
                ground_chunks[coord]=true
        surface_count+=1
    await get_tree().physics_frame
    await get_tree().physics_frame
    var local_max := 0.0
    for sample: Dictionary in samples:
        var point: Vector3=sample.point
        var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*4,point-Vector3.UP*4,TERRAIN_ONLY)
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        assert(not hit.is_empty(),"Path has no physical reference terrain: %s" % sample.surface)
        var gap := point.y-Vector3(hit.position).y
        assert(absf(gap-float(sample.lift))<0.0005,"Path loses terrain contact: %s gap=%s" % [sample.surface,gap])
        assert(gap>0.002 and gap<0.0125,"Path buries soles or intersects terrain")
        local_max=maxf(local_max,gap)
    assert(surface_count>=30 and kinds.size()==3)
    _verify_far_coverage()
    generator.free()
    print("PATH_SUPPORT_OK surfaces=",surface_count," ray_samples=",samples.size()," max_gap_m=",local_max," materials=3")
    print("TERRAIN_PATHS_OK physical_triangle_samples=",checked," max_gap_m=",max_gap," chunk_seam=true entrances=",homes," materials=3")
    get_tree().quit(0)

func _verify_far_coverage() -> void:
    # This actual far-city strip previously lost 52 of its 800 square metres.
    # Test the produced mesh, not only the triangles that happened to survive.
    var footprints:Array[PackedVector2Array]=[PATHS.strip(Vector2(14654,-7140),Vector2(14654,-7040),8)]
    var transform:=Transform3D(Basis.IDENTITY,Vector3(14620,0,-7160))
    var mesh:ArrayMesh=PATHS.build(footprints,transform)
    assert(mesh!=null,"Far city path disappeared")
    var arrays:=mesh.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
    var area:=0.
    for index in range(0,ids.size(),3):
        var a:=vertices[ids[index]];var b:=vertices[ids[index+1]];var c:=vertices[ids[index+2]]
        area+=absf((b.x-a.x)*(c.z-a.z)-(b.z-a.z)*(c.x-a.x))*.5
    assert(absf(area-800)<.025,"Far path has unmeshed holes: %sm2 instead of800"%area)
    for z in range(-7139,-7040,2):
        for x in range(14651,14658,2):
            var point:=Vector2(x,z);var covered:=false
            for index in range(0,ids.size(),3):
                var a:=transform*vertices[ids[index]];var b:=transform*vertices[ids[index+1]];var c:=transform*vertices[ids[index+2]]
                var origin:=Vector2(a.x,a.z)
                if Geometry2D.is_point_in_polygon(point-origin,PackedVector2Array([Vector2.ZERO,Vector2(b.x,b.z)-origin,Vector2(c.x,c.z)-origin])):
                    covered=true;break
            assert(covered,"Far path contains an uncovered walkable sample at"+str(point))
    print("FAR_PATH_COVERAGE_OK actual_area_m2=",area," expected_m2=800 original_assertions_retained=true")
