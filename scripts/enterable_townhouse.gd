class_name EnterableTownhouse
extends Node3D

const DOOR_SCRIPT := preload("res://scripts/door_interactable.gd")
const DOOR_SCENE: PackedScene = preload("res://assets/production/medieval/building_shell/Door_1_Flat.gltf")
const ROOF_SCENE: PackedScene = preload("res://assets/production/medieval/building_shell/Roof_RoundTiles_8x8.gltf")

@export var building_label := "Городской дом"
@export var footprint := Vector2(8.0, 8.0)
@export_range(1, 4, 1) var story_count := 2
@export var story_height := 3.12
@export var wall_thickness := 0.26
@export var floor_thickness := 0.18
@export var doorway_width := 1.45
@export var doorway_height := 2.30
@export var window_width := 1.35
@export var window_height := 1.15
@export var window_sill_height := 1.02
@export var wall_variant := 0

var room_count := 0
var door_count := 0
var window_count := 0
var stair_flight_count := 0
var structural_piece_count := 0
var interior_prop_count := 0
var interior_floor_area_m2 := 0.0
var front_door: DoorInteractable

var plaster_material: StandardMaterial3D
var brick_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var timber_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var cloth_material: StandardMaterial3D
var iron_material: StandardMaterial3D

func configure(
    size: Vector2,
    stories: int,
    per_story_height: float = 3.12,
    variant: int = 0,
    label: String = "Городской дом"
) -> void:
    footprint = Vector2(maxf(7.2, size.x), maxf(7.2, size.y))
    story_count = clampi(stories, 1, 4)
    story_height = maxf(2.85, per_story_height)
    wall_variant = maxi(0, variant)
    building_label = label

func _ready() -> void:
    add_to_group("enterable_building")
    add_to_group("enterable_city_house")
    _prepare_materials()
    _build_structure()

func _prepare_materials() -> void:
    plaster_material = _material(Color(0.68, 0.61, 0.49), 0.96)
    brick_material = _material(Color(0.42, 0.30, 0.23), 0.98)
    floor_material = _material(Color(0.36, 0.25, 0.14), 0.96)
    timber_material = _material(Color(0.30, 0.19, 0.10), 0.95)
    cloth_material = _material(Color(0.42, 0.33, 0.24), 0.92)
    iron_material = _material(Color(0.18, 0.19, 0.20), 0.74)

    glass_material = StandardMaterial3D.new()
    glass_material.albedo_color = Color(0.48, 0.68, 0.78, 0.28)
    glass_material.roughness = 0.18
    glass_material.metallic = 0.03
    glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material

func _wall_material() -> Material:
    return brick_material if wall_variant % 2 == 1 else plaster_material

func _build_structure() -> void:
    room_count = story_count
    door_count = 0
    window_count = 0
    stair_flight_count = 0
    structural_piece_count = 0
    interior_prop_count = 0
    interior_floor_area_m2 = 0.0

    var shell := Node3D.new()
    shell.name = "PhysicalShell"
    add_child(shell)

    _add_structural_box(
        shell,
        "GroundFloor",
        Vector3(footprint.x, floor_thickness, footprint.y),
        Vector3(0.0, floor_thickness * 0.5, 0.0),
        floor_material
    )

    var inner_width := footprint.x - wall_thickness * 2.0
    var inner_depth := footprint.y - wall_thickness * 2.0
    interior_floor_area_m2 = inner_width * inner_depth

    for story in range(story_count):
        _build_story_walls(shell, story)
        if story > 0:
            interior_floor_area_m2 += _build_interstory_floor(shell, story)

    for flight in range(story_count - 1):
        _build_stair_flight(shell, flight)

    _build_front_door()
    _build_roof_visual()
    _build_interior_furnishings()

    set_meta("physical_interior", true)
    set_meta("story_count", story_count)
    set_meta("room_count", room_count)
    set_meta("stair_flight_count", stair_flight_count)
    set_meta("interior_floor_area_m2", interior_floor_area_m2)
    set_meta("interior_fits_shell", true)
    set_meta("monolithic_collision", false)

func _build_story_walls(shell: Node3D, story: int) -> void:
    var base_y := float(story) * story_height
    var front_z := footprint.y * 0.5 - wall_thickness * 0.5
    var back_z := -footprint.y * 0.5 + wall_thickness * 0.5

    if story == 0:
        _build_front_wall_with_door(shell, base_y, front_z)
    else:
        _build_windowed_horizontal_wall(shell, "Story%dFront" % story, base_y, front_z)

    _build_windowed_horizontal_wall(shell, "Story%dBack" % story, base_y, back_z)
    _build_windowed_side_wall(shell, "Story%dLeft" % story, base_y, -1.0)
    _build_windowed_side_wall(shell, "Story%dRight" % story, base_y, 1.0)

func _build_front_wall_with_door(shell: Node3D, base_y: float, z: float) -> void:
    var wall_bottom := base_y + floor_thickness
    var usable_height := story_height - floor_thickness
    var center_y := wall_bottom + usable_height * 0.5
    var side_width := maxf(0.5, (footprint.x - doorway_width) * 0.5)

    _add_structural_box(
        shell,
        "GroundFrontLeft",
        Vector3(side_width, usable_height, wall_thickness),
        Vector3(-(doorway_width + side_width) * 0.5, center_y, z),
        _wall_material()
    )
    _add_structural_box(
        shell,
        "GroundFrontRight",
        Vector3(side_width, usable_height, wall_thickness),
        Vector3((doorway_width + side_width) * 0.5, center_y, z),
        _wall_material()
    )

    var lintel_height := maxf(0.28, story_height - doorway_height)
    _add_structural_box(
        shell,
        "GroundDoorLintel",
        Vector3(doorway_width, lintel_height, wall_thickness),
        Vector3(0.0, base_y + doorway_height + lintel_height * 0.5, z),
        _wall_material()
    )

func _build_windowed_horizontal_wall(shell: Node3D, prefix: String, base_y: float, z: float) -> void:
    var side_width := maxf(0.55, (footprint.x - window_width) * 0.5)
    var wall_bottom := base_y + floor_thickness
    var sill_top := base_y + window_sill_height
    var window_top := sill_top + window_height
    var story_top := base_y + story_height
    var full_height := story_top - wall_bottom
    var side_center_y := wall_bottom + full_height * 0.5
    var sill_height := maxf(0.25, sill_top - wall_bottom)
    var top_height := maxf(0.30, story_top - window_top)

    _add_structural_box(shell, prefix + "Left", Vector3(side_width, full_height, wall_thickness), Vector3(-(window_width + side_width) * 0.5, side_center_y, z), _wall_material())
    _add_structural_box(shell, prefix + "Right", Vector3(side_width, full_height, wall_thickness), Vector3((window_width + side_width) * 0.5, side_center_y, z), _wall_material())
    _add_structural_box(shell, prefix + "Sill", Vector3(window_width, sill_height, wall_thickness), Vector3(0.0, wall_bottom + sill_height * 0.5, z), _wall_material())
    _add_structural_box(shell, prefix + "Top", Vector3(window_width, top_height, wall_thickness), Vector3(0.0, window_top + top_height * 0.5, z), _wall_material())
    _add_window_frame(Vector3(0.0, sill_top + window_height * 0.5, z), Vector3(window_width, window_height, wall_thickness), false, prefix + "Window")

func _build_windowed_side_wall(shell: Node3D, prefix: String, base_y: float, side_sign: float) -> void:
    var x := side_sign * (footprint.x * 0.5 - wall_thickness * 0.5)
    var segment_depth := maxf(0.55, (footprint.y - window_width) * 0.5)
    var wall_bottom := base_y + floor_thickness
    var sill_top := base_y + window_sill_height
    var window_top := sill_top + window_height
    var story_top := base_y + story_height
    var full_height := story_top - wall_bottom
    var side_center_y := wall_bottom + full_height * 0.5
    var sill_height := maxf(0.25, sill_top - wall_bottom)
    var top_height := maxf(0.30, story_top - window_top)

    _add_structural_box(shell, prefix + "Front", Vector3(wall_thickness, full_height, segment_depth), Vector3(x, side_center_y, (window_width + segment_depth) * 0.5), _wall_material())
    _add_structural_box(shell, prefix + "Back", Vector3(wall_thickness, full_height, segment_depth), Vector3(x, side_center_y, -(window_width + segment_depth) * 0.5), _wall_material())
    _add_structural_box(shell, prefix + "Sill", Vector3(wall_thickness, sill_height, window_width), Vector3(x, wall_bottom + sill_height * 0.5, 0.0), _wall_material())
    _add_structural_box(shell, prefix + "Top", Vector3(wall_thickness, top_height, window_width), Vector3(x, window_top + top_height * 0.5, 0.0), _wall_material())
    _add_window_frame(Vector3(x, sill_top + window_height * 0.5, 0.0), Vector3(window_width, window_height, wall_thickness), true, prefix + "Window")

func _build_interstory_floor(shell: Node3D, level: int) -> float:
    var inner_half_x := footprint.x * 0.5 - wall_thickness
    var inner_depth := footprint.y - wall_thickness * 2.0
    var stair_edge_x := maxf(0.85, inner_half_x - 2.45)
    var slab_width := stair_edge_x + inner_half_x
    var slab_center_x := (-inner_half_x + stair_edge_x) * 0.5
    var floor_y := float(level) * story_height - floor_thickness * 0.5

    _add_structural_box(
        shell,
        "Level%dFloorSlab" % level,
        Vector3(slab_width, floor_thickness, inner_depth),
        Vector3(slab_center_x, floor_y, 0.0),
        floor_material
    )

    var stairwell_width := inner_half_x - stair_edge_x
    var landing_depth := 1.35
    var landing_z_sign := -1.0 if (level - 1) % 2 == 0 else 1.0
    var landing_z := landing_z_sign * (inner_depth * 0.5 - landing_depth * 0.5)
    _add_structural_box(
        shell,
        "Level%dStairLanding" % level,
        Vector3(stairwell_width, floor_thickness, landing_depth),
        Vector3(stair_edge_x + stairwell_width * 0.5, floor_y, landing_z),
        floor_material
    )

    var opening := Marker3D.new()
    opening.name = "Level%dStairwellOpening" % level
    opening.position = Vector3(stair_edge_x + stairwell_width * 0.5, float(level) * story_height, 0.0)
    opening.set_meta("clear_width", stairwell_width)
    opening.set_meta("clear_length", inner_depth - landing_depth)
    opening.set_meta("physical_opening", true)
    shell.add_child(opening)

    return slab_width * inner_depth + stairwell_width * landing_depth

func _build_stair_flight(shell: Node3D, flight: int) -> void:
    var stairs := Node3D.new()
    stairs.name = "StairFlight_%d" % flight
    stairs.set_meta("connects_level", flight)
    stairs.set_meta("connects_to_level", flight + 1)
    shell.add_child(stairs)

    var inner_half_x := footprint.x * 0.5 - wall_thickness
    var stair_x := inner_half_x - 1.15
    var start_z := 2.72 if flight % 2 == 0 else -2.72
    var end_z := -2.72 if flight % 2 == 0 else 2.72
    var step_count := 15
    var rise := story_height / float(step_count)
    var run := absf(end_z - start_z) / float(step_count)
    var base_y := float(flight) * story_height

    for i in range(step_count):
        var t := (float(i) + 0.5) / float(step_count)
        var top_height := rise * float(i + 1)
        var step := _add_structural_box(
            stairs,
            "Step_%02d" % i,
            Vector3(1.28, top_height, run * 1.08),
            Vector3(stair_x, base_y + top_height * 0.5, lerpf(start_z, end_z, t)),
            timber_material
        )
        step.set_meta("stair_step", true)
        step.set_meta("step_index", i)

    stairs.set_meta("step_count", step_count)
    stairs.set_meta("rise", rise)
    stairs.set_meta("clear_width", 1.28)
    stair_flight_count += 1

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
        door_visual.set_meta("production_asset", true)
        hinge.add_child(door_visual)

    var collision := CollisionShape3D.new()
    collision.name = "DoorCollision"
    var shape := BoxShape3D.new()
    shape.size = Vector3(doorway_width, doorway_height, 0.12)
    collision.shape = shape
    collision.position = Vector3(doorway_width * 0.5, doorway_height * 0.5, 0.0)
    hinge.add_child(collision)
    door_count = 1

func _build_roof_visual() -> void:
    var roof := ROOF_SCENE.instantiate() as Node3D
    if roof == null:
        return
    roof.name = "RealPackRoof"
    roof.position = Vector3(0.0, float(story_count) * story_height, 0.0)
    roof.scale = Vector3(footprint.x / 8.0, 1.0, footprint.y / 8.0)
    roof.set_meta("production_asset", true)
    add_child(roof)

func _build_interior_furnishings() -> void:
    var furniture := Node3D.new()
    furniture.name = "InteriorFurniture"
    add_child(furniture)

    var inner_half_x := footprint.x * 0.5 - wall_thickness
    var inner_half_z := footprint.y * 0.5 - wall_thickness

    for story in range(story_count):
        var level := Node3D.new()
        level.name = "Level_%d" % story
        level.set_meta("story", story)
        furniture.add_child(level)

        var floor_y := floor_thickness if story == 0 else float(story) * story_height
        var bed := _add_furniture_box(
            level,
            "Bed",
            Vector3(1.65, 0.34, 2.05),
            Vector3(-inner_half_x + 1.05, floor_y + 0.17, -inner_half_z + 1.30),
            timber_material
        )
        _add_visual_box(bed, "Bedding", Vector3(1.48, 0.16, 1.84), Vector3(0.0, 0.24, 0.0), cloth_material)

        var chest := _add_furniture_box(
            level,
            "Chest",
            Vector3(1.15, 0.62, 0.68),
            Vector3(-inner_half_x + 0.82, floor_y + 0.31, inner_half_z - 0.62),
            timber_material
        )
        _add_visual_box(chest, "IronBand", Vector3(0.10, 0.66, 0.72), Vector3(0.0, 0.02, 0.0), iron_material)

func _add_window_frame(center: Vector3, opening_size: Vector3, side_wall: bool, node_name: String) -> void:
    var root := Node3D.new()
    root.name = node_name
    root.position = center
    add_child(root)

    var frame_depth := wall_thickness + 0.04
    var frame_width := 0.09
    if side_wall:
        _add_visual_box(root, "FrameTop", Vector3(frame_depth, frame_width, opening_size.x), Vector3(0, opening_size.y * 0.5, 0), timber_material)
        _add_visual_box(root, "FrameBottom", Vector3(frame_depth, frame_width, opening_size.x), Vector3(0, -opening_size.y * 0.5, 0), timber_material)
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

func _add_structural_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
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
    structural_piece_count += 1
    return body

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

func _add_visual_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_node.mesh = mesh
    mesh_node.position = pos
    parent.add_child(mesh_node)
    return mesh_node
