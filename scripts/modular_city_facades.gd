extends RefCounted

const ROOT := "res://assets/production/medieval/quaternius_city_core/"
static var cached_modules: Dictionary = {}
static var gable_mesh: ArrayMesh
var groups: Dictionary = {}

func _module(path: String) -> Array:
    if cached_modules.has(path):
        return cached_modules[path]
    var scene := load(path) as PackedScene
    var source := scene.instantiate() as Node3D
    var result: Array = []
    _collect(source, Transform3D.IDENTITY, result)
    source.free()
    cached_modules[path] = result
    return result

func _collect(node: Node3D, inherited: Transform3D, result: Array) -> void:
    var transform := inherited * node.transform
    if node is MeshInstance3D:
        var visual := node as MeshInstance3D
        var mesh := visual.mesh.duplicate() as ArrayMesh
        for surface in range(mesh.get_surface_count()):
            mesh.surface_set_material(surface, visual.get_active_material(surface))
        result.append({"mesh": mesh, "transform": transform})
    for child in node.get_children():
        if child is Node3D:
            _collect(child, transform, result)

func _add_mesh(mesh: Mesh, transform: Transform3D) -> void:
    var key := mesh.get_instance_id()
    if not groups.has(key):
        groups[key] = {"mesh": mesh, "transforms": []}
    groups[key].transforms.append(transform)

func _add_module(path: String, transform: Transform3D) -> void:
    for part: Dictionary in _module(path):
        _add_mesh(part.mesh, transform * Transform3D(part.transform))

func add_house(origin: Vector3, yaw: float, footprint: Vector2, stories: int, brick: bool = false) -> void:
    var house := Transform3D(Basis(Vector3.UP, yaw), origin)
    var style := "UnevenBrick" if brick else "Plaster"
    var straight := ROOT + "Wall_%s_Straight.gltf" % style
    var window := ROOT + "Wall_%s_Window_Wide_Round.gltf" % style
    var doorway := ROOT + "Wall_%s_Door_Round.gltf" % style
    var count_x := maxi(2, roundi(footprint.x / 2.0))
    var count_z := maxi(2, roundi(footprint.y / 2.0))
    var step_x := footprint.x / count_x
    var step_z := footprint.y / count_z
    for story in range(stories):
        var height := float(story) * 3.12
        for index in range(count_x):
            var x := -footprint.x * 0.5 + (index + 0.5) * step_x
            var front := doorway if story == 0 and index == count_x / 2 else window if index % 2 == 0 else straight
            _add_module(front, house * Transform3D(Basis.from_scale(Vector3(step_x / 2.0, 1, 1)), Vector3(x, height, footprint.y * 0.5)))
            _add_module(window if index % 2 == 0 else straight, house * Transform3D(Basis(Vector3.UP, PI) * Basis.from_scale(Vector3(step_x / 2.0, 1, 1)), Vector3(x, height, -footprint.y * 0.5)))
            if front == doorway:
                _add_module("res://assets/production/medieval/building_shell/Door_1_Flat.gltf", house * Transform3D(Basis.IDENTITY, Vector3(x, 0.05, footprint.y * 0.5 + 0.06)))
        for index in range(count_z):
            var z := -footprint.y * 0.5 + (index + 0.5) * step_z
            for side: float in [-1.0, 1.0]:
                _add_module(window if index % 2 == 0 else straight, house * Transform3D(Basis(Vector3.UP, side * PI * 0.5) * Basis.from_scale(Vector3(step_z / 2.0, 1, 1)), Vector3(side * footprint.x * 0.5, height, z)))
    var roof_base := house * Transform3D(Basis.IDENTITY, Vector3(0, float(stories) * 3.12, 0))
    var roof_scale := Basis.from_scale(Vector3((footprint.x + 0.8) / 8.0, 0.65, (footprint.y + 0.8) / 8.0))
    _add_module(ROOT + "Roof_RoundTiles_8x8.gltf", roof_base * Transform3D(roof_scale, Vector3.ZERO))
    _add_mesh(_gables(), roof_base * Transform3D(roof_scale, Vector3.ZERO))
    _add_module(ROOT + "Prop_Chimney.gltf", roof_base * Transform3D(Basis.IDENTITY, Vector3(footprint.x * 0.22, 1.2, -footprint.y * 0.18)))

func _gables() -> ArrayMesh:
    if gable_mesh != null:
        return gable_mesh
    var material := StandardMaterial3D.new()
    material.albedo_texture = load(ROOT + "T_Plaster_BaseColor.png")
    material.roughness = 0.94
    material.uv1_triplanar = true
    material.uv1_scale = Vector3.ONE * 0.35
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_material(material)
    for z: float in [-4.0, 4.0]:
        var corners := [Vector3(-4, -0.05, z), Vector3(0, 5.5, z), Vector3(4, -0.05, z)]
        if z < 0:
            corners.reverse()
        for corner: Vector3 in corners:
            surface.add_vertex(corner)
    surface.generate_normals()
    gable_mesh = surface.commit()
    return gable_mesh

func finish(parent: Node3D) -> void:
    for group: Dictionary in groups.values():
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.mesh = group.mesh
        instances.instance_count = group.transforms.size()
        for index in range(instances.instance_count):
            instances.set_instance_transform(index, group.transforms[index])
        var batch := MultiMeshInstance3D.new()
        batch.name = "AuthoredCityFacades_%d" % parent.get_child_count()
        batch.multimesh = instances
        batch.visibility_range_end = 520.0
        parent.add_child(batch)
    groups.clear()
