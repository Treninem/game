extends RefCounted

# Clip road footprints to the SAME four-metre triangles used by WorldStreamer.
# Sampling only the centre of a long box leaves its corners floating on hills.
# These are thin visual overlays; the existing terrain owns physical support.
const GRID := 4.0
const LIFT := 0.006
const MAX_LIFT := 0.012
const CAPITAL := preload("res://scripts/capital_data.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")
static var materials: Dictionary = {}
static var settlement_regions: Array[Dictionary] = []

static func material(kind: String) -> StandardMaterial3D:
    if materials.has(kind):
        return materials[kind]
    var result := StandardMaterial3D.new()
    result.roughness = 0.98
    result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    result.uv1_triplanar = true
    result.uv1_world_triplanar = true
    result.uv1_scale = Vector3.ONE * 0.65
    match kind:
        "paving":
            result.albedo_texture = load("res://assets/production/materials/ground/stone_paving.jpg")
            result.albedo_color = Color(0.65, 0.63, 0.57)
            result.uv1_scale = Vector3.ONE * 0.30
        "gravel":
            result.albedo_texture = load("res://assets/production/materials/ground/road_gravel.png")
            result.albedo_color = Color(0.76, 0.70, 0.58)
            result.uv1_scale = Vector3.ONE * 3.0
        _:
            result.albedo_texture = load("res://assets/production/materials/ground/road_soil.png")
            result.albedo_color = Color(0.91, 0.83, 0.68)
    materials[kind] = result
    return result

static func strip(a: Vector2, b: Vector2, width: float) -> PackedVector2Array:
    var side := Vector2(-(b-a).y, (b-a).x).normalized() * width * 0.5
    return PackedVector2Array([a-side, b-side, b+side, a+side])

static func rectangle(parent: Node3D, center: Vector2, size: Vector2) -> PackedVector2Array:
    var polygon := PackedVector2Array()
    for side in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
        var point := parent.to_global(Vector3(center.x+side.x*size.x*0.5, 0, center.y+side.y*size.y*0.5))
        polygon.append(Vector2(point.x, point.z))
    return polygon

static func build(polygons: Array[PackedVector2Array], transform: Transform3D,
        bounds: Rect2 = Rect2(), exclude_capital: bool = false, lift: float = LIFT) -> ArrayMesh:
    # The terrain owns support. Centimetres of visual separation bury boots;
    # reserve only a small depth-fighting clearance, including stacked layers.
    assert(lift>=LIFT and lift<=MAX_LIFT,"Path overlay exceeds its physical support clearance")
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var inverse := transform.affine_inverse()
    var heights: Dictionary = {}
    var triangles := 0
    for polygon in polygons:
        var clipped: Array[PackedVector2Array] = [polygon]
        if bounds.has_area():
            clipped = Geometry2D.intersect_polygons(polygon, PackedVector2Array([
                bounds.position, bounds.position+Vector2(bounds.size.x,0),
                bounds.end, bounds.position+Vector2(0,bounds.size.y)]))
        if exclude_capital:
            _prepare_regions()
            var masks: Array[PackedVector2Array] = []
            for region in settlement_regions: masks.append(region.polygon)
            var half := Vector2.ONE*(CAPITAL.HALF_EXTENT+0.01)
            masks.append(PackedVector2Array([CAPITAL.CENTER-half,CAPITAL.CENTER+Vector2(half.x,-half.y),
                CAPITAL.CENTER+half,CAPITAL.CENTER+Vector2(-half.x,half.y)]))
            for mask in masks:
                var remaining: Array[PackedVector2Array] = []
                for piece in clipped: remaining.append_array(Geometry2D.clip_polygons(piece,mask))
                clipped = remaining
        for footprint in clipped:
            var area := Rect2(footprint[0], Vector2.ZERO)
            for point in footprint: area = area.expand(point)
            for z in range(floori(area.position.y/GRID), ceili(area.end.y/GRID)):
                for x in range(floori(area.position.x/GRID), ceili(area.end.x/GRID)):
                    var corners := [Vector2(x,z)*GRID, Vector2(x+1,z)*GRID,
                        Vector2(x,z+1)*GRID, Vector2(x+1,z+1)*GRID]
                    for indices in [[0,1,2], [1,3,2]]:
                        var ground := PackedVector2Array([corners[indices[0]],corners[indices[1]],corners[indices[2]]])
                        var pieces := Geometry2D.intersect_polygons(footprint, ground)
                        for piece in pieces:
                            if piece.size() < 3: continue
                            var center := Vector2.ZERO
                            for point in piece: center += point
                            center /= float(piece.size())
                            if not WorldData.water_kind_at(center).is_empty(): continue
                            var a := _corner(ground[0], heights)
                            var b := _corner(ground[1], heights)
                            var c := _corner(ground[2], heights)
                            var normal := (c-a).cross(b-a).normalized()
                            # Ear clipping must operate near zero. At world coordinates
                            # around 15 km, float polygon areas can cancel to zero and
                            # silently drop small clipped road triangles.
                            var local_piece:=PackedVector2Array()
                            for point in piece:local_piece.append(point-piece[0])
                            var triangulation := Geometry2D.triangulate_polygon(local_piece)
                            for index in triangulation:
                                var p := piece[index]
                                var y := a.y - (normal.x*(p.x-a.x)+normal.z*(p.y-a.z))/normal.y
                                tool.set_normal((inverse.basis*normal).normalized())
                                tool.set_uv(p*0.65)
                                tool.add_vertex(inverse*Vector3(p.x,y+lift,p.y))
                            triangles += triangulation.size()/3
    if triangles == 0: return null
    tool.index()
    return tool.commit()

static func add(parent: Node3D, label: String, polygons: Array[PackedVector2Array],
        kind: String, lift: float = LIFT) -> MeshInstance3D:
    var mesh := build(polygons, parent.global_transform, Rect2(), false, lift)
    if mesh == null: return null
    var result := MeshInstance3D.new()
    result.name = label
    result.mesh = mesh
    result.material_override = material(kind)
    result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    result.visibility_range_end = 620.0
    result.set_meta("physical_support", "streamed_world_terrain")
    result.set_meta("path_polygons",polygons)
    result.set_meta("path_lift",lift)
    result.set_meta("path_kind",kind)
    result.set_meta("surface_type","stone" if kind=="paving" else "dirt")
    result.add_to_group("terrain_path_surface")
    parent.add_child(result)
    return result

static func _corner(point: Vector2, cache: Dictionary) -> Vector3:
    if not cache.has(point): cache[point] = WorldData.elevation_at(point)
    return Vector3(point.x, cache[point], point.y)

static func settlement_yaw(center: Vector2) -> float:
    var closest := center+Vector2(0,100)
    var distance := INF
    for road in GEOGRAPHY.PRIMARY_ROADS:
        for point: Vector2 in road.points:
            if point==center: continue
            if point.distance_squared_to(center)<distance:
                distance = point.distance_squared_to(center)
                closest = point
    var toward := (closest-center).normalized()
    return atan2(toward.x,toward.y)

static func settlement_owns(point: Vector2) -> bool:
    _prepare_regions()
    for region in settlement_regions:
        var p: Vector2 = region.inverse*point
        if absf(p.x)<=region.half.x and absf(p.y)<=region.half.y: return true
    return false

static func _prepare_regions() -> void:
    if settlement_regions.is_empty():
        for poi in GEOGRAPHY.POIS:
            if String(poi.id) not in ["border_village_01","border_village_02","first_fortified_town"]: continue
            var center: Vector2 = poi.pos
            var half := Vector2(150,115) if poi.id=="first_fortified_town" else Vector2(78,68)
            var transform := Transform2D(-settlement_yaw(center),center)
            var polygon := PackedVector2Array()
            for side in [Vector2(-1,-1),Vector2(1,-1),Vector2.ONE,Vector2(-1,1)]:
                polygon.append(transform*((half+Vector2.ONE*0.01)*side))
            settlement_regions.append({"inverse":transform.affine_inverse(),"half":half,"polygon":polygon})
