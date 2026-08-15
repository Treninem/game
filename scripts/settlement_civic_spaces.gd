class_name SettlementCivicSpaces
extends Node3D

const COUNCIL_BUILDING_NAME := "Enterable_14"

var halls_decorated := 0
var timber_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var cloth_material: StandardMaterial3D
var parchment_material: StandardMaterial3D

func _ready() -> void:
    process_priority = 46
    _prepare_materials()
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_decorate_existing")

func _exit_tree() -> void:
    if get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.disconnect(_on_node_added)

func _prepare_materials() -> void:
    timber_material = _material(Color(0.25, 0.145, 0.075, 1.0), 0.95)
    stone_material = _material(Color(0.39, 0.38, 0.35, 1.0), 0.96)
    cloth_material = _material(Color(0.31, 0.16, 0.11, 1.0), 0.90)
    parchment_material = _material(Color(0.72, 0.64, 0.45, 1.0), 0.84)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name.begins_with("Settlement_"):
        call_deferred("_decorate_candidate", node)

func _decorate_existing() -> void:
    var world := get_parent()
    if world == null:
        return
    for candidate in world.find_children("Settlement_*", "Node3D", true, false):
        _decorate_candidate(candidate)

func _decorate_candidate(node: Node) -> void:
    var settlement := node as Node3D
    if settlement == null or not is_instance_valid(settlement):
        return
    decorate_settlement(settlement)

func decorate_settlement(settlement: Node3D) -> bool:
    if settlement == null or not is_instance_valid(settlement):
        return false
    if String(settlement.get_meta("settlement_kind", "")) != "fortified_town":
        return false
    if settlement.get_meta("civic_space_ready", false):
        return true

    var hall := settlement.get_node_or_null(COUNCIL_BUILDING_NAME) as EnterableBuilding
    if hall == null:
        return false
    if hall.front_door == null or hall.door_count < 1:
        return false

    var old_furniture := hall.get_node_or_null("InteriorFurniture")
    if old_furniture != null:
        old_furniture.free()

    hall.building_label = "Городская ратуша"
    hall.set_meta("building_use", "civic_hall")
    hall.set_meta("physical_council_venue", true)
    hall.set_meta("canonical_story_sources", [
        "story/main_story/09_CITY_TO_REALM.md",
        "story/dialogues/09_FOUNDING_COUNCIL.md"
    ])

    var chamber := Node3D.new()
    chamber.name = "CouncilChamber"
    chamber.set_meta("assembly_capacity", 18)
    chamber.set_meta("physical_furniture", true)
    hall.add_child(chamber)

    var entrance_aisle := Marker3D.new()
    entrance_aisle.name = "EntranceAisle"
    entrance_aisle.position = Vector3(0.0, hall.floor_thickness + 0.05, 3.1)
    entrance_aisle.set_meta("clear_width", 2.4)
    entrance_aisle.set_meta("connects_front_door_to_chamber", true)
    chamber.add_child(entrance_aisle)

    var assembly := Marker3D.new()
    assembly.name = "AssemblyArea"
    assembly.position = Vector3(0.0, hall.floor_thickness + 0.05, -1.1)
    assembly.set_meta("standing_capacity", 8)
    assembly.set_meta("seated_capacity", 10)
    chamber.add_child(assembly)

    _add_static_box(chamber, "CouncilTable", Vector3(4.7, 0.18, 1.45), Vector3(0.0, hall.floor_thickness + 0.88, -2.5), timber_material)
    _add_static_box(chamber, "CouncilTableBaseA", Vector3(0.22, 0.78, 1.05), Vector3(-1.75, hall.floor_thickness + 0.44, -2.5), timber_material)
    _add_static_box(chamber, "CouncilTableBaseB", Vector3(0.22, 0.78, 1.05), Vector3(1.75, hall.floor_thickness + 0.44, -2.5), timber_material)

    _add_bench(chamber, "BenchLeftFront", Vector3(-3.1, hall.floor_thickness + 0.48, -0.55), PI * 0.5)
    _add_bench(chamber, "BenchLeftBack", Vector3(-3.1, hall.floor_thickness + 0.48, -2.55), PI * 0.5)
    _add_bench(chamber, "BenchRightFront", Vector3(3.1, hall.floor_thickness + 0.48, -0.55), PI * 0.5)
    _add_bench(chamber, "BenchRightBack", Vector3(3.1, hall.floor_thickness + 0.48, -2.55), PI * 0.5)

    _add_static_box(chamber, "ClerkDesk", Vector3(1.65, 0.82, 0.82), Vector3(-4.7, hall.floor_thickness + 0.41, 2.25), timber_material)
    _add_static_box(chamber, "CharterChest", Vector3(1.25, 0.72, 0.66), Vector3(4.75, hall.floor_thickness + 0.36, 2.45), timber_material)

    var charter := MeshInstance3D.new()
    charter.name = "CharterWritingSurface"
    var charter_mesh := BoxMesh.new()
    charter_mesh.size = Vector3(1.30, 0.025, 0.68)
    charter_mesh.material = parchment_material
    charter.mesh = charter_mesh
    charter.position = Vector3(-4.7, hall.floor_thickness + 0.835, 2.25)
    chamber.add_child(charter)

    var dais := _add_static_box(chamber, "CouncilDais", Vector3(5.8, 0.22, 2.3), Vector3(0.0, hall.floor_thickness + 0.11, -4.55), stone_material)
    dais.set_meta("meeting_focus", true)

    var banner := MeshInstance3D.new()
    banner.name = "NeutralCivicCloth"
    var banner_mesh := BoxMesh.new()
    banner_mesh.size = Vector3(2.2, 1.75, 0.035)
    banner_mesh.material = cloth_material
    banner.mesh = banner_mesh
    banner.position = Vector3(0.0, hall.wall_height - 1.15, -hall.footprint.y * 0.5 + hall.wall_thickness + 0.05)
    banner.set_meta("non_heraldic", true)
    chamber.add_child(banner)

    settlement.set_meta("civic_space_ready", true)
    halls_decorated += 1
    return true

func _add_bench(parent: Node3D, node_name: String, pos: Vector3, yaw: float) -> StaticBody3D:
    var bench := _add_static_box(parent, node_name, Vector3(2.5, 0.22, 0.52), pos, timber_material)
    bench.rotation.y = yaw
    return bench

func _add_static_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    body.collision_layer = 1
    body.collision_mask = 1
    parent.add_child(body)

    var mesh_node := MeshInstance3D.new()
    mesh_node.name = "Mesh"
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_node.mesh = mesh
    body.add_child(mesh_node)

    var collision := CollisionShape3D.new()
    collision.name = "Collision"
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func civic_hall_count() -> int:
    return halls_decorated
