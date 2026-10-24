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
var dressing_materials: Dictionary = {}

func _enter_tree() -> void:
    # The loading scene transfers this same prepared world to the game root.
    # Reentering does not call _ready again; keep streamed dressing subscribed.
    if not get_tree().node_added.is_connected(_on_node_added):get_tree().node_added.connect(_on_node_added)
    call_deferred("_decorate_existing")

func _ready() -> void:
    process_priority = 46
    SettingsManager.settings_changed.connect(_apply_dressing_quality)

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

    _dress_room(building as EnterableBuilding, table)

    building.set_meta("real_furniture_visuals", true)
    decorated_buildings += 1
    return true

func _dress_room(building: EnterableBuilding, table: StaticBody3D) -> void:
    if building == null or building.has_node("HouseholdDetails"):
        return
    var details := Node3D.new()
    details.name = "HouseholdDetails"
    details.set_meta("decorative_only", true)
    building.add_child(details)
    var top := _bounds_in(table.get_node("RealTableModel") as Node3D, building)
    var middle := top.get_center()
    var owners: Array = building.get_meta("household_owners", [])
    var settings_count := owners.size() if not owners.is_empty() else (2 if building.has_node("InteriorFurniture/BedSecond") else 1)
    details.set_meta("place_settings", mini(2, settings_count))
    for side: float in ([-1.0, 1.0] if settings_count > 1 else [-1.0]):
        var label := "Left" if side < 0 else "Right"
        _house_prop(building, details, "Table_Plate", Vector3(middle.x + side * top.size.x * 0.28, top.end.y, middle.z - top.size.z * 0.08)).name = "TablePlate" + label
        _house_prop(building, details, "Mug", Vector3(middle.x + side * top.size.x * 0.28, top.end.y, middle.z - top.size.z * 0.33)).name = "TableMug" + label
    _house_prop(building, details, "Book_Stack_1", Vector3(middle.x, top.end.y, middle.z + top.size.z * 0.20)).name = "TableBooks"
    if building.footprint.x >= 9.0 and building.footprint.y >= 8.0:
        var shelf := StaticBody3D.new()
        shelf.name = "HouseBookcase"
        shelf.position = Vector3(building.interior_size.x * 0.175, building.floor_thickness, -building.interior_size.z * 0.5 + 0.27)
        details.add_child(shelf)
        var case_model := _house_prop(building, shelf, "Bookcase_2", Vector3.ZERO)
        var box := _combined_mesh_bounds(shelf)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = box.size
        collision.shape = shape
        collision.position = box.get_center()
        shelf.add_child(collision)
        var levels := _case_shelf_tops(case_model)
        for level in levels.slice(0, mini(3, levels.size())):
            _house_prop(building, shelf, "Book_Stack_1", Vector3(-0.06, level, 0)).name = "ShelfRowBooks" + str(levels.find(level))
        _house_prop(building, details, "Book_Stack_1", shelf.position + Vector3(0, box.end.y, 0)).name = "ShelfBooks"
    if building.has_node("HouseRooms"):
        var half := building.interior_size * 0.5
        var floor_y := building.floor_thickness
        var counter := _solid_prop(building, details, "Workbench_Drawers", "KitchenCounter", Vector3(2.55, floor_y, half.z - 0.48), PI)
        var counter_top := _bounds_in(counter, building)
        _house_prop(building, details, "Pot_1", Vector3(counter_top.get_center().x - 0.32, counter_top.end.y, counter_top.get_center().z)).name = "KitchenPot"
        _house_prop(building, details, "SmallBottles_1", Vector3(counter_top.get_center().x + 0.34, counter_top.end.y, counter_top.get_center().z)).name = "KitchenBottles"
        _solid_prop(building, details, "FarmCrate_Apple", "HouseholdProvisions", Vector3(-half.x + 0.65, floor_y, half.z - 0.48), 0)
        _solid_prop(building, details, "Cabinet", "LinenCabinet", Vector3(-2.0, floor_y, half.z - 0.38), PI)
        _house_prop(building, details, "Peg_Rack", Vector3(-1.0, 1.7, half.z - 1.4)).rotation.y = -PI * 0.5
        for bed_name in ["Bed", "BedSecond"]:
            var bed := building.get_node_or_null("InteriorFurniture/" + bed_name) as Node3D
            if bed == null:
                continue
            _solid_prop(building, details, "Nightstand_Shelf", bed_name + "Nightstand", Vector3(bed.position.x + 1.15, floor_y, bed.position.z - 0.82), 0)
            _house_prop(building, details, "Bag", Vector3(bed.position.x + 1.10, floor_y, bed.position.z + 0.85)).name = bed_name + "Belongings"
        var living = load("res://scripts/house_living_details.gd").new()
        living.name = "LivingDetails"
        building.add_child(living)
        living.build(building, self)
        building.get_node("HouseRooms").invalidate_navigation()

func _solid_prop(building: EnterableBuilding, parent: Node3D, key: String, label: String, point: Vector3, yaw: float) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = label
    body.position = point
    body.rotation.y = yaw
    parent.add_child(body)
    _house_prop(building, body, key, Vector3.ZERO)
    var box := _combined_mesh_bounds(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    collision.position = box.get_center()
    body.add_child(collision)
    return body

func _case_shelf_tops(model: Node3D) -> Array[float]:
    var levels: Array[float] = []
    var meshes := model.find_children("*", "MeshInstance3D", true, false) + ([model] if model is MeshInstance3D else [])
    for mesh: MeshInstance3D in meshes:
        for surface in range(mesh.mesh.get_surface_count()):
            var arrays := mesh.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            for offset in range(0, indices.size(), 3):
                var a := indices[offset]
                var b := indices[offset + 1]
                var c := indices[offset + 2]
                if normals[a].y < 0.95 or normals[b].y < 0.95 or normals[c].y < 0.95:
                    continue
                var low := vertices[a].min(vertices[b]).min(vertices[c])
                var high := vertices[a].max(vertices[b]).max(vertices[c])
                var y := (low.y + high.y) * 0.5
                if high.x - low.x < 0.35 or high.z - low.z < 0.15 or y < 0.12 or y > mesh.get_aabb().end.y - 0.25:
                    continue
                var distinct := true
                for old: float in levels:
                    distinct = distinct and absf(old - y) > 0.008
                if distinct:
                    levels.append(y)
    levels.sort()
    return levels

func _house_prop(building: EnterableBuilding, parent: Node3D, key: String, point: Vector3) -> Node3D:
    var kit := building._interior_scene("res://assets/production/interiors/architecture/HouseholdProps.glb").instantiate() as Node3D
    var prop := kit.find_child(key, true, false) as Node3D
    assert(prop != null, "Missing reviewed household model: " + key)
    prop.get_parent().remove_child(prop)
    kit.free()
    parent.add_child(prop)
    prop.position = point
    prop.set_meta("household_prop", key)
    for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false) + ([prop] if prop is MeshInstance3D else []):
        var large := key in ["Bookcase_2", "Cabinet", "Workbench_Drawers", "Nightstand_Shelf"]
        mesh.visibility_range_end = 24.0 if large else 14.0
        if not large:
            mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        for index in range(mesh.mesh.get_surface_count()):
            var source := mesh.get_active_material(index)
            var label := source.resource_name
            if "Props" in label:
                if key == "FarmCrate_Apple":
                    label = "Apple"
                elif key in ["Vase_4", "SmallBottles_1", "Shelf_Small_Bottles"]:
                    label = "KitchenCeramic"
            var material := _dressing_material(label)
            mesh.set_surface_override_material(index, material)
    return prop

func _dressing_material(label: String) -> StandardMaterial3D:
    var family := label if label in ["Apple", "KitchenCeramic"] else "Cloth" if "Cloth" in label else "Metal" if "Metal" in label else ("Props" if "Props" in label else "Furniture")
    if dressing_materials.has(family):
        return dressing_materials[family] as StandardMaterial3D
    if family == "Furniture":
        var wood := preload("res://scripts/interior_surface_materials.gd").wood(Color(0.72, 0.59, 0.44))
        dressing_materials[family] = wood
        return wood
    var base := "res://assets/production/medieval/capital_square/T_Trim_" + family
    if family in ["Apple", "KitchenCeramic"]:
        base = "res://assets/production/medieval/capital_square/T_Trim_Props"
    if family == "Cloth":
        base = "res://assets/production/interiors/materials/household_cloth"
    var material := StandardMaterial3D.new()
    material.resource_name = "Household_" + family
    material.albedo_texture = load(base + "_BaseColor.png") as Texture2D
    material.normal_texture = load(base + "_Normal.png") as Texture2D
    var orm := load(base + "_ORM.png") as Texture2D
    material.roughness = 1.0
    material.roughness_texture = orm
    material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
    material.metallic = 1.0
    material.metallic_texture = orm
    material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
    material.ao_texture = orm
    material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
    material.vertex_color_use_as_albedo = true
    if family in ["Apple", "KitchenCeramic"]:
        material.vertex_color_use_as_albedo = false
        material.albedo_color = Color(0.62, 0.11, 0.045) if family == "Apple" else Color(0.5, 0.33, 0.18)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    dressing_materials[family] = material
    _apply_dressing_quality()
    return material

func _apply_dressing_quality() -> void:
    var detailed := int(SettingsManager.get_value("graphics", "quality_preset")) >= 2
    for material: StandardMaterial3D in dressing_materials.values():
        material.normal_enabled = detailed and material.normal_texture != null
        material.ao_enabled = detailed and material.ao_texture != null

func _bounds_in(model: Node3D, reference: Node3D) -> AABB:
    return reference.global_transform.affine_inverse() * model.global_transform * _combined_mesh_bounds(model)

func _replace_proxy_visual(body: StaticBody3D, scene: PackedScene, model_name: String, target_size: Vector3, bottom_y: float) -> bool:
    if body.get_node_or_null(model_name) != null:
        return true

    var model := scene.instantiate() as Node3D
    if model == null:
        return false

    # The source bed is authored lengthwise on X; gameplay beds use Z.
    # Rotate inside a neutral root so bounds, mattress support and collision
    # are measured in the same furniture frame before uniform normalization.
    if model_name == "RealBedModel":
        var oriented := Node3D.new()
        model.rotation.y = PI * 0.5
        oriented.add_child(model)
        model = oriented
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
            if source != null and ("wood" in source.resource_name.to_lower() or "MI_Trim_Furniture" in source.resource_name):
                mesh.set_surface_override_material(index, _dressing_material("Furniture"))
                continue
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
