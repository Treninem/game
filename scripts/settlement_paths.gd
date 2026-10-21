extends RefCounted

const PATHS := preload("res://scripts/terrain_paths.gd")
const GATES := preload("res://scripts/settlement_gate_network.gd")

# Street design, not NPC waypoints. The actual entrances and house footprints
# determine access; existing home positions/door persistence IDs stay stable.
static func build_village(root: Node3D) -> void:
    if root.has_node("VillageLanes"): return
    var began := Time.get_ticks_usec()
    var houses: Array[Node3D] = []
    for child in root.get_children():
        if child is EnterableBuilding: houses.append(child)
    var wet_cells: Dictionary = {}
    var street_grid := _grid(root, houses, 3.3, wet_cells)
    var center := Vector2(root.global_position.x, root.global_position.z)
    var gate_specs := GATES.local_gate_specs(center,root.rotation.y,Vector2(78,68),5.0)
    var streets: Array[PackedVector2Array] = []
    var network: Array[Vector2] = [Vector2.ZERO]
    var street_paths: Array[PackedVector2Array] = []
    for gate in gate_specs:
        var endpoint: Vector2 = gate.point
        # Stop just inside the perimeter: the gate overlay owns the outside.
        endpoint -= endpoint.normalized()*2.0
        var path := street_grid.get_point_path(Vector2i(endpoint.round()), Vector2i.ZERO)
        if path.is_empty():
            push_error("Village gate has no clear street to the square")
            continue
        street_paths.append(path)
        _append_path(root, streets, path, 5.5)
        for point in path: network.append(point)
    var lanes := PATHS.add(root,"VillageLanes",streets,"gravel",0.035)
    if lanes != null: lanes.set_meta("local_paths",street_paths)

    var foot_grid := _grid(root,houses,1.15, wet_cells)
    var connected := 0
    for house in houses:
        var entrance3 := root.to_local(house.to_global(Vector3(0,0,house.footprint.y*0.5+2.4)))
        var entrance := Vector2(entrance3.x,entrance3.z)
        var goal := Vector2.ZERO
        var distance := INF
        for candidate in network:
            if candidate.distance_squared_to(entrance) < distance:
                distance = candidate.distance_squared_to(entrance)
                goal = candidate
        var start_id := Vector2i(entrance.round())
        var goal_id := Vector2i(goal.round())
        if foot_grid.is_point_solid(start_id) or foot_grid.is_point_solid(goal_id):
            push_error("Village entrance cannot reach street: %s" % house.name)
            continue
        var path := foot_grid.get_point_path(start_id,goal_id)
        if path.is_empty():
            push_error("Village street access is disconnected: %s" % house.name)
            continue
        path.insert(0,entrance)
        var threshold := root.to_local(house.to_global(Vector3(0,0,house.footprint.y*0.5+0.15)))
        path.insert(0,Vector2(threshold.x,threshold.z))
        var polygons: Array[PackedVector2Array] = []
        _append_path(root,polygons,path,1.8)
        var visual := PATHS.add(root,"HomeAccess_"+house.name,polygons,"soil",0.045)
        if visual != null:
            visual.set_meta("home_path",str(house.get_path()))
            visual.set_meta("local_path",path)
            visual.set_meta("clear_width",1.8)
            connected += 1
    root.set_meta("connected_home_entrances",connected)
    root.set_meta("street_gate_links",gate_specs.size())
    root.set_meta("path_build_ms",float(Time.get_ticks_usec()-began)/1000.0)

static func _grid(root: Node3D,houses: Array[Node3D],clearance: float,wet_cells: Dictionary = {}) -> AStarGrid2D:
    var result := AStarGrid2D.new()
    result.region = Rect2i(-78,-68,157,137)
    result.cell_size = Vector2.ONE
    result.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    result.update()
    # Rasterize only each house's nearby cells, rather than transform every cell
    # through every house twice on the streaming frame.
    for house in houses:
        var relative := root.global_transform.affine_inverse()*house.global_transform
        var basis := Transform2D(Vector2(relative.basis.x.x,relative.basis.x.z),
            Vector2(relative.basis.z.x,relative.basis.z.z),Vector2(relative.origin.x,relative.origin.z))
        var half: Vector2 = house.footprint*0.5+Vector2.ONE*clearance
        var area := Rect2(basis*(-half),Vector2.ZERO)
        for side in [Vector2(-1,1),Vector2(1,-1),Vector2.ONE]: area = area.expand(basis*(half*side))
        var inverse := basis.affine_inverse()
        for z in range(maxi(-68,floori(area.position.y)),mini(68,ceili(area.end.y))+1):
            for x in range(maxi(-78,floori(area.position.x)),mini(78,ceili(area.end.x))+1):
                var p := inverse*Vector2(x,z)
                if absf(p.x)<half.x and absf(p.y)<half.y: result.set_point_solid(Vector2i(x,z))
    for obstacle in [Rect2(-10,1,4,4),Rect2(10,6,5,5),Rect2(-16,7,5,4)]:
        var area: Rect2 = obstacle.grow(clearance)
        result.fill_solid_region(Rect2i(Vector2i(area.position.floor()),Vector2i(area.size.ceil())+Vector2i.ONE))
    # Conservative four-metre wet cells share the terrain sampling scale; cache
    # them for both street and pedestrian grids during this one materialization.
    for z in range(-68,69,4):
        for x in range(-78,79,4):
            var key := Vector2i(x,z)
            if not wet_cells.has(key):
                var wet := false
                for offset in [Vector2.ZERO,Vector2(4,0),Vector2(0,4),Vector2(4,4)]:
                    var world := root.to_global(Vector3(x+offset.x,0,z+offset.y))
                    if not WorldData.water_kind_at(Vector2(world.x,world.z)).is_empty(): wet = true
                wet_cells[key] = wet
            if wet_cells[key]: result.fill_solid_region(Rect2i(key,Vector2i(5,5)).intersection(result.region))
    return result

static func _append_path(root: Node3D,polygons: Array[PackedVector2Array],path: PackedVector2Array,width: float) -> void:
    if path.size()<2: return
    var simplified := PackedVector2Array([path[0]])
    for i in range(1,path.size()-1):
        if (path[i]-path[i-1]).normalized().dot((path[i+1]-path[i]).normalized())<0.999:
            simplified.append(path[i])
    simplified.append(path[-1])
    for i in range(simplified.size()-1):
        var a := root.to_global(Vector3(simplified[i].x,0,simplified[i].y))
        var b := root.to_global(Vector3(simplified[i+1].x,0,simplified[i+1].y))
        if a.distance_squared_to(b)>0.001:
            polygons.append(PATHS.strip(Vector2(a.x,a.z),Vector2(b.x,b.z),width))
    for point in simplified:
        polygons.append(PATHS.rectangle(root,point,Vector2.ONE*width*0.7))
