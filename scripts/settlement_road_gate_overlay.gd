class_name SettlementRoadGateOverlay
extends Node3D

const GATE_NETWORK := preload("res://scripts/settlement_gate_network.gd")

const VILLAGE_HALF_SIZE := Vector2(78.0, 68.0)
const TOWN_HALF_SIZE := Vector2(150.0, 115.0)
const VILLAGE_GATE_HALF_WIDTH := 5.0
const TOWN_GATE_HALF_WIDTH := 7.0
const ROAD_OUTSIDE_LENGTH := 28.0
const ROAD_PATCH_SPACING := 7.0
const TOWN_GATE_OPEN_ANGLE := 72.0

var processed: Dictionary = {}
var stone_material: StandardMaterial3D
var timber_material: StandardMaterial3D
var path_material: StandardMaterial3D

func _ready() -> void:
    _prepare_materials()
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_scan_existing")

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name.begins_with("Settlement_"):
        call_deferred("rebuild_settlement", node)

func _scan_existing() -> void:
    for node in get_tree().get_nodes_in_group("streamed_settlement"):
        if node is Node3D:
            rebuild_settlement(node)

func rebuild_settlement(root: Node3D) -> Node3D:
    if root == null or not is_instance_valid(root):
        return null
    var id := String(root.get_meta("settlement_id", ""))
    var kind := String(root.get_meta("settlement_kind", ""))
    if id.is_empty() or (kind != "village" and kind != "fortified_town"):
        return null
    var existing := root.get_node_or_null("RoadGateNetwork") as Node3D
    if existing != null:
        return existing

    var center := Vector2(root.global_position.x, root.global_position.z)
    var half_size := TOWN_HALF_SIZE if kind == "fortified_town" else VILLAGE_HALF_SIZE
    var gate_half_width := TOWN_GATE_HALF_WIDTH if kind == "fortified_town" else VILLAGE_GATE_HALF_WIDTH
    var gates := GATE_NETWORK.local_gate_specs(center, root.rotation.y, half_size, gate_half_width)
    if gates.is_empty():
        return null

    _remove_legacy_perimeter(root, kind)
    var network := Node3D.new()
    network.name = "RoadGateNetwork"
    network.set_meta("gate_count", gates.size())
    network.set_meta("settlement_id", id)
    root.add_child(network)

    if kind == "fortified_town":
        _build_town_perimeter(root, network, center, half_size, gates)
    else:
        _build_village_perimeter(root, network, center, half_size, gates)
    _build_gate_passages(root, network, center, half_size, gates, kind)

    root.set_meta("road_gate_count", gates.size())
    root.add_to_group("streamed_settlement")
    processed[id] = gates.size()
    return network

func _build_village_perimeter(root: Node3D, network: Node3D, center: Vector2, half_size: Vector2, gates: Array[Dictionary]) -> void:
    _build_segmented_side(root, network, center, half_size, gates, "front", 1.15, 0.24, timber_material)
    _build_segmented_side(root, network, center, half_size, gates, "back", 1.15, 0.24, timber_material)
    _build_segmented_side(root, network, center, half_size, gates, "left", 1.15, 0.24, timber_material)
    _build_segmented_side(root, network, center, half_size, gates, "right", 1.15, 0.24, timber_material)

func _build_town_perimeter(root: Node3D, network: Node3D, center: Vector2, half_size: Vector2, gates: Array[Dictionary]) -> void:
    for side in ["front", "back", "left", "right"]:
        _build_segmented_side(root, network, center, half_size, gates, side, 5.6, 2.2, stone_material)

    var corners := [Vector2(-half_size.x,-half_size.y), Vector2(half_size.x,-half_size.y), Vector2(-half_size.x,half_size.y), Vector2(half_size.x,half_size.y)]
    for i in range(corners.size()):
        _add_static_box(root, network, center, "CornerTower_%02d" % i, Vector3(5.5, 8.2, 5.5), corners[i], 4.1, stone_material)

func _build_segmented_side(root: Node3D, network: Node3D, center: Vector2, half_size: Vector2, gates: Array[Dictionary], side: String, height: float, thickness: float, material: Material) -> void:
    var half_extent := half_size.x if side == "front" or side == "back" else half_size.y
    var intervals := GATE_NETWORK.side_intervals(gates, side, half_extent)
    for i in range(intervals.size()):
        var interval: Vector2 = intervals[i]
        var segment_length := interval.y - interval.x
        if segment_length <= 0.05:
            continue
        var tangent := (interval.x + interval.y) * 0.5
        var local_pos := Vector2.ZERO
        var size := Vector3.ZERO
        if side == "front":
            local_pos = Vector2(tangent, half_size.y)
            size = Vector3(segment_length, height, thickness)
        elif side == "back":
            local_pos = Vector2(tangent, -half_size.y)
            size = Vector3(segment_length, height, thickness)
        elif side == "left":
            local_pos = Vector2(-half_size.x, tangent)
            size = Vector3(thickness, height, segment_length)
        else:
            local_pos = Vector2(half_size.x, tangent)
            size = Vector3(thickness, height, segment_length)
        _add_static_box(root, network, center, "%sSegment_%02d" % [side.capitalize(), i], size, local_pos, height * 0.5, material)

func _build_gate_passages(root: Node3D, network: Node3D, center: Vector2, half_size: Vector2, gates: Array[Dictionary], kind: String) -> void:
    for i in range(gates.size()):
        var gate: Dictionary = gates[i]
        var point: Vector2 = gate.get("point", Vector2.ZERO)
        var half_width := float(gate.get("half_width", 0.0))
        var marker := Marker3D.new()
        marker.name = "RoadGatePassage_%02d" % i
        marker.position = _local_on_terrain(root, center, point, 0.12)
        marker.set_meta("side", String(gate.get("side", "")))
        marker.set_meta("half_width", half_width)
        marker.set_meta("world_direction", gate.get("world_direction", Vector2.ZERO))
        marker.set_meta("road_connected", true)
        network.add_child(marker)

        if kind == "fortified_town":
            _build_town_gate_arch(root, network, center, gate, i)
        _build_road_approach(root, network, center, gate, i, kind)

func _build_town_gate_arch(root: Node3D, network: Node3D, center: Vector2, gate: Dictionary, index: int) -> void:
    var point: Vector2 = gate.get("point", Vector2.ZERO)
    var side := String(gate.get("side", ""))
    var half_width := float(gate.get("half_width", TOWN_GATE_HALF_WIDTH))
    var lintel_size := Vector3(half_width * 2.0, 1.1, 2.5)
    if side == "left" or side == "right":
        lintel_size = Vector3(2.5, 1.1, half_width * 2.0)
    _add_static_box(root, network, center, "GateLintel_%02d" % index, lintel_size, point, 6.75, stone_material)

    var tangent := Vector2(1,0) if side == "front" or side == "back" else Vector2(0,1)
    var leaf_length := half_width - 0.55
    var leaf_size := Vector3(leaf_length, 3.4, 0.32)
    if side == "left" or side == "right":
        leaf_size = Vector3(0.32, 3.4, leaf_length)
    for leaf_index in range(2):
        var sign_value := -1.0 if leaf_index == 0 else 1.0
        var hinge_pos := point + tangent * half_width * sign_value
        var closed_offset := tangent * (-sign_value * leaf_length * 0.5)
        var open_angle := deg_to_rad(TOWN_GATE_OPEN_ANGLE) * sign_value
        var rotated3 := Basis(Vector3.UP, open_angle) * Vector3(closed_offset.x, 0.0, closed_offset.y)
        var leaf_center := hinge_pos + Vector2(rotated3.x, rotated3.z)
        var body := _add_static_box(root, network, center, "Gate_%02d_Leaf_%d" % [index, leaf_index], leaf_size, leaf_center, 1.7, timber_material)
        body.rotation.y = open_angle
        body.set_meta("hinge_local", hinge_pos)
        body.set_meta("open_angle_degrees", TOWN_GATE_OPEN_ANGLE * sign_value)
        body.set_meta("gate_index", index)
        body.set_meta("hinged_correctly", true)

func _build_road_approach(root: Node3D, network: Node3D, center: Vector2, gate: Dictionary, index: int, kind: String) -> void:
    var direction: Vector2 = gate.get("local_direction", Vector2(0,1))
    var boundary: Vector2 = gate.get("point", Vector2.ZERO)
    var outer := boundary + direction * ROAD_OUTSIDE_LENGTH
    var total_length := outer.length()
    var width := 9.0 if kind == "fortified_town" else 7.0
    var patches := maxi(1, int(ceil(total_length / ROAD_PATCH_SPACING)))
    var approach := Node3D.new()
    approach.name = "RoadApproach_%02d" % index
    approach.set_meta("extends_outside_perimeter", true)
    approach.set_meta("patch_count", patches)
    approach.set_meta("gate_boundary", boundary)
    approach.set_meta("outer_endpoint", outer)
    network.add_child(approach)

    var angle := atan2(direction.x, direction.y)
    for patch_index in range(patches + 1):
        var distance := minf(total_length, float(patch_index) * ROAD_PATCH_SPACING)
        var local_pos := direction * distance
        var mesh_node := MeshInstance3D.new()
        mesh_node.name = "RoadPatch_%02d" % patch_index
        var mesh := BoxMesh.new()
        mesh.size = Vector3(width, 0.05, ROAD_PATCH_SPACING + 0.7)
        mesh.material = path_material
        mesh_node.mesh = mesh
        mesh_node.position = _local_on_terrain(root, center, local_pos, 0.07)
        mesh_node.rotation.y = angle
        approach.add_child(mesh_node)

func _remove_legacy_perimeter(root: Node3D, kind: String) -> void:
    var prefixes: Array[String] = []
    if kind == "fortified_town":
        prefixes = ["TownWall", "WallTower", "TownGateLintel", "GateLeaf", "TownGatePassage"]
    else:
        prefixes = ["Fence", "VillageGatePassage"]
    for child in root.get_children():
        for prefix in prefixes:
            if child.name.begins_with(prefix):
                child.free()
                break

func _add_static_box(root: Node3D, parent: Node3D, center: Vector2, node_name: String, size: Vector3, local_pos: Vector2, height_center: float, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = _local_on_terrain(root, center, local_pos, height_center)
    body.collision_layer = 1
    body.collision_mask = 1
    parent.add_child(body)
    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_node.mesh = mesh
    body.add_child(mesh_node)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _local_on_terrain(root: Node3D, center: Vector2, local_pos: Vector2, lift: float) -> Vector3:
    var world_offset := Basis(Vector3.UP, root.rotation.y) * Vector3(local_pos.x, 0.0, local_pos.y)
    var world_pos := center + Vector2(world_offset.x, world_offset.z)
    var y := WorldData.elevation_at(world_pos) + lift
    return Vector3(local_pos.x, y - root.global_position.y, local_pos.y)

func _prepare_materials() -> void:
    stone_material = _material(Color(0.36, 0.37, 0.35, 1.0), 0.97)
    timber_material = _material(Color(0.22, 0.115, 0.05, 1.0), 0.96)
    path_material = _material(Color(0.27, 0.205, 0.13, 1.0), 0.995)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
