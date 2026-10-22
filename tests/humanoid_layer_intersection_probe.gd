extends RefCounted

# Proper 3D triangle crossings, independent of runtime clearance envelopes.
# Edge/plane distance is a diagnostic, not a count of visible clothing defects.

const CELL := .05
var inner: RefCounted
var outer: RefCounted
var snapshots := 0
var outer_components := PackedInt32Array()

func setup(visual: Node3D,skeleton: Skeleton3D,inner_role: String="VikingPants",outer_part: String="Clothing",outer_role: String="VikingTunic") -> void:
    inner=preload("res://tests/humanoid_clothed_skin_probe.gd").new()
    outer=preload("res://tests/humanoid_clothed_skin_probe.gd").new()
    inner.cache(visual,skeleton,"Clothing",inner_role)
    outer.cache(visual,skeleton,outer_part,outer_role)
    assert(inner.complete.size()>300 and outer.complete.size()>300,"Missing real garment geometry")

func snapshot(skeleton: Skeleton3D) -> void:
    inner.snapshot(skeleton);outer.snapshot(skeleton);snapshots+=1

static func _bounds(a: Vector3,b: Vector3,c: Vector3) -> AABB:
    return AABB(a,Vector3.ZERO).expand(b).expand(c).grow(.000001)

static func _edge_depth(a: Vector3,b: Vector3,p: Vector3,q: Vector3,r: Vector3) -> float:
    var normal := (q-p).cross(r-p).normalized()
    var da := (a-p).dot(normal)
    var db := (b-p).dot(normal)
    # Shared edges/tangent contact are not a surface passing through another.
    if da*db>=-0.000000000001:return 0.0
    var hit: Variant=Geometry3D.segment_intersects_triangle(a,b,p,q,r)
    return minf(absf(da),absf(db)) if hit!=null else 0.0

static func _crossing(a: Vector3,b: Vector3,c: Vector3,p: Vector3,q: Vector3,r: Vector3) -> float:
    var depth := 0.0
    for edge: Array in [[a,b],[b,c],[c,a]]:depth=maxf(depth,_edge_depth(edge[0],edge[1],p,q,r))
    for edge: Array in [[p,q],[q,r],[r,p]]:depth=maxf(depth,_edge_depth(edge[0],edge[1],a,b,c))
    return depth

static func canaries() -> void:
    var a := Vector3(-1,-1,0)
    var b := Vector3(1,-1,0)
    var c := Vector3(0,1,0)
    assert(_crossing(a,b,c,Vector3(0,-.5,-1),Vector3(0,-.5,1),Vector3(0,.5,0))>.4)
    assert(_crossing(a,b,c,a+Vector3.BACK*.01,b+Vector3.BACK*.01,c+Vector3.BACK*.01)==0)

func scan() -> Dictionary:
    assert(snapshots>0)
    var began := Time.get_ticks_usec()
    var tiles := {}
    var bounds := []
    for i in range(0,outer.complete.size(),3):
        var box := _bounds(outer.last_points[outer.complete[i]],outer.last_points[outer.complete[i+1]],outer.last_points[outer.complete[i+2]])
        bounds.append(box)
        var low := (box.position/CELL).floor()
        var high := (box.end/CELL).floor()
        for z in range(int(low.z),int(high.z)+1):
            for y in range(int(low.y),int(high.y)+1):
                for x in range(int(low.x),int(high.x)+1):
                    var key := Vector3i(x,y,z)
                    if not tiles.has(key):tiles[key]=PackedInt32Array()
                    tiles[key].append(i)
    var crossed := 0
    var over_half_mm := 0
    var maximum := 0.0
    var witnesses := []
    var worst := {}
    var candidates := 0
    var by_component := {}
    for i in range(0,inner.complete.size(),3):
        var a: Vector3=inner.last_points[inner.complete[i]]
        var b: Vector3=inner.last_points[inner.complete[i+1]]
        var c: Vector3=inner.last_points[inner.complete[i+2]]
        var box := _bounds(a,b,c)
        var low := (box.position/CELL).floor()
        var high := (box.end/CELL).floor()
        var seen := {}
        for z in range(int(low.z),int(high.z)+1):
            for y in range(int(low.y),int(high.y)+1):
                for x in range(int(low.x),int(high.x)+1):
                    for j: int in tiles.get(Vector3i(x,y,z),PackedInt32Array()):seen[j]=true
        for j: int in seen:
            if not box.intersects(bounds[j/3]):continue
            candidates+=1
            var p: Vector3=outer.last_points[outer.complete[j]]
            var q: Vector3=outer.last_points[outer.complete[j+1]]
            var rr: Vector3=outer.last_points[outer.complete[j+2]]
            var depth := _crossing(a,b,c,p,q,rr)
            if depth<=0:continue
            crossed+=1
            if depth>.0005:
                over_half_mm+=1
                if not outer_components.is_empty():
                    var label:int=outer_components[outer.complete[j]]
                    by_component[str(label)]=int(by_component.get(str(label),0))+1
            if depth>maximum:
                worst={"inner_triangle":i/3,"outer_triangle":j/3,"edge_plane_depth_m":depth,
                    "inner_rest":[inner.identities[inner.complete[i]],inner.identities[inner.complete[i+1]],inner.identities[inner.complete[i+2]]],
                    "outer_rest":[outer.identities[outer.complete[j]],outer.identities[outer.complete[j+1]],outer.identities[outer.complete[j+2]]],
                    "inner_points":[a,b,c],"outer_points":[p,q,rr]}
            maximum=maxf(maximum,depth)
            if witnesses.size()<8:witnesses.append({"inner_triangle":i/3,"outer_triangle":j/3,"edge_plane_depth_m":depth,"inner_rest_heights":[inner.positions[inner.complete[i]].y,inner.positions[inner.complete[i+1]].y,inner.positions[inner.complete[i+2]].y]})
    return {"crossing_pairs":crossed,"crossings_over_half_mm":over_half_mm,"by_component":by_component,"max_edge_plane_depth_m":maximum,"candidate_pairs":candidates,"usec":Time.get_ticks_usec()-began,"witnesses":witnesses,"worst":worst}
