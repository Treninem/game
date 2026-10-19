class_name SettlementInteriorVisuals
extends Node3D

# CC0 Quaternius furniture promoted from assets/staging after source/license review.
# Preserve the existing physical footprints and central aisle. Resting surfaces
# also align collision height with the authored model so feet do not hover above
# a normalized mattress/seat when the player stands on it.
const BED_SCENE = preload("res://assets/production/interiors/quaternius_furniture/Bed.fbx")
const TABLE_SCENE = preload("res://assets/production/interiors/quaternius_furniture/Table.fbx")

const BED_TARGET_SIZE := Vector3(1.72, 0.72, 2.18)
const TABLE_TARGET_SIZE := Vector3(1.58, 0.86, 1.00)
const EPSILON := 0.0001

var decorated_buildings := 0
var real_model_instances := 0

func _ready() -> void:
    process_priority = 46
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_decorate_existing")

func _exit_tree() -> void:
    if get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.disconnect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node == null:
        return
    # Equipment, effects and streamed nodes may be freed in the same frame.
    # A typed Node argument cannot even reach our validity check after free.
    call_deferred("_decorate_candidate_ref", weakref(node))

func _decorate_candidate_ref(reference: WeakRef) -> void:
    var node := reference.get_ref() as Node
    if is_instance_valid(node):
        _decorate_candidate(node)

func _decorate_existing() -> void:
    for building in get_tree().get_nodes_in_group("enterable_building"):
        _decorate_candidate(building)

func _decorate_candidate(node: Node) -> void:
    if not is_instance_valid(node) or not node.is_in_group("enterable_building"):
        return
    decorate_building(node)

func decorate_building(building: Node) -> bool:
    if building == null or not is_instance_valid(building):
        return false
    if building.get_meta("real_furniture_visuals", false):
        return true

    var furniture := building.get_node_or_null("InteriorFurniture") as Node3D
    if furniture == null:
        return false

    var bed := furniture.get_node_or_null("Bed") as StaticBody3D
    var table := furniture.get_node_or_null("Table") as StaticBody3D
    if bed == null or table == null:
        return false

    var bed_ok := _replace_proxy_visual(bed, BED_SCENE, "RealBedModel", BED_TARGET_SIZE, -0.17)
    # Table collision proxy represents the tabletop. The imported full table is
    # grounded relative to that proxy while the original collision stays intact.
    var second := furniture.get_node_or_null("BedSecond") as StaticBody3D
    if second != null:
        bed_ok = _replace_proxy_visual(second, BED_SCENE, "RealBedModel", BED_TARGET_SIZE, -0.17) and bed_ok
    for bench_name in ["Bench", "BenchSecond"]:
        var bench := furniture.get_node_or_null(bench_name) as StaticBody3D
        if bench != null:
            _replace_proxy_visual(bench, preload("res://assets/production/medieval/capital_square/Bench.gltf"), "RealBenchModel", Vector3(1.8, 0.58, 0.48), -0.53)
    for chest_name in ["StorageChest", "GuestChest"]:
        var chest := furniture.get_node_or_null(chest_name) as StaticBody3D
        if chest != null:
            _replace_proxy_visual(chest, preload("res://assets/production/medieval/capital_square/Chest_Wood.gltf"), "RealChestModel", Vector3(1.35, 0.68, 0.72), -0.34)
    var table_ok := _replace_proxy_visual(table, TABLE_SCENE, "RealTableModel", TABLE_TARGET_SIZE, -0.82)
    if not bed_ok or not table_ok:
        return false

    building.set_meta("real_furniture_visuals", true)
    decorated_buildings += 1
    return true

func _replace_proxy_visual(body: StaticBody3D, scene: PackedScene, model_name: String, target_size: Vector3, bottom_y: float) -> bool:
    if body.get_node_or_null(model_name) != null:
        return true

    var model := scene.instantiate() as Node3D
    if model == null:
        return false

    _set_geometry_visible_recursive(body, false)
    model.name = model_name
    body.add_child(model)
    model.position = Vector3.ZERO
    model.rotation = Vector3.ZERO
    model.scale = Vector3.ONE

    var bounds := _combined_mesh_bounds(model)
    if bounds.size.x <= EPSILON or bounds.size.y <= EPSILON or bounds.size.z <= EPSILON:
        model.queue_free()
        _set_geometry_visible_recursive(body, true)
        return false

    var uniform_scale := minf(
        target_size.x / bounds.size.x,
        minf(target_size.y / bounds.size.y, target_size.z / bounds.size.z)
    )
    if uniform_scale <= EPSILON:
        model.queue_free()
        _set_geometry_visible_recursive(body, true)
        return false

    model.scale = Vector3.ONE * uniform_scale
    var center := bounds.get_center()
    model.position = Vector3(
        -center.x * uniform_scale,
        bottom_y - bounds.position.y * uniform_scale,
        -center.z * uniform_scale
    )
    model.set_meta("source_pack", "quaternius_fantasy_props_megakit_standard" if "/capital_square/" in scene.resource_path else "quaternius_furniture_pack")
    model.set_meta("license", "CC0")
    model.set_meta("collision_proxy", body.name)
    _restore_furniture_materials(model)
    _configure_rest_surface(body, model, model_name)
    real_model_instances += 1
    return true

func _restore_furniture_materials(model: Node3D) -> void:
    # These source FBX surfaces retain semantic names, but the importer gives
    # every one the same untextured grey. Restore only those known blank slots;
    # authored textures or deliberately coloured materials remain untouched.
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        for index in range(mesh.mesh.get_surface_count()):
            var source := mesh.get_active_material(index) as StandardMaterial3D
            if source == null or source.albedo_texture != null:
                continue
            var color := source.albedo_color
            if maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) > 0.01:
                continue
            var label := source.resource_name.to_lower()
            var replacement := source.duplicate() as StandardMaterial3D
            replacement.roughness = 0.94
            if "wood" in label:
                replacement.albedo_texture = preload("res://assets/production/medieval/building_shell/T_WoodTrim_BaseColor.png")
                replacement.albedo_color = Color(0.45, 0.32, 0.20) if "dark" in label else Color(0.8, 0.66, 0.48)
                replacement.uv1_triplanar = true
                replacement.uv1_world_triplanar = true
                replacement.uv1_scale = Vector3.ONE * 1.2
            elif "sheets" in label:
                replacement.albedo_color = Color(0.38, 0.27, 0.18)
            elif "white" in label:
                replacement.albedo_color = Color(0.72, 0.68, 0.56)
            elif "darkbrown" in label:
                replacement.albedo_color = Color(0.15, 0.085, 0.04)
            else:
                continue
            mesh.set_surface_override_material(index, replacement)

func _set_geometry_visible_recursive(root: Node, visible_value: bool) -> void:
    for child in root.get_children():
        if child is GeometryInstance3D:
            (child as GeometryInstance3D).visible = visible_value
        _set_geometry_visible_recursive(child, visible_value)

func _combined_mesh_bounds(root: Node3D) -> AABB:
    var has_bounds := false
    var min_corner := Vector3(INF, INF, INF)
    var max_corner := Vector3(-INF, -INF, -INF)
    var root_inverse := root.global_transform.affine_inverse()

    for candidate in root.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance := candidate as MeshInstance3D
        if mesh_instance == null or mesh_instance.mesh == null:
            continue
        var local_aabb := mesh_instance.get_aabb()
        var to_root := root_inverse * mesh_instance.global_transform
        for corner_index in range(8):
            var corner := local_aabb.position + Vector3(
                local_aabb.size.x if (corner_index & 1) != 0 else 0.0,
                local_aabb.size.y if (corner_index & 2) != 0 else 0.0,
                local_aabb.size.z if (corner_index & 4) != 0 else 0.0
            )
            var point := to_root * corner
            min_corner.x = minf(min_corner.x, point.x)
            min_corner.y = minf(min_corner.y, point.y)
            min_corner.z = minf(min_corner.z, point.z)
            max_corner.x = maxf(max_corner.x, point.x)
            max_corner.y = maxf(max_corner.y, point.y)
            max_corner.z = maxf(max_corner.z, point.z)
            has_bounds = true

    if not has_bounds:
        return AABB()
    return AABB(min_corner, max_corner - min_corner)

func decorated_building_count() -> int:
    return decorated_buildings

func real_furniture_model_count() -> int:
    return real_model_instances

func _configure_rest_surface(body: StaticBody3D, model: Node3D, model_name: String) -> void:
    if model_name not in ["RealBedModel", "RealBenchModel"]:
        return
    var support := -INF
    var to_body := body.global_transform.affine_inverse()
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        for surface in range(mesh.mesh.get_surface_count()):
            var material := mesh.get_active_material(surface)
            # Bedposts/headboard are not a sleeping surface. Use the authored
            # sheet mesh rather than an assumed uniform-normalization height.
            if model_name == "RealBedModel" and (material == null or "sheets" not in material.resource_name.to_lower()):
                continue
            var arrays := mesh.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var transform := to_body * mesh.global_transform
            for vertex in vertices:
                support = maxf(support, (transform * vertex).y)
    if is_finite(support):
        body.set_meta("rest_support_y", support)
        var collision := body.get_node_or_null("Collision") as CollisionShape3D
        if collision != null and collision.shape is BoxShape3D:
            var bottom := -0.17 if model_name == "RealBedModel" else -0.53
            var shape := collision.shape as BoxShape3D
            shape.size.y = maxf(0.05, support - bottom)
            collision.position.y = (support + bottom) * 0.5
