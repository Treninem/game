extends Node3D

var home: EnterableBuilding
var decorator: SettlementInteriorVisuals
var materials: Dictionary = {}
const FABRIC_NORMAL := preload("res://assets/production/interiors/materials/household_cloth_Normal.png")
const FABRIC_ORM := preload("res://assets/production/interiors/materials/household_cloth_ORM.png")
const FABRIC_LABELS := ["Sheets", "Pillow", "Curtain", "Rug", "Border"]

func _ready() -> void:
    SettingsManager.settings_changed.connect(_apply_material_quality)

func _apply_material_quality() -> void:
    var detailed := int(SettingsManager.get_value("graphics", "quality_preset")) >= 2
    for label: String in FABRIC_LABELS:
        if not materials.has(label):continue
        var fabric: StandardMaterial3D = materials[label]
        fabric.normal_enabled = detailed
        fabric.ao_enabled = detailed
        fabric.roughness_texture = FABRIC_ORM if detailed else null


func build(building: EnterableBuilding, visuals: SettlementInteriorVisuals) -> void:
    home = building
    decorator = visuals
    for light: SpotLight3D in home.window_lights:
        var window := light.get_parent_node_3d()
        var curtains := _model("WindowCurtains", self)
        curtains.transform = home.global_transform.affine_inverse() * window.global_transform
    for name: String in ["Bed", "BedSecond"]:
        var bed := home.get_node_or_null("InteriorFurniture/" + name) as StaticBody3D
        if bed == null:
            continue
        var sheet := _sheet_bounds(bed)
        var linen := _model("BedLinen", bed)
        var pillow := _sheet_bounds(bed, "white")
        if pillow.get_center().z > sheet.get_center().z:
            linen.rotation.y = PI
        _replace_old_bedding(bed.get_node("RealBedModel"))
        linen.scale = Vector3(sheet.size.x / 1.5, 1, sheet.size.z / 2.0)
        linen.position = Vector3(sheet.get_center().x, sheet.end.y, sheet.get_center().z)
        decorator._configure_rest_surface(bed, bed, "RealBedModel")
        var rug := _model("WovenRug", self)
        rug.position = Vector3(bed.position.x + 1.95, home.floor_thickness, bed.position.z)
    var room_rug := _model("WovenRug", self)
    room_rug.position = Vector3(-2.3, home.floor_thickness, home.interior_size.z * 0.5 - 1.5)
    room_rug.rotation.y = PI * 0.5
    _kitchen()
    _dining()

func _replace_old_bedding(model: Node3D) -> void:
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        var replacement := ArrayMesh.new()
        var removed := false
        for surface in range(mesh.mesh.get_surface_count()):
            var material := mesh.get_active_material(surface)
            var label := material.resource_name.to_lower() if material != null else ""
            if "sheets" in label or "white" in label:
                removed = true
                continue
            replacement.add_surface_from_arrays(mesh.mesh.surface_get_primitive_type(surface), mesh.mesh.surface_get_arrays(surface))
            replacement.surface_set_material(replacement.get_surface_count() - 1, material)
        if removed:
            if replacement.get_surface_count() == 0:
                mesh.queue_free()
            else:
                mesh.mesh = replacement
                for surface in range(replacement.get_surface_count()):
                    mesh.set_surface_override_material(surface, null)

func _kitchen() -> void:
    var half := home.interior_size * 0.5
    var shelf := decorator._house_prop(home, self, "Shelf_Small_Bottles", Vector3(2.55, 1.75, half.z - 0.22))
    shelf.rotation.y = PI
    var lower := decorator._house_prop(home, self, "Shelf_Simple", Vector3(2.55, 1.3, half.z - 0.22))
    lower.rotation.y = PI
    var shelf_top := _shelf_top(lower)
    var plate := decorator._house_prop(home, self, "Table_Plate", Vector3(shelf_top.get_center().x - 0.28, shelf_top.end.y, shelf_top.get_center().z))
    var plate_top := decorator._bounds_in(plate, home)
    decorator._house_prop(home, self, "Table_Plate", Vector3(plate_top.get_center().x, plate_top.end.y, plate_top.get_center().z))
    decorator._house_prop(home, self, "Mug", Vector3(shelf_top.get_center().x + 0.3, shelf_top.end.y, shelf_top.get_center().z))
    var cabinet := home.get_node("HouseholdDetails/LinenCabinet") as Node3D
    var top := decorator._bounds_in(cabinet, home)
    decorator._house_prop(home, self, "Vase_4", Vector3(top.get_center().x, top.end.y, top.get_center().z))
    if home.footprint.y >= 9.5:
        decorator._solid_prop(home, self, "Barrel", "PantryBarrel", Vector3(half.x - 2.4, home.floor_thickness, -half.z + 0.55), 0)
    var hearth := StaticBody3D.new()
    hearth.name = "KitchenHearth"
    hearth.position = Vector3(half.x - 0.25, home.floor_thickness, (home.get_node("HouseRooms").kitchen_z + half.z) * 0.5)
    hearth.rotation.y = -PI * 0.5
    add_child(hearth)
    _model("ArchedHearth", hearth)
    var box := decorator._combined_mesh_bounds(hearth)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    collision.position = box.get_center()
    hearth.add_child(collision)
    decorator._house_prop(home, hearth, "Pot_1", Vector3(0, 0.65, 0.04))
    var emitter = load("res://scripts/world_effect_emitter.gd").new()
    emitter.configure("hearth_fire", 0.5, 0.22)
    emitter.activation_distance = 14.0
    emitter.position = Vector3(0, 0.05, 0.04)
    emitter.randomize_interval = false
    hearth.add_child(emitter)
    var light := OmniLight3D.new()
    light.position = Vector3(0, 0.6, 0.3)
    light.light_color = Color(1, 0.53, 0.23)
    light.light_energy = 0.8
    light.omni_range = 2.8
    light.shadow_enabled = false
    hearth.add_child(light)
    home.get_node("HouseRooms").room_lights.append(light)

func _dining() -> void:
    var table := home.get_node("HouseholdDetails")
    for plate: Node3D in table.get_children():
        if not String(plate.name).begins_with("TablePlate"):
            continue
        decorator._house_prop(home, self, "Table_Knife", plate.position + Vector3(0.17, 0, 0))
        decorator._house_prop(home, self, "Table_Spoon", plate.position + Vector3(-0.17, 0, 0))
    var bounds := decorator._bounds_in(home.get_node("InteriorFurniture/Table/RealTableModel"), home)
    decorator._house_prop(home, self, "CandleStick_Triple", Vector3(bounds.get_center().x + bounds.size.x * 0.3, bounds.end.y, bounds.get_center().z + bounds.size.z * 0.28))
    for name: String in ["Bench", "BenchSecond"]:
        var bench := home.get_node_or_null("InteriorFurniture/" + name) as StaticBody3D
        if bench == null:
            continue
        var cover := _model("WovenRug", bench)
        cover.position.y = float(bench.get_meta("rest_support_y"))
        cover.scale = Vector3(1.7 / 1.3, 1, 0.42 / 2.0)
        decorator._configure_rest_surface(bench, bench, "RealBenchModel")

func _sheet_bounds(bed: Node3D, label: String = "sheets") -> AABB:
    var result := AABB()
    var measured := false
    for mesh: MeshInstance3D in bed.find_children("*", "MeshInstance3D", true, false):
        var transform := bed.global_transform.affine_inverse() * mesh.global_transform
        for index in range(mesh.mesh.get_surface_count()):
            var material := mesh.get_active_material(index)
            if material == null or label not in material.resource_name.to_lower():
                continue
            var arrays := mesh.mesh.surface_get_arrays(index)
            for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
                var point := transform * vertex
                result = result.expand(point) if measured else AABB(point, Vector3.ZERO)
                measured = true
    assert(measured, "Reviewed bed lacks its authored sheet surface")
    return result

func _shelf_top(model: Node3D) -> AABB:
    var top := AABB()
    var highest := -INF
    for mesh: MeshInstance3D in [model] + model.find_children("*", "MeshInstance3D", true, false):
        var transform := home.global_transform.affine_inverse() * mesh.global_transform
        for surface in range(mesh.mesh.get_surface_count()):
            var arrays := mesh.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            for index in range(0, indices.size(), 3):
                var a := indices[index]
                if (transform.basis * normals[a]).normalized().y < 0.95:
                    continue
                var box := AABB(transform * vertices[a], Vector3.ZERO)
                box = box.expand(transform * vertices[indices[index + 1]]).expand(transform * vertices[indices[index + 2]])
                if box.size.x < 0.3 or box.size.z < 0.1:
                    continue
                if box.end.y > highest + 0.005:
                    top = box
                    highest = box.end.y
                elif absf(box.end.y - highest) < 0.005:
                    top = top.merge(box)
    assert(is_finite(highest), "Kitchen shelf lacks a broad physical support surface")
    return top

func _model(key: String, parent: Node3D) -> Node3D:
    var kit := home._interior_scene("res://assets/production/interiors/architecture/HouseLivingDetails.glb").instantiate() as Node3D
    var model := kit.find_child(key, true, false) as Node3D
    model.get_parent().remove_child(model)
    kit.free()
    parent.add_child(model)
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        mesh.visibility_range_end = 18
        for index in range(mesh.mesh.get_surface_count()):
            mesh.set_surface_override_material(index, _material(mesh.get_active_material(index).resource_name))
    return model

func _material(label: String) -> StandardMaterial3D:
    if materials.has(label):
        return materials[label]
    var material := StandardMaterial3D.new()
    material.resource_name = "Household " + label
    material.roughness = 0.95
    if label == "Timber":
        material = preload("res://scripts/interior_surface_materials.gd").wood(Color(0.53, 0.39, 0.25))
    elif label == "Stone":
        material.albedo_texture = load("res://assets/production/materials/ground/stone_paving.jpg")
        material.albedo_color = Color(0.75, 0.72, 0.66)
        material.uv1_triplanar = true
        material.uv1_world_triplanar = true
        material.uv1_scale = Vector3.ONE * 1.5
    elif label in FABRIC_LABELS:
        material.albedo_texture = load("res://assets/production/interiors/materials/household_cloth_BaseColor.png")
        material.albedo_color = Color(0.43, 0.22, 0.15) if label == "Sheets" else Color(0.34, 0.21, 0.12) if label == "Rug" else Color(0.66, 0.49, 0.28) if label == "Border" else Color(0.85, 0.8, 0.65)
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        # Reuse the same licensed swatch UVs for all PBR channels. These maps
        # have shipped beside the albedo; keep the cloth nonmetallic.
        material.normal_texture = FABRIC_NORMAL
        material.normal_scale = 0.35
        material.ao_texture = FABRIC_ORM
        material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
        material.ao_light_affect = 0.15
        material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
    else:
        material.albedo_color = Color(0.09, 0.065, 0.045)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    materials[label] = material
    _apply_material_quality()
    return material
