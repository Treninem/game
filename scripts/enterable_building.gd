class_name EnterableBuilding
extends Node3D

const DOOR_SCRIPT := preload("res://scripts/door_interactable.gd")
const DOOR_SCENE: PackedScene = preload("res://assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/glTF/Door_1_Flat.gltf")
const ROOF_SCENE: PackedScene = preload("res://assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/glTF/Roof_RoundTiles_8x8.gltf")

@export var building_label := "Дом"
@export var footprint := Vector2(9.0, 8.0)
@export var wall_height := 3.2
@export var wall_thickness := 0.28
@export var floor_thickness := 0.18
@export var ceiling_thickness := 0.16
@export var doorway_width := 1.45
@export var doorway_height := 2.35
@export var window_width := 1.35
@export var window_height := 1.15
@export var window_sill_height := 1.05
@export var wall_variant := 0

var room_count := 0
var door_count := 0
var window_count := 0
var structural_piece_count := 0
var interior_prop_count := 0
var interior_size := Vector3.ZERO
var front_door: DoorInteractable

var wall_materials: Array[StandardMaterial3D] = []
var floor_material: StandardMaterial3D
var ceiling_material: StandardMaterial3D
var timber_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var bedding_material: StandardMaterial3D
var cloth_material: StandardMaterial3D
var iron_material: StandardMaterial3D

func configure(size: Vector3, variant: int = 0, label: String = "Дом") -> void:
    footprint = Vector2(maxf(5.0, size.x), maxf(5.0, size.z))
    wall_height = maxf(2.8, size.y)
    wall_variant = maxi(0, variant)
    building_label = label

func _ready() -> void:
    add_to_group("enterable_building")
    _prepare_materials()
    _build_structure()

func _build_structure() -> void:
    room_count = 1
    door_count = 0
    window_count = 0
    structural_piece_count = 0
    interior_prop_count = 0
    interior_size = Vector3(
        footprint.x - wall_thickness * 2.0,
        wall_height - floor_thickness - ceiling_thickness,
        footprint.y - wall_thickness * 2.0
    )

    var shell := Node3D.new()
    shell.name = "PhysicalShell"
    add_child(shell)

    _add_static_box(
        shell,
        "Floor",
        Vector3(footprint.x, floor_thickness, footprint.y),
        Vector3(0.0, floor_thickness * 0.5, 0.0),
        floor_material
    )
    _add_static_box(
        shell,
        "Ceiling",
        Vector3(footprint.x - wall_thickness * 0.5, ceiling_thickness, footprint.y - wall_thickness * 0.5),
        Vector3(0.0, wall_height - ceiling_thickness * 0.5, 0.0),
        ceiling_material
    )

    _build_front_wall(shell)
    _build_back_wall(shell)
    _build_side_wall_with_window(shell, "LeftWall", -1.0)
    _build_side_wall_with_window(shell, "RightWall", 1.0)
    _build_roof_visual()
    _build_front_door()
    _build_interior_furnishings()

func _build_front_wall(shell: Node3D) -> void:
    var front_z := footprint.y * 0.5 - wall_thickness * 0.5
    var side_width := maxf(0.4, (footprint.x - doorway_width) * 0.5)
    var y_center := floor_thickness + (wall_height - floor_thickness) * 0.5
    var usable_height := wall_height - floor_thickness

    _add_static_box(
        shell,
        "FrontWallLeft",
        Vector3(side_width, usable_height, wall_thickness),
        Vector3(-(doorway_width + side_width) * 0.5, y_center, front_z),
        _wall_material()
    )
    _add_static_box(
        shell,
        "FrontWallRight",
        Vector3(side_width, usable_height, wall_thickness),
        Vector3((doorway_width + side_width) * 0.5, y_center, front_z),
        _wall_material()
    )

    var lintel_height := maxf(0.25, wall_height - doorway_height)
    _add_static_box(
        shell,
        "DoorLintel",
        Vector3(doorway_width, lintel_height, wall_thickness),
        Vector3(0.0, doorway_height + lintel_height * 0.5, front_z),
        _wall_material()
    )

func _build_back_wall(shell: Node3D) -> void:
    var back_z := -footprint.y * 0.5 + wall_thickness * 0.5
    _build_windowed_horizontal_wall(shell, "BackWall", back_z)

func _build_windowed_horizontal_wall(shell: Node3D, prefix: String, z: float) -> void:
    var side_width := maxf(0.5, (footprint.x - window_width) * 0.5)
    var sill_top := window_sill_height
    var window_top := window_sill_height + window_height
    var top_height := maxf(0.3, wall_height - window_top)

    _add_static_box(shell, prefix + "Left", Vector3(side_width, wall_height - floor_thickness, wall_thickness), Vector3(-(window_width + side_width) * 0.5, floor_thickness + (wall_height - floor_thickness) * 0.5, z), _wall_material())
    _add_static_box(shell, prefix + "Right", Vector3(side_width, wall_height - floor_thickness, wall_thickness), Vector3((window_width + side_width) * 0.5, floor_thickness + (wall_height - floor_thickness) * 0.5, z), _wall_material())
    _add_static_box(shell, prefix + "SillWall", Vector3(window_width, sill_top - floor_thickness, wall_thickness), Vector3(0.0, floor_thickness + (sill_top - floor_thickness) * 0.5, z), _wall_material())
    _add_static_box(shell, prefix + "Top", Vector3(window_width, top_height, wall_thickness), Vector3(0.0, window_top + top_height * 0.5, z), _wall_material())
    _add_window_frame(Vector3(0.0, window_sill_height + window_height * 0.5, z), Vector3(window_width, window_height, wall_thickness), false, prefix + "Window")

func _build_side_wall_with_window(shell: Node3D, prefix: String, side_sign: float) -> void:
    var x := side_sign * (footprint.x * 0.5 - wall_thickness * 0.5)
    var segment_depth := maxf(0.5, (footprint.y - window_width) * 0.5)
    var sill_top := window_sill_height
    var window_top := window_sill_height + window_height
    var top_height := maxf(0.3, wall_height - window_top)
    var y_center := floor_thickness + (wall_height - floor_thickness) * 0.5

    _add_static_box(shell, prefix + "Front", Vector3(wall_thickness, wall_height - floor_thickness, segment_depth), Vector3(x, y_center, (window_width + segment_depth) * 0.5), _wall_material())
    _add_static_box(shell, prefix + "Back", Vector3(wall_thickness, wall_height - floor_thickness, segment_depth), Vector3(x, y_center, -(window_width + segment_depth) * 0.5), _wall_material())
    _add_static_box(shell, prefix + "SillWall", Vector3(wall_thickness, sill_top - floor_thickness, window_width), Vector3(x, floor_thickness + (sill_top - floor_thickness) * 0.5, 0.0), _wall_material())
    _add_static_box(shell, prefix + "Top", Vector3(wall_thickness, top_height, window_width), Vector3(x, window_top + top_height * 0.5, 0.0), _wall_material())
    _add_window_frame(Vector3(x, window_sill_height + window_height * 0.5, 0.0), Vector3(window_width, window_height, wall_thickness), true, prefix + "Window")

func _build_front_door() -> void:
    var hinge := DOOR_SCRIPT.new() as DoorInteractable
    hinge.name = "FrontDoor"
    hinge.position = Vector3(-doorway_width * 0.5, 0.0, footprint.y * 0.5 + 0.035)
    hinge.configure("%s — входная дверь" % building_label, -1.0, false)
    add_child(hinge)
    front_door = hinge

    var door_visual := DOOR_SCENE.instantiate() as Node3D
    if door_visual != null:
        door_visual.name = "RealDoorModel"
        door_visual.scale = Vector3(doorway_width / 1.116, doorway_height / 2.118, 1.0)
        hinge.add_child(door_visual)

    var collision := CollisionShape3D.new()
    collision.name = "DoorCollision"
    var shape := BoxShape3D.new()
    shape.size = Vector3(doorway_width, doorway_height, 0.12)
    collision.shape = shape
    collision.position = Vector3(doorway_width * 0.5, doorway_height * 0.5, 0.0)
    hinge.add_child(collision)
    door_count = 1

func _build_interior_furnishings() -> void:
    var furniture := Node3D.new()
    furniture.name = "InteriorFurniture"
    add_child(furniture)

    var inner_half_x := interior_size.x * 0.5
    var inner_half_z := interior_size.z * 0.5
    var floor_y := floor_thickness

    # Keep a wide, collision-free central aisle from the front door through the room.
    # Furniture hugs the side/back walls so entering and turning inside remain physical.
    var bed_x := -inner_half_x + 1.15
    var bed_z := -inner_half_z + 1.45
    var bed := _add_furniture_box(furniture, "Bed", Vector3(1.75, 0.34, 2.25), Vector3(bed_x, floor_y + 0.17, bed_z), timber_material)
    _add_visual_box(bed, "Mattress", Vector3(1.58, 0.18, 2.02), Vector3(0.0, 0.25, 0.0), bedding_material)
    _add_visual_box(bed, "Pillow", Vector3(1.18, 0.16, 0.42), Vector3(0.0, 0.39, -0.72), cloth_material)

    var table_x := inner_half_x - 1.35
    var table_z := -0.45
    var table := _add_furniture_box(furniture, "Table", Vector3(1.65, 0.15, 1.05), Vector3(table_x, floor_y + 0.82, table_z), timber_material)
    for leg_pos in [Vector3(-0.62, -0.39, -0.32), Vector3(0.62, -0.39, -0.32), Vector3(-0.62, -0.39, 0.32), Vector3(0.62, -0.39, 0.32)]:
        _add_visual_box(table, "Leg", Vector3(0.13, 0.78, 0.13), leg_pos, timber_material)

    var chest_x := inner_half_x - 0.9
    var chest_z := -inner_half_z + 0.75
    var chest := _add_furniture_box(furniture, "StorageChest", Vector3(1.35, 0.68, 0.72), Vector3(chest_x, floor_y + 0.34, chest_z), timber_material)
    _add_visual_box(chest, "IronBandA", Vector3(0.10, 0.72, 0.76), Vector3(-0.4, 0.04, 0.0), iron_material)
    _add_visual_box(chest, "IronBandB", Vector3(0.10, 0.72, 0.76), Vector3(0.4, 0.04, 0.0), iron_material)

    var bench_x := inner_half_x - 1.05
    var bench_z := inner_half_z - 1.15
    var bench := _add_furniture_box(furniture, "Bench", Vector3(1.8, 0.22, 0.48), Vector3(bench_x, floor_y + 0.53, bench_z), timber_material)
    _add_visual_box(bench, "BenchLegA", Vector3(0.18, 0.52, 0.38), Vector3(-0.58, -0.26, 0.0), timber_material)
    _add_visual_box(bench, "BenchLegB", Vector3(0.18, 0.52, 0.38), Vector3(0.58, -0.26, 0.0), timber_material)

func _add_furniture_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
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
    interior_prop_count += 1
    return body

func _add_window_frame(center: Vector3, opening_size: Vector3, side_wall: bool, node_name: String) -> void:
    var root := Node3D.new()
    root.name = node_name
    root.position = center
    add_child(root)

    var frame_depth := wall_thickness + 0.05
    var frame_width := 0.09
    if side_wall:
        _add_visual_box(root, "FrameTop", Vector3(frame_depth, frame_width, opening_size.x), Vector3.ZERO + Vector3(0, opening_size.y * 0.5, 0), timber_material)
        _add_visual_box(root, "FrameBottom", Vector3(frame_depth, frame_width, opening_size.x), Vector3.ZERO + Vector3(0, -opening_size.y * 0.5, 0), timber_material)
        _add_visual_box(root, "FrameA", Vector3(frame_depth, opening_size.y, frame_width), Vector3(0, 0, -opening_size.x * 0.5), timber_material)
        _add_visual_box(root, "FrameB", Vector3(frame_depth, opening_size.y, frame_width), Vector3(0, 0, opening_size.x * 0.5), timber_material)
        _add_visual_box(root, "Glass", Vector3(0.035, opening_size.y - frame_width * 2.0, opening_size.x - frame_width * 2.0), Vector3.ZERO, glass_material)
    else:
        _add_visual_box(root, "FrameTop", Vector3(opening_size.x, frame_width, frame_depth), Vector3(0, opening_size.y * 0.5, 0), timber_material)
        _add_visual_box(root, "FrameBottom", Vector3(opening_size.x, frame_width, frame_depth), Vector3(0, -opening_size.y * 0.5, 0), timber_material)
        _add_visual_box(root, "FrameA", Vector3(frame_width, opening_size.y, frame_depth), Vector3(-opening_size.x * 0.5, 0, 0), timber_material)
        _add_visual_box(root, "FrameB", Vector3(frame_width, opening_size.y, frame_depth), Vector3(opening_size.x * 0.5, 0, 0), timber_material)
        _add_visual_box(root, "Glass", Vector3(opening_size.x - frame_width * 2.0, opening_size.y - frame_width * 2.0, 0.035), Vector3.ZERO, glass_material)
    window_count += 1

func _build_roof_visual() -> void:
    var roof := ROOF_SCENE.instantiate() as Node3D
    if roof == null:
        return
    roof.name = "RealPackRoof"
    roof.position = Vector3(0.0, wall_height + 0.03, 0.0)
    roof.scale = Vector3(maxf(0.75, footprint.x / 8.0), 1.0, maxf(0.75, footprint.y / 8.0))
    add_child(roof)

func _add_static_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
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
    structural_piece_count += 1
    return body

func _add_visual_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = node_name
    mesh_node.position = pos
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_node.mesh = mesh
    parent.add_child(mesh_node)
    return mesh_node

func _wall_material() -> StandardMaterial3D:
    return wall_materials[wall_variant % wall_materials.size()]

func _prepare_materials() -> void:
    wall_materials = [
        _material(Color(0.53, 0.45, 0.34), 0.94),
        _material(Color(0.66, 0.60, 0.48), 0.92),
        _material(Color(0.42, 0.34, 0.27), 0.97),
        _material(Color(0.72, 0.68, 0.58), 0.93)
    ]
    floor_material = _material(Color(0.24, 0.14, 0.075), 0.96)
    ceiling_material = _material(Color(0.43, 0.36, 0.27), 0.97)
    timber_material = _material(Color(0.18, 0.085, 0.035), 0.95)
    glass_material = _material(Color(0.58, 0.76, 0.82, 0.28), 0.16)
    glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bedding_material = _material(Color(0.54, 0.47, 0.36), 0.98)
    cloth_material = _material(Color(0.72, 0.68, 0.57), 0.99)
    iron_material = _material(Color(0.12, 0.13, 0.14), 0.73)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
