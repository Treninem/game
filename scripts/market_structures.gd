extends RefCounted

const ARCADE := preload("res://assets/production/architecture/market_arcade/MarketArcade.glb")
const MATERIALS := preload("res://scripts/modular_city_facades.gd")
static var shape_refs: Dictionary = {}

static func physical_mesh(body:StaticBody3D,visual:Node3D,key:String,cloth:bool=false) -> CollisionShape3D:
    var reference:WeakRef=shape_refs.get(key)
    var shape:=reference.get_ref() as ConcavePolygonShape3D if reference!=null else null
    if shape==null:
        var faces:=PackedVector3Array()
        var inverse:=body.global_transform.affine_inverse()
        for mesh:MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
            var transform:=inverse*mesh.global_transform
            for slot in range(mesh.mesh.get_surface_count()):
                var material:=mesh.mesh.surface_get_material(slot)
                if cloth and material!=null and material.resource_name=="MI_Banner":continue
                var arrays:=mesh.mesh.surface_get_arrays(slot)
                var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
                if indices.is_empty():
                    for vertex:Vector3 in vertices:faces.append(transform*vertex)
                else:
                    for index in indices:faces.append(transform*vertices[index])
        assert(faces.size()>=3)
        shape=ConcavePolygonShape3D.new();shape.set_faces(faces)
        shape.backface_collision=true
        var bounds:=AABB(faces[0],Vector3.ZERO)
        for point:Vector3 in faces:bounds=bounds.expand(point)
        shape.set_meta("navigation_local_bounds",bounds)
        shape_refs[key]=weakref(shape)
    var collision:=CollisionShape3D.new();collision.name="MeasuredStructureCollision";collision.shape=shape;body.add_child(collision)
    body.set_meta("structural_triangle_collision",true)
    return collision

static func build_arcade(square:Node3D) -> Node3D:
    var body:=StaticBody3D.new();body.name="MarketArcade"
    body.position=Vector3(-22,square._ground_y(Vector3(-22,0,-14.5)),-14.5)
    body.add_to_group("map_fixture");body.add_to_group("market_shelter");body.set_meta("map_footprint",Vector2(20.0,15.4));square.add_child(body)
    var visual:=ARCADE.instantiate() as Node3D;body.add_child(visual)
    var library:=MATERIALS.new()
    for mesh:MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):mesh.set_surface_override_material(slot,library._city_material(mesh.get_active_material(slot)))
    physical_mesh(body,visual,"market_arcade")
    return body
