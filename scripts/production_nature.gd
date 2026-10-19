extends RefCounted

const TREE: PackedScene = preload("res://assets/production/nature/temperate/TemperateTree_LOD.glb")
const PINE: PackedScene = preload("res://assets/production/nature/woodland/Pine_1.glb")
const WIND := preload("res://assets/shaders/environment/foliage_wind.gdshader")
static var wind_materials: Dictionary = {}
static var render_meshes: Dictionary = {}
static var trunk_radii: Dictionary = {}
static var collision_parts: Dictionary = {}

static func prepare(node: Node) -> void:
    if node is MeshInstance3D:
        var visual := node as MeshInstance3D
        for index in range(visual.mesh.get_surface_count()):
            var base := visual.get_active_material(index) as StandardMaterial3D
            if base == null or base.albedo_texture == null:
                continue
            if "Leaves" not in base.resource_name and "Grass" not in base.resource_name:
                continue
            var key := base.get_instance_id()
            if not wind_materials.has(key):
                var material := ShaderMaterial.new()
                material.shader = WIND
                material.set_shader_parameter("albedo_texture", base.albedo_texture)
                material.set_shader_parameter("black_key", "Temperate" in base.resource_name)
                material.set_shader_parameter("wind_strength", 0.045)
                material.set_shader_parameter("wave_frequency", 2.0)
                if "Grass" in base.resource_name:
                    material.set_shader_parameter("vegetation_tint", Color(0.48, 0.60, 0.36))
                    material.set_shader_parameter("height_anchor", true)
                elif "Pine" in base.resource_name:
                    material.set_shader_parameter("vegetation_tint", Color(0.72, 0.79, 0.62))
                wind_materials[key] = material
            visual.set_surface_override_material(index, wind_materials[key])
    for child in node.get_children():
        prepare(child)

static func sync_wind() -> void:
    for material: ShaderMaterial in wind_materials.values():
        EnvironmentState.apply_environment_material(material)
        material.set_shader_parameter("wind_strength", minf(0.12, EnvironmentState.wind_strength * 0.10))

static func add_batches(parent: Node3D, transforms: Array[Transform3D], cover_near: bool = false, conifer: bool = false) -> void:
    var positions: Array[Vector3] = []
    for transform in transforms:
        positions.append(transform.origin)
    parent.add_to_group("map_tree_batch")
    parent.set_meta("map_tree_positions", positions)
    var scene := PINE if conifer else TREE
    var first_child := parent.get_child_count()
    add_model_batches(parent, transforms, scene, 620.0, true)
    if cover_near:
        for index in range(first_child, parent.get_child_count()):
            var visual := parent.get_child(index) as GeometryInstance3D
            if visual != null:
                visual.set_meta("quality_begin", 0.0)
                visual.set_meta("quality_shadows", GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
                SettingsManager.apply_geometry_quality(visual)
        var body := StaticBody3D.new()
        body.name = "PhysicalTreeTrunks"
        parent.add_child(body)
        var shape := CylinderShape3D.new()
        shape.radius = trunk_radius(scene)
        shape.height = 2.5
        for transform in transforms:
            var collision := CollisionShape3D.new()
            collision.shape = shape
            collision.transform = transform * Transform3D(Basis.IDENTITY, Vector3.UP * 1.25)
            body.add_child(collision)

static func add_model_batches(parent: Node3D, transforms: Array[Transform3D], scene: PackedScene, visibility_end: float, distant: bool = false, material_override: Material = null) -> void:
    var source := scene.instantiate() as Node3D
    if material_override != null:
        apply_material(source, material_override)
    prepare(source)
    _batch_meshes(source, Transform3D.IDENTITY, parent, transforms, visibility_end, distant)
    source.free()

static func apply_material(node: Node, material: Material) -> void:
    if node is MeshInstance3D:
        node.material_override = material
    for child in node.get_children():
        apply_material(child, material)

static func trunk_radius(scene: PackedScene) -> float:
    var key := scene.get_instance_id()
    if not trunk_radii.has(key):
        var source := scene.instantiate() as Node3D
        var points: Array[Vector3] = []
        _collect_vertices(source, Transform3D.IDENTITY, points)
        source.free()
        var bottom := INF
        for point in points:
            bottom = minf(bottom, point.y)
        var radius := 0.15
        for point in points:
            if point.y < bottom + 0.12:
                radius = maxf(radius, Vector2(point.x, point.z).length())
        trunk_radii[key] = clampf(radius, 0.15, 1.5)
    return float(trunk_radii[key])

static func _collect_vertices(node: Node3D, inherited: Transform3D, points: Array[Vector3]) -> void:
    var transform := inherited * node.transform
    if node is MeshInstance3D:
        for surface in range(node.mesh.get_surface_count()):
            for vertex: Vector3 in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
                points.append(transform * vertex)
    for child in node.get_children():
        if child is Node3D:
            _collect_vertices(child, transform, points)

static func add_model_collisions(parent: Node3D, transforms: Array[Transform3D], scene: PackedScene) -> void:
    var key := scene.get_instance_id()
    if not collision_parts.has(key):
        var source := scene.instantiate() as Node3D
        var parts: Array = []
        _collect_collision_parts(source, Transform3D.IDENTITY, parts)
        source.free()
        collision_parts[key] = parts
    var body := parent as StaticBody3D
    if body == null:
        body = StaticBody3D.new()
        body.name = "AuthoredRockCollision"
        parent.add_child(body)
    for transform in transforms:
        for part: Dictionary in collision_parts[key]:
            var collision := CollisionShape3D.new()
            collision.shape = part.shape
            collision.transform = transform * Transform3D(part.transform)
            body.add_child(collision)

static func _collect_collision_parts(node: Node3D, inherited: Transform3D, parts: Array) -> void:
    var transform := inherited * node.transform
    if node is MeshInstance3D:
        parts.append({"shape": node.mesh.create_convex_shape(true, false), "transform": transform})
    for child in node.get_children():
        if child is Node3D:
            _collect_collision_parts(child, transform, parts)

static func _batch_meshes(node: Node3D, inherited: Transform3D, parent: Node3D, transforms: Array[Transform3D], visibility_end: float, distant: bool) -> void:
    var local := inherited * node.transform
    if node is MeshInstance3D:
        var visual := node as MeshInstance3D
        # Preserve authored bark and alpha-cutout leaf surfaces in one shared mesh.
        var key := str(visual.mesh.get_instance_id())
        for surface in range(visual.mesh.get_surface_count()):
            var material := visual.get_active_material(surface)
            key += ":%d" % (material.get_instance_id() if material != null else 0)
        if not render_meshes.has(key):
            var prepared := visual.mesh.duplicate() as ArrayMesh
            for index in range(prepared.get_surface_count()):
                prepared.surface_set_material(index, visual.get_active_material(index))
            render_meshes[key] = prepared
        var mesh := render_meshes[key] as ArrayMesh
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.mesh = mesh
        batch.instance_count = transforms.size()
        for index in range(transforms.size()):
            batch.set_instance_transform(index, transforms[index] * local)
        var instance := MultiMeshInstance3D.new()
        instance.name = "WoodlandBatch"
        instance.multimesh = batch
        instance.visibility_range_begin = 110.0 if distant else 0.0
        instance.visibility_range_end = visibility_end
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if distant or visibility_end < 100.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        parent.add_child(instance)
        instance.add_to_group("quality_nature")
        instance.set_meta("quality_begin", instance.visibility_range_begin)
        instance.set_meta("quality_end", instance.visibility_range_end)
        instance.set_meta("quality_shadows", instance.cast_shadow)
        SettingsManager.apply_geometry_quality(instance)
    for child in node.get_children():
        if child is Node3D:
            _batch_meshes(child, local, parent, transforms, visibility_end, distant)
