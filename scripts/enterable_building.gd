class_name EnterableBuilding
extends Node3D

const DOOR_SCRIPT := preload("res://scripts/door_interactable.gd")
const DOOR_SCENE: PackedScene = preload("res://assets/production/medieval/building_shell/Door_1_Flat.gltf")
static var roof_shape_refs: Dictionary = {}
const ROOF_SCENE: PackedScene = preload("res://assets/production/exteriors/family_home/CottageShingleRoof.tscn")

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
var window_lights: Array[SpotLight3D] = []
var room_lantern: OmniLight3D
var interior_scenes: Dictionary = {}
var light_elapsed := 0.0

func configure(size: Vector3, variant: int = 0, label: String = "Дом") -> void:
    footprint = Vector2(maxf(5.0, size.x), maxf(5.0, size.z))
    wall_height = maxf(2.8, size.y)
    wall_variant = maxi(0, variant)
    building_label = label

func _ready() -> void:
    add_to_group("enterable_building")
    _prepare_materials()
    SettingsManager.settings_changed.connect(_apply_surface_quality)
    _apply_surface_quality()
    _build_structure()
    _update_window_light()

func _process(delta: float) -> void:
    light_elapsed += delta
    if light_elapsed < 0.5:
        return
    light_elapsed = 0.0
    _update_window_light()

func _update_window_light() -> void:
    # Cheap approximation of daylight bounced into the room; no shadow maps,
    # no extra lights on Low, and no illumination of distant streamed houses.
    var hour := fmod(GameState.world_minutes / 60.0, 24.0)
    var daylight := maxf(0.0, sin((hour - 6.0) * PI / 12.0))
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var nearby := player == null or global_position.distance_squared_to(player.global_position) < 400.0
    var enabled := int(SettingsManager.get_value("graphics", "quality_preset")) > 0 and nearby and daylight > 0.01
    for light: SpotLight3D in window_lights:
        light.visible = enabled
        light.light_energy = daylight * 0.65
    if is_instance_valid(room_lantern):
        var inside := player == null
        if player != null:
            var local_player := to_local(player.global_position)
            inside = absf(local_player.x) < interior_size.x * 0.5 and absf(local_player.z) < interior_size.z * 0.5 and local_player.y > 0.0 and local_player.y < wall_height
        room_lantern.visible = nearby
        room_lantern.light_energy = lerpf(2.0, 0.8, daylight)
        room_lantern.shadow_enabled = inside and int(SettingsManager.get_value("graphics", "quality_preset")) > 0

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

    var floor_body := _add_static_box(
        shell,
        "Floor",
        Vector3(footprint.x, floor_thickness, footprint.y),
        Vector3(0.0, floor_thickness * 0.5, 0.0),
        floor_material
    )
    floor_body.set_meta("surface_type", "wood")
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
    _build_timberwork()
    _build_room_lantern()
    if footprint.x >= 8.5 and footprint.y >= 7.5:
        var rooms = load("res://scripts/house_room_layout.gd").new()
        rooms.name = "HouseRooms"
        add_child(rooms)
        rooms.build(self)

func _interior_scene(path: String) -> PackedScene:
    # Instantiate decoration on activation, outside the background stage dependency
    # graph. Retain the scene for this house so its three windows reuse one load.
    if not interior_scenes.has(path):
        interior_scenes[path] = load(path) as PackedScene
    return interior_scenes[path] as PackedScene

func _build_room_lantern() -> void:
    if bool(get_meta("external_interior_lantern", false)):
        return
    var lantern := _interior_scene("res://assets/production/medieval/capital_square/Lantern_Wall.gltf").instantiate() as Node3D
    lantern.name = "RoomWallLantern"
    add_child(lantern)
    var bounds := AABB()
    var measured := false
    for child in lantern.find_children("*", "MeshInstance3D", true, false):
        var mesh := child as MeshInstance3D
        var local_bounds: AABB = (lantern.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
        bounds = bounds.merge(local_bounds) if measured else local_bounds
        measured = true
    var factor := 0.42 / maxf(bounds.size.y, 0.001)
    lantern.scale = Vector3.ONE * factor
    lantern.position = Vector3(1.8, 2.25, -footprint.y * 0.5 + 0.45) - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
    room_lantern = OmniLight3D.new()
    room_lantern.name = "RoomLanternLight"
    room_lantern.position = Vector3(1.8, 2.4, -footprint.y * 0.5 + 0.8)
    room_lantern.light_color = Color(1.0, 0.73, 0.44)
    room_lantern.omni_range = 7.5
    add_child(room_lantern)

func _build_timberwork() -> void:
    var frame := _interior_scene("res://assets/production/interiors/architecture/RoomTimberwork.glb").instantiate() as Node3D
    frame.name = "RoomTimberwork"
    frame.scale = Vector3(footprint.x / 12.0, wall_height / 3.2, footprint.y / 10.0)
    add_child(frame)
    var grain := preload("res://scripts/interior_surface_materials.gd").wood(Color(0.53, 0.42, 0.30))
    grain.uv1_triplanar = false
    grain.uv1_world_triplanar = false
    grain.uv1_scale = Vector3.ONE
    for child in frame.find_children("*", "MeshInstance3D", true, false):
        var mesh := child as MeshInstance3D
        mesh.material_override = grain
        # Actual exposed beam faces block the controller; never a whole-room box.
        mesh.create_trimesh_collision()

func _build_front_wall(shell:Node3D)->void:
    if footprint.x<8.5:
        _build_small_front_wall(shell)
        return
    var z=footprint.y*.5-wall_thickness*.5
    var side_width=(footprint.x-doorway_width)*.5
    var post=(side_width-window_width)*.5
    var top=window_sill_height+window_height
    for sign_value in [-1,1]:
        var prefix="FrontWallLeft" if sign_value<0 else "FrontWallRight"
        var center=sign_value*(doorway_width+side_width)*.5
        for direction in [-1,1]:
            var x=center+direction*(window_width+post)*.5
            _add_static_box(shell,prefix+str(direction),Vector3(post,wall_height-floor_thickness,wall_thickness),Vector3(x,(wall_height+floor_thickness)*.5,z),_wall_material())
        _add_static_box(shell,prefix+"Sill",Vector3(window_width,window_sill_height-floor_thickness,wall_thickness),Vector3(center,(floor_thickness+window_sill_height)*.5,z),_wall_material())
        _add_static_box(shell,prefix+"Header",Vector3(window_width,wall_height-top,wall_thickness),Vector3(center,(wall_height+top)*.5,z),_wall_material())
        var label="FrontWindowLeft" if sign_value<0 else "FrontWindowRight"
        _add_window_frame(Vector3(center,window_sill_height+window_height*.5,z),Vector3(window_width,window_height,wall_thickness),false,label)
        (get_node(label) as Node3D).rotation.y=PI
    _add_static_box(shell,"DoorLintel",Vector3(doorway_width,wall_height-doorway_height,wall_thickness),Vector3(0,(wall_height+doorway_height)*.5,z),_wall_material())

func _build_small_front_wall(shell: Node3D) -> void:
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
    var centers: Array[float] = [0.0]
    if footprint.x >= 8.5 and footprint.y >= 7.5:
        centers.push_front(-interior_size.x * 0.5 + 1.45)
    var cursor := -footprint.x * 0.5
    var top := window_sill_height + window_height
    for index in range(centers.size()):
        var x := centers[index]
        var start := x - window_width * 0.5
        _add_static_box(shell, prefix + "Pier" + str(index), Vector3(start - cursor, wall_height - floor_thickness, wall_thickness), Vector3((cursor + start) * 0.5, (wall_height + floor_thickness) * 0.5, z), _wall_material())
        _add_static_box(shell, prefix + "Sill" + str(index), Vector3(window_width, window_sill_height - floor_thickness, wall_thickness), Vector3(x, (floor_thickness + window_sill_height) * 0.5, z), _wall_material())
        _add_static_box(shell, prefix + "Header" + str(index), Vector3(window_width, wall_height - top, wall_thickness), Vector3(x, (wall_height + top) * 0.5, z), _wall_material())
        _add_window_frame(Vector3(x, window_sill_height + window_height * 0.5, z), Vector3(window_width, window_height, wall_thickness), false, prefix + "Window" + str(index))
        cursor = x + window_width * 0.5
    _add_static_box(shell, prefix + "EndPier", Vector3(footprint.x * 0.5 - cursor, wall_height - floor_thickness, wall_thickness), Vector3((cursor + footprint.x * 0.5) * 0.5, (wall_height + floor_thickness) * 0.5, z), _wall_material())

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

    if footprint.y >= 9.5:
        var second := _add_furniture_box(furniture, "BedSecond", Vector3(1.75, 0.34, 2.25), Vector3(bed_x, floor_y + 0.17, bed_z + 3.0), timber_material)
        _add_visual_box(second, "Mattress", Vector3(1.58, 0.18, 2.02), Vector3(0, 0.25, 0), bedding_material)

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

    if footprint.y >= 9.5:
        _add_furniture_box(furniture, "GuestChest", Vector3(1.35, 0.68, 0.72), Vector3(-inner_half_x + 0.9, floor_y + 0.34, 1.9), timber_material)

    var bench_x := table_x
    var bench_z := 0.75
    var bench := _add_furniture_box(furniture, "Bench", Vector3(1.8, 0.22, 0.48), Vector3(bench_x, floor_y + 0.53, bench_z), timber_material)
    bench.set_meta("approach_offset", Vector3(-1.45, 0, 0))
    _add_visual_box(bench, "BenchLegA", Vector3(0.18, 0.52, 0.38), Vector3(-0.58, -0.26, 0.0), timber_material)
    _add_visual_box(bench, "BenchLegB", Vector3(0.18, 0.52, 0.38), Vector3(0.58, -0.26, 0.0), timber_material)
    if footprint.y >= 9.5:
        var dining_second := _add_furniture_box(furniture, "BenchSecond", Vector3(1.8, 0.22, 0.48), Vector3(bench_x, floor_y + 0.53, -1.65), timber_material)
        dining_second.rotation.y = PI


func _add_furniture_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
    var body := preload("res://scripts/household_furniture.gd").new()
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

    var assembly := _interior_scene("res://assets/production/interiors/architecture/TimberWindow.glb").instantiate() as Node3D
    root.add_child(assembly)
    root.scale = Vector3(opening_size.x / 1.35, opening_size.y / 1.15, wall_thickness / 0.28)
    if side_wall:
        root.rotation.y = PI * 0.5 if center.x < 0.0 else -PI * 0.5
    var grain := preload("res://scripts/interior_surface_materials.gd").wood(Color(0.65, 0.55, 0.42))
    grain.uv1_triplanar = false
    grain.uv1_world_triplanar = false
    grain.uv1_scale = Vector3.ONE
    for child in assembly.find_children("*", "MeshInstance3D", true, false):
        var mesh := child as MeshInstance3D
        if mesh.name == "Glass":
            mesh.material_override = glass_material
            mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        else:
            mesh.material_override = grain
    var daylight := SpotLight3D.new()
    daylight.name = "WindowDaylight"
    daylight.position.z = wall_thickness * 0.5 + 0.04
    daylight.rotation.y = PI
    daylight.light_color = Color(0.83, 0.90, 1.0)
    daylight.spot_range = 4.5
    daylight.spot_angle = 67.0
    daylight.spot_attenuation = 0.6
    daylight.shadow_enabled = false
    root.add_child(daylight)
    window_lights.append(daylight)
    window_count += 1

func _build_roof_visual() -> void:
    var roof := ROOF_SCENE.instantiate() as Node3D
    roof.name = "RealPackRoof"
    roof.position = Vector3(0, wall_height - 0.01, 0)
    roof.scale = Vector3(footprint.x / 12.0, 1, footprint.y / 10.0)
    add_child(roof)
    # Gables share the home's pigment and live quality switches. The other
    # roof surfaces use the wrapper's immutable shared photographic materials.
    for mesh: MeshInstance3D in roof.find_children("*", "MeshInstance3D", true, false):
        for surface in range(mesh.mesh.get_surface_count()):
            var material := mesh.get_active_material(surface) as StandardMaterial3D
            if material != null and material.resource_name == "Plaster":
                mesh.set_surface_override_material(surface, _wall_material())
        _build_roof_collision(mesh)

func _build_roof_collision(mesh: MeshInstance3D) -> void:
    # Bake the relative frame into a shared static shape. Physics bodies stay
    # unscaled even when the same roof fits a differently sized home.
    var frame := Transform3D.IDENTITY
    var member: Node3D = mesh
    while member != self:
        frame = member.transform * frame
        member = member.get_parent() as Node3D
        assert(member != null)
    for stale_key in roof_shape_refs.keys():
        if roof_shape_refs[stale_key].get_ref() == null:
            roof_shape_refs.erase(stale_key)
    var key := str(mesh.mesh.get_instance_id()) + ":" + str(frame)
    var shape: ConcavePolygonShape3D
    if roof_shape_refs.has(key):
        shape = roof_shape_refs[key].get_ref() as ConcavePolygonShape3D
    if shape == null:
        var faces := mesh.mesh.get_faces()
        var bounds := AABB(frame * faces[0], Vector3.ZERO)
        for i in range(faces.size()):
            faces[i] = frame * faces[i]
            bounds = bounds.expand(faces[i])
        shape = ConcavePolygonShape3D.new()
        shape.set_faces(faces)
        shape.set_meta("navigation_local_bounds", bounds)
        roof_shape_refs[key] = weakref(shape)
    var body := StaticBody3D.new()
    body.name = "RoofCollision"
    body.collision_layer = 1
    body.collision_mask = 1
    body.set_meta("surface_type", "wood")
    add_child(body)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)

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
    var surfaces := preload("res://scripts/interior_surface_materials.gd")
    wall_materials = [
        surfaces.plaster(Color(.96, .93, .85)),
        surfaces.plaster(Color(.88, .87, .81)),
        surfaces.plaster(Color(.82, .78, .67)),
        surfaces.plaster(Color(.98, .95, .89))
    ]
    floor_material = surfaces.wood(Color(0.82, 0.77, 0.68))
    ceiling_material = surfaces.wood(Color(0.72, 0.67, 0.58))
    timber_material = _material(Color(0.18, 0.085, 0.035), 0.95)
    glass_material = _material(Color(0.72, 0.83, 0.86, 0.12), 0.16)
    glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    bedding_material = _material(Color(0.54, 0.47, 0.36), 0.98)
    cloth_material = _material(Color(0.72, 0.68, 0.57), 0.99)
    iron_material = _material(Color(0.12, 0.13, 0.14), 0.73)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material

func _apply_surface_quality() -> void:
    var detailed := int(SettingsManager.get_value("graphics", "quality_preset")) >= 2
    var surfaces := preload("res://scripts/interior_surface_materials.gd")
    for material: StandardMaterial3D in wall_materials:
        material.normal_enabled = detailed
        material.ao_enabled = detailed
        material.roughness_texture = surfaces.PLASTER_ORM if detailed else null
        material.roughness = 1.0 if detailed else 0.94
    _update_window_light()
