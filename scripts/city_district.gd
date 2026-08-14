extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")

const CELL_SIZE := 192.0
const LOAD_RADIUS_CELLS := 2
const UNLOAD_RADIUS := 620.0
const MAX_CELL_BUILDS_PER_FRAME := 1
const CITY_SEED := 470219
const MODULE_WIDTH := 2.0
const STORY_HEIGHT := 3.12

const ASSET_ROOT := "res://assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/glTF/"
const ASSET_PATHS := {
    "wall_plaster": ASSET_ROOT + "Wall_Plaster_Straight.gltf",
    "door_plaster": ASSET_ROOT + "Wall_Plaster_Door_Round.gltf",
    "window_plaster": ASSET_ROOT + "Wall_Plaster_Window_Wide_Round.gltf",
    "wall_brick": ASSET_ROOT + "Wall_UnevenBrick_Straight.gltf",
    "door_brick": ASSET_ROOT + "Wall_UnevenBrick_Door_Round.gltf",
    "window_brick": ASSET_ROOT + "Wall_UnevenBrick_Window_Wide_Round.gltf",
    "roof": ASSET_ROOT + "Roof_RoundTiles_8x8.gltf",
    "wagon": ASSET_ROOT + "Prop_Wagon.gltf",
    "crate": ASSET_ROOT + "Prop_Crate.gltf"
}

const OPEN_DISTRICTS := {
    "central": true,
    "starter": true,
    "arena": true,
    "hippodrome": true,
    "farms": true,
    "canals": true,
    "port": true
}

var player: Node3D
var materials: Dictionary = {}
var assets: Dictionary = {}
var loaded_cells: Dictionary = {}
var pending_cells: Array[Vector2i] = []
var queued_cells: Dictionary = {}
var last_player_cell := Vector2i(999999, 999999)
var last_location := ""

func _ready() -> void:
    _prepare_materials()
    _load_city_assets()
    player = get_tree().get_first_node_in_group("player") as Node3D
    call_deferred("_initial_stream")

func _initial_stream() -> void:
    _resolve_player()
    if player != null:
        _refresh_stream(true)

func _process(_delta: float) -> void:
    _resolve_player()
    if player == null:
        return

    _update_location()
    var current_cell := _cell_for_world(player.global_position)
    if current_cell != last_player_cell:
        last_player_cell = current_cell
        _refresh_stream(false)

    var builds := 0
    while not pending_cells.is_empty() and builds < MAX_CELL_BUILDS_PER_FRAME:
        var cell := pending_cells.pop_front()
        queued_cells.erase(cell)
        if not loaded_cells.has(cell) and _should_keep_cell(cell):
            _build_cell(cell)
            builds += 1

    _unload_far_cells()

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D

func _update_location() -> void:
    var world_2d := Vector2(player.global_position.x, player.global_position.z)
    var location := "Окраины Люменграда"
    if CAPITAL.inside_capital(world_2d):
        var district: Dictionary = CAPITAL.district_at(world_2d)
        location = "Люменград"
        if not district.is_empty():
            location += " • " + String(district.get("name", "Городской квартал"))
    if location != last_location:
        last_location = location
        if GameState.current_location != location:
            GameState.set_location(location)

func _refresh_stream(force_current: bool) -> void:
    if player == null:
        return
    var world_2d := Vector2(player.global_position.x, player.global_position.z)
    if not CAPITAL.inside_capital(world_2d):
        pending_cells.clear()
        queued_cells.clear()
        return

    var current := _cell_for_world(player.global_position)
    if force_current and not loaded_cells.has(current):
        _queue_cell(current, true)

    for ring in range(0, LOAD_RADIUS_CELLS + 1):
        for x in range(-ring, ring + 1):
            for z in range(-ring, ring + 1):
                if ring > 0 and abs(x) < ring and abs(z) < ring:
                    continue
                _queue_cell(current + Vector2i(x, z), false)

func _queue_cell(cell: Vector2i, front: bool) -> void:
    if loaded_cells.has(cell) or queued_cells.has(cell):
        return
    var center := _cell_center(cell)
    if not CAPITAL.inside_capital(Vector2(center.x, center.z)):
        return
    queued_cells[cell] = true
    if front:
        pending_cells.push_front(cell)
    else:
        pending_cells.append(cell)

func _should_keep_cell(cell: Vector2i) -> bool:
    if player == null:
        return false
    var center := _cell_center(cell)
    return Vector2(center.x, center.z).distance_to(Vector2(player.global_position.x, player.global_position.z)) <= UNLOAD_RADIUS

func _unload_far_cells() -> void:
    if player == null:
        return
    var player_2d := Vector2(player.global_position.x, player.global_position.z)
    var remove: Array[Vector2i] = []
    for key in loaded_cells.keys():
        var cell: Vector2i = key
        var center := _cell_center(cell)
        if Vector2(center.x, center.z).distance_to(player_2d) > UNLOAD_RADIUS:
            remove.append(cell)
    for cell in remove:
        var root: Node = loaded_cells.get(cell)
        if is_instance_valid(root):
            root.queue_free()
        loaded_cells.erase(cell)

func _cell_for_world(pos: Vector3) -> Vector2i:
    return Vector2i(
        floori((pos.x + CELL_SIZE * 0.5) / CELL_SIZE),
        floori((pos.z + CELL_SIZE * 0.5) / CELL_SIZE)
    )

func _cell_center(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x) * CELL_SIZE, 0.0, float(cell.y) * CELL_SIZE)

func _build_cell(cell: Vector2i) -> void:
    var root := Node3D.new()
    root.name = "CityCell_%d_%d" % [cell.x, cell.y]
    root.position = _cell_center(cell)
    add_child(root)
    loaded_cells[cell] = root

    _add_static_box(
        "Ground",
        Vector3(CELL_SIZE + 0.4, 0.35, CELL_SIZE + 0.4),
        Vector3(0, -0.19, 0),
        materials["ground"],
        root
    )
    _add_road_grid(root)

    var world_pos := Vector2(root.position.x, root.position.z)
    var district: Dictionary = CAPITAL.district_at(world_pos)
    var district_id := String(district.get("id", "city"))
    _populate_cell(root, cell, district_id)

func _add_road_grid(root: Node3D) -> void:
    _add_mesh_box("RoadNS", Vector3(18.0, 0.10, CELL_SIZE + 0.6), Vector3(0, 0.045, 0), materials["road"], root)
    _add_mesh_box("RoadEW", Vector3(CELL_SIZE + 0.6, 0.10, 18.0), Vector3(0, 0.050, 0), materials["road"], root)
    _add_mesh_box("WalkNSL", Vector3(4.0, 0.12, CELL_SIZE + 0.6), Vector3(-11.0, 0.065, 0), materials["walk"], root)
    _add_mesh_box("WalkNSR", Vector3(4.0, 0.12, CELL_SIZE + 0.6), Vector3(11.0, 0.065, 0), materials["walk"], root)
    _add_mesh_box("WalkEWT", Vector3(CELL_SIZE + 0.6, 0.12, 4.0), Vector3(0, 0.070, -11.0), materials["walk"], root)
    _add_mesh_box("WalkEWB", Vector3(CELL_SIZE + 0.6, 0.12, 4.0), Vector3(0, 0.070, 11.0), materials["walk"], root)

func _populate_cell(root: Node3D, cell: Vector2i, district_id: String) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = _cell_seed(cell)

    if district_id == "central" or district_id == "starter":
        _build_plaza_detail(root, rng, district_id)
        return
    if district_id == "arena" or district_id == "hippodrome" or district_id == "farms" or district_id == "canals":
        _build_open_district_detail(root, rng, district_id)
        return

    var lots := [Vector3(-52, 0, -52), Vector3(52, 0, -52), Vector3(-52, 0, 52), Vector3(52, 0, 52)]
    var building_count := 2
    if district_id == "royal" or district_id == "rich" or district_id == "aristocratic":
        building_count = 1
    elif district_id == "market" or district_id == "crafts" or district_id == "old_town" or district_id == "residential":
        building_count = 3

    var used: Dictionary = {}
    for i in range(building_count):
        var lot_index := rng.randi_range(0, lots.size() - 1)
        var safety := 0
        while used.has(lot_index) and safety < 8:
            lot_index = rng.randi_range(0, lots.size() - 1)
            safety += 1
        used[lot_index] = true
        var rotation_step := rng.randi_range(0, 3)
        _build_medieval_house(root, lots[lot_index], float(rotation_step) * PI * 0.5, district_id, rng)

    if district_id == "market" or district_id == "crafts" or district_id == "warehouses" or district_id == "port":
        _instance_asset("wagon", root, Vector3(28, 0.12, -25), Vector3(0, rng.randf_range(-PI, PI), 0))
        for i in range(3):
            _instance_asset("crate", root, Vector3(23 + i * 1.4, 0.08, -31), Vector3.ZERO)

func _build_medieval_house(parent: Node3D, pos: Vector3, yaw: float, district_id: String, rng: RandomNumberGenerator) -> void:
    var building := Node3D.new()
    building.name = "House"
    building.position = pos
    building.rotation.y = yaw
    parent.add_child(building)

    var brick_style := district_id in ["old_town", "guards", "training", "training_mine", "warehouses", "port"]
    var wall_key := "wall_brick" if brick_style else "wall_plaster"
    var door_key := "door_brick" if brick_style else "door_plaster"
    var window_key := "window_brick" if brick_style else "window_plaster"
    var stories := 1 if district_id in ["warehouses", "port", "stables", "sawmill"] else 2
    if district_id in ["rich", "aristocratic", "royal"]:
        stories = 2

    for story in range(stories):
        var y := float(story) * STORY_HEIGHT
        for i in range(4):
            var offset := -3.0 + float(i) * MODULE_WIDTH
            var front_key := wall_key
            if story == 0 and i == 1:
                front_key = door_key
            elif i == 0 or i == 3:
                front_key = window_key
            _instance_asset(front_key, building, Vector3(offset, y, 4.0), Vector3.ZERO)
            _instance_asset(window_key if (i == 1 or i == 2) else wall_key, building, Vector3(offset, y, -4.0), Vector3(0, PI, 0))
            _instance_asset(window_key if i % 2 == 0 else wall_key, building, Vector3(4.0, y, offset), Vector3(0, PI * 0.5, 0))
            _instance_asset(window_key if i % 2 == 1 else wall_key, building, Vector3(-4.0, y, offset), Vector3(0, -PI * 0.5, 0))

    _instance_asset("roof", building, Vector3(0, float(stories) * STORY_HEIGHT, 0), Vector3.ZERO)
    _add_collision_box(Vector3(8.0, float(stories) * STORY_HEIGHT, 8.0), Vector3(0, float(stories) * STORY_HEIGHT * 0.5, 0), building)

    if rng.randf() < 0.35:
        _instance_asset("crate", building, Vector3(5.2, 0.08, 3.4), Vector3(0, rng.randf_range(-PI, PI), 0))

func _build_plaza_detail(root: Node3D, rng: RandomNumberGenerator, district_id: String) -> void:
    _add_mesh_box("PlazaStone", Vector3(116, 0.13, 116), Vector3(0, 0.075, 0), materials["plaza"], root)
    if district_id == "central":
        var base := CylinderMesh.new()
        base.top_radius = 6.0
        base.bottom_radius = 6.5
        base.height = 0.8
        base.radial_segments = 20
        var base_node := MeshInstance3D.new()
        base_node.mesh = base
        base_node.position = Vector3(0, 0.45, 0)
        base_node.material_override = materials["stone"]
        root.add_child(base_node)
    for i in range(4):
        _instance_asset("crate", root, Vector3(-18 + i * 12, 0.08, 30), Vector3(0, rng.randf_range(-PI, PI), 0))

func _build_open_district_detail(root: Node3D, rng: RandomNumberGenerator, district_id: String) -> void:
    if district_id == "farms":
        for i in range(5):
            _add_mesh_box("Field_%d" % i, Vector3(24, 0.08, 42), Vector3(-60 + i * 30, 0.045, 48), materials["soil"], root)
    elif district_id == "canals":
        _add_mesh_box("Canal", Vector3(34, 0.05, CELL_SIZE - 34), Vector3(48, 0.03, 0), materials["water"], root)
    elif district_id == "hippodrome":
        _add_mesh_box("Track", Vector3(150, 0.08, 82), Vector3(0, 0.045, 42), materials["track"], root)
    elif district_id == "arena":
        _add_mesh_box("ArenaApproach", Vector3(120, 0.08, 74), Vector3(0, 0.045, 42), materials["plaza"], root)
    if rng.randf() < 0.55:
        _instance_asset("wagon", root, Vector3(-34, 0.10, 34), Vector3(0, rng.randf_range(-PI, PI), 0))

func _load_city_assets() -> void:
    for key in ASSET_PATHS.keys():
        var path := String(ASSET_PATHS[key])
        if not ResourceLoader.exists(path):
            continue
        var resource := load(path)
        if resource is PackedScene:
            assets[key] = resource

func _instance_asset(key: String, parent: Node3D, pos: Vector3, rotation: Vector3) -> Node3D:
    var packed: PackedScene = assets.get(key) as PackedScene
    if packed == null:
        return _fallback_asset(parent, pos, rotation)
    var node := packed.instantiate() as Node3D
    if node == null:
        return _fallback_asset(parent, pos, rotation)
    node.position = pos
    node.rotation = rotation
    parent.add_child(node)
    return node

func _fallback_asset(parent: Node3D, pos: Vector3, rotation: Vector3) -> Node3D:
    var marker := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.0, 3.0, 0.25)
    mesh.material = materials["fallback"]
    marker.mesh = mesh
    marker.position = pos + Vector3(0, 1.5, 0)
    marker.rotation = rotation
    parent.add_child(marker)
    return marker

func _cell_seed(cell: Vector2i) -> int:
    return abs(CITY_SEED ^ (cell.x * 73856093) ^ (cell.y * 19349663))

func _prepare_materials() -> void:
    materials["ground"] = _material(Color(0.29, 0.31, 0.25), 0.98)
    materials["road"] = _material(Color(0.22, 0.205, 0.19), 0.97)
    materials["walk"] = _material(Color(0.38, 0.36, 0.33), 0.94)
    materials["plaza"] = _material(Color(0.43, 0.42, 0.40), 0.93)
    materials["stone"] = _material(Color(0.34, 0.36, 0.38), 0.92)
    materials["soil"] = _material(Color(0.25, 0.18, 0.11), 0.98)
    materials["track"] = _material(Color(0.34, 0.24, 0.16), 0.98)
    materials["water"] = _material(Color(0.08, 0.31, 0.42), 0.24)
    materials["fallback"] = _material(Color(0.34, 0.22, 0.12), 0.94)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material

func _add_mesh_box(node_name: String, size: Vector3, pos: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    parent.add_child(mesh_instance)
    return mesh_instance

func _add_static_box(node_name: String, size: Vector3, pos: Vector3, material: Material, parent: Node3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    parent.add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_instance.mesh = mesh
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _add_collision_box(size: Vector3, pos: Vector3, parent: Node3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = pos
    parent.add_child(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body
