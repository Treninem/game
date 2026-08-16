extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")
const ENTERABLE_TOWNHOUSE := preload("res://scripts/enterable_townhouse.gd")

const CELL_SIZE := 192.0
const LOAD_RADIUS_CELLS := 2
const UNLOAD_RADIUS := 620.0
const MAX_CELL_BUILDS_PER_FRAME := 1
const CITY_SEED := 470219
const MODULE_WIDTH := 2.0
const STORY_HEIGHT := 3.12
const LANDMARK_LOT_CLEARANCE := 84.0

const ASSET_ROOT := "res://assets/production/medieval/quaternius_city_core/"
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

const DENSE_STREET_DISTRICTS := [
    "central", "starter", "market", "crafts", "old_town", "residential", "guilds", "adventurers"
]
const GRAND_STREET_DISTRICTS := ["central", "starter", "royal", "aristocratic", "guilds"]
const OPEN_DISTRICTS := ["arena", "hippodrome", "farms", "canals"]
const INDUSTRIAL_DISTRICTS := ["crafts", "warehouses", "port", "sawmill", "training_mine"]
const ELITE_DISTRICTS := ["rich", "aristocratic", "royal"]

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
    var current_cell: Vector2i = _cell_for_world(player.global_position)
    if current_cell != last_player_cell:
        last_player_cell = current_cell
        _refresh_stream(false)

    var builds: int = 0
    while not pending_cells.is_empty() and builds < MAX_CELL_BUILDS_PER_FRAME:
        var cell: Vector2i = pending_cells.pop_front()
        queued_cells.erase(cell)
        if not loaded_cells.has(cell) and _should_keep_cell(cell):
            _build_cell(cell)
            builds += 1

    _unload_far_cells()

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D

func _update_location() -> void:
    var world_2d: Vector2 = Vector2(player.global_position.x, player.global_position.z)
    var location: String = "Окраины Люменграда"
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
    var world_2d: Vector2 = Vector2(player.global_position.x, player.global_position.z)
    if not CAPITAL.inside_capital(world_2d):
        pending_cells.clear()
        queued_cells.clear()
        return

    var current: Vector2i = _cell_for_world(player.global_position)
    if force_current and not loaded_cells.has(current):
        _queue_cell(current, true)

    for ring in range(0, LOAD_RADIUS_CELLS + 1):
        for x in range(-ring, ring + 1):
            for z in range(-ring, ring + 1):
                if ring > 0 and absi(x) < ring and absi(z) < ring:
                    continue
                _queue_cell(current + Vector2i(x, z), false)

func _queue_cell(cell: Vector2i, front: bool) -> void:
    if loaded_cells.has(cell) or queued_cells.has(cell):
        return
    var center: Vector3 = _cell_center(cell)
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
    var center: Vector3 = _cell_center(cell)
    return Vector2(center.x, center.z).distance_to(Vector2(player.global_position.x, player.global_position.z)) <= UNLOAD_RADIUS

func _unload_far_cells() -> void:
    if player == null:
        return
    var player_2d: Vector2 = Vector2(player.global_position.x, player.global_position.z)
    var remove: Array[Vector2i] = []
    for key in loaded_cells.keys():
        var cell: Vector2i = key
        var center: Vector3 = _cell_center(cell)
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

func _cell_for_point(pos: Vector2) -> Vector2i:
    return Vector2i(
        floori((pos.x + CELL_SIZE * 0.5) / CELL_SIZE),
        floori((pos.y + CELL_SIZE * 0.5) / CELL_SIZE)
    )

func _cell_center(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x) * CELL_SIZE, 0.0, float(cell.y) * CELL_SIZE)

func _district_core_cell(district_id: String) -> Vector2i:
    for district in CAPITAL.DISTRICTS:
        if String(district.get("id", "")) == district_id:
            return _cell_for_point(district.get("center", Vector2.ZERO))
    return Vector2i(999999, 999999)

func _is_civic_core(cell: Vector2i, district_id: String) -> bool:
    return district_id in ["central", "starter"] and cell == _district_core_cell(district_id)

func _lot_is_clear(root: Node3D, lot: Vector3) -> bool:
    var world_lot: Vector2 = Vector2(root.position.x + lot.x, root.position.z + lot.z)
    return CAPITAL.protected_infrastructure_near(world_lot, LANDMARK_LOT_CLEARANCE).is_empty()

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

    var world_pos: Vector2 = Vector2(root.position.x, root.position.z)
    var district: Dictionary = CAPITAL.district_at(world_pos)
    var district_id: String = String(district.get("id", "city"))
    _add_road_network(root, cell, district_id)
    _populate_cell(root, cell, district_id)

func _add_road_network(root: Node3D, cell: Vector2i, district_id: String) -> void:
    var dense: bool = district_id in DENSE_STREET_DISTRICTS
    var open_area: bool = district_id in OPEN_DISTRICTS
    var ns_enabled: bool = dense or absi(cell.x) % 2 == 0
    var ew_enabled: bool = dense or absi(cell.y) % 2 == 0
    var road_width: float = _road_width_for(cell, district_id)
    var road_material: Material = materials["track"] if district_id == "farms" else materials["road"]
    var sidewalks: bool = not open_area and district_id != "sawmill" and district_id != "training_mine"

    if ns_enabled:
        _add_road_strip(root, "RoadNS", true, road_width, 0.0, road_material, sidewalks)
    if ew_enabled:
        _add_road_strip(root, "RoadEW", false, road_width, 0.0, road_material, sidewalks)

    if district_id in ["market", "crafts", "old_town", "residential"]:
        var alley_vertical: bool = absi(cell.x + cell.y) % 2 == 0
        var alley_offset: float = 58.0 if absi(cell.x * 3 + cell.y) % 2 == 0 else -58.0
        _add_road_strip(root, "Lane", alley_vertical, 7.0, alley_offset, materials["lane"], false)

    if _is_civic_core(cell, district_id):
        _add_mesh_box("CivicCrossing", Vector3(34.0, 0.115, 34.0), Vector3(0, 0.060, 0), materials["plaza"], root)

func _road_width_for(cell: Vector2i, district_id: String) -> float:
    if district_id in OPEN_DISTRICTS:
        return 9.0
    if district_id in GRAND_STREET_DISTRICTS:
        return 20.0 if absi(cell.x + cell.y) % 4 == 0 else 16.0
    if district_id in INDUSTRIAL_DISTRICTS or district_id in ["guards", "training"]:
        return 14.0
    return 12.0 if absi(cell.x + cell.y) % 3 != 0 else 15.0

func _add_road_strip(
    root: Node3D,
    node_name: String,
    vertical: bool,
    width: float,
    offset: float,
    material: Material,
    sidewalks: bool
) -> void:
    var road_size: Vector3 = Vector3(width, 0.10, CELL_SIZE + 0.6) if vertical else Vector3(CELL_SIZE + 0.6, 0.10, width)
    var road_pos: Vector3 = Vector3(offset, 0.045, 0) if vertical else Vector3(0, 0.045, offset)
    _add_mesh_box(node_name, road_size, road_pos, material, root)

    if not sidewalks:
        return
    var sidewalk_offset: float = width * 0.5 + 2.2
    if vertical:
        _add_mesh_box(node_name + "WalkL", Vector3(3.4, 0.12, CELL_SIZE + 0.6), Vector3(offset - sidewalk_offset, 0.065, 0), materials["walk"], root)
        _add_mesh_box(node_name + "WalkR", Vector3(3.4, 0.12, CELL_SIZE + 0.6), Vector3(offset + sidewalk_offset, 0.065, 0), materials["walk"], root)
    else:
        _add_mesh_box(node_name + "WalkT", Vector3(CELL_SIZE + 0.6, 0.12, 3.4), Vector3(0, 0.065, offset - sidewalk_offset), materials["walk"], root)
        _add_mesh_box(node_name + "WalkB", Vector3(CELL_SIZE + 0.6, 0.12, 3.4), Vector3(0, 0.065, offset + sidewalk_offset), materials["walk"], root)

func _populate_cell(root: Node3D, cell: Vector2i, district_id: String) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = _cell_seed(cell)

    if _is_civic_core(cell, district_id):
        _build_plaza_detail(root, rng, district_id)
        return
    if district_id in OPEN_DISTRICTS:
        _build_open_district_detail(root, rng, district_id)
        return
    if district_id == "port":
        _build_port_detail(root, rng)
        return

    var base_lots: Array[Vector3] = [
        Vector3(-54, 0, -54), Vector3(54, 0, -54),
        Vector3(-54, 0, 54), Vector3(54, 0, 54)
    ]
    var available_lots: Array[Vector3] = []
    for base_lot in base_lots:
        var lot: Vector3 = base_lot
        lot.x += rng.randf_range(-6.0, 6.0)
        lot.z += rng.randf_range(-6.0, 6.0)
        if _lot_is_clear(root, lot):
            available_lots.append(lot)

    var building_count: int = mini(_building_count_for(district_id), available_lots.size())
    for i in range(building_count):
        var lot_index: int = rng.randi_range(0, available_lots.size() - 1)
        var lot: Vector3 = available_lots[lot_index]
        available_lots.remove_at(lot_index)
        var rotation_step: int = rng.randi_range(0, 3)
        _build_medieval_house(root, lot, float(rotation_step) * PI * 0.5, district_id, rng)

    _add_district_props(root, district_id, rng)

func _building_count_for(district_id: String) -> int:
    if district_id in ["market", "crafts", "old_town", "residential"]:
        return 3
    if district_id in ELITE_DISTRICTS:
        return 1
    if district_id in ["stables", "sawmill", "training_mine"]:
        return 1
    return 2

func _add_district_props(root: Node3D, district_id: String, rng: RandomNumberGenerator) -> void:
    if district_id in ["market", "crafts", "warehouses", "sawmill"]:
        _instance_asset("wagon", root, Vector3(28, 0.12, -25), Vector3(0, rng.randf_range(-PI, PI), 0))
        var crate_count: int = 4 if district_id == "warehouses" else 2
        for i in range(crate_count):
            _instance_asset("crate", root, Vector3(23 + i * 1.5, 0.08, -31), Vector3.ZERO)
    elif district_id in ["guards", "training", "guilds", "adventurers"]:
        for i in range(2):
            _instance_asset("crate", root, Vector3(-28 + i * 3.0, 0.08, 27), Vector3(0, rng.randf_range(-0.2, 0.2), 0))
    elif district_id == "stables":
        _instance_asset("wagon", root, Vector3(-28, 0.12, 30), Vector3(0, rng.randf_range(-PI, PI), 0))

func _build_medieval_house(parent: Node3D, pos: Vector3, yaw: float, district_id: String, rng: RandomNumberGenerator) -> EnterableTownhouse:
    var brick_style: bool = district_id in ["old_town", "guards", "training", "training_mine", "warehouses", "port", "crafts"]
    var stories: int = _story_count_for(district_id)
    var label := "Городской дом"
    if district_id in INDUSTRIAL_DISTRICTS:
        label = "Городское рабочее здание"

    var building := ENTERABLE_TOWNHOUSE.new() as EnterableTownhouse
    building.name = "House"
    building.configure(Vector2(8.0, 8.0), stories, STORY_HEIGHT, 1 if brick_style else 0, label)
    building.position = pos
    building.rotation.y = yaw
    building.set_meta("district_id", district_id)
    building.set_meta("streamed_with_city_cell", true)
    parent.add_child(building)

    var clutter_chance: float = 0.55 if district_id in INDUSTRIAL_DISTRICTS else 0.24
    if rng.randf() < clutter_chance:
        _instance_asset("crate", building, Vector3(5.2, 0.08, 3.4), Vector3(0, rng.randf_range(-PI, PI), 0))

    return building

func _story_count_for(district_id: String) -> int:
    if district_id in ["warehouses", "port", "stables", "sawmill", "training_mine"]:
        return 1
    if district_id in ELITE_DISTRICTS:
        return 3
    return 2

func _build_plaza_detail(root: Node3D, rng: RandomNumberGenerator, district_id: String) -> void:
    var plaza_size: float = 124.0 if district_id == "central" else 108.0
    _add_mesh_box("PlazaStone", Vector3(plaza_size, 0.13, plaza_size), Vector3(0, 0.075, 0), materials["plaza"], root)
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
        var field_positions: Array[Vector3] = [Vector3(-52, 0.045, -52), Vector3(52, 0.045, -52), Vector3(-52, 0.045, 52), Vector3(52, 0.045, 52)]
        for i in range(field_positions.size()):
            var size: Vector3 = Vector3(rng.randf_range(38.0, 54.0), 0.08, rng.randf_range(42.0, 62.0))
            _add_mesh_box("Field_%d" % i, size, field_positions[i], materials["soil"], root)
    elif district_id == "canals":
        _add_mesh_box("Canal", Vector3(30, 0.05, CELL_SIZE - 28), Vector3(52, 0.03, 0), materials["water"], root)
        _add_mesh_box("CanalBank", Vector3(5, 0.14, CELL_SIZE - 28), Vector3(33.0, 0.07, 0), materials["stone"], root)
        _add_mesh_box("CanalBank2", Vector3(5, 0.14, CELL_SIZE - 28), Vector3(71.0, 0.07, 0), materials["stone"], root)
    elif district_id == "hippodrome":
        _build_hippodrome_track(root)
    elif district_id == "arena":
        _add_mesh_box("ArenaApproach", Vector3(126, 0.08, 82), Vector3(0, 0.045, 42), materials["plaza"], root)
        _add_mesh_box("ArenaAxis", Vector3(28, 0.09, 150), Vector3(0, 0.05, 0), materials["track"], root)

    if rng.randf() < 0.48:
        _instance_asset("wagon", root, Vector3(-34, 0.10, 34), Vector3(0, rng.randf_range(-PI, PI), 0))

func _build_hippodrome_track(root: Node3D) -> void:
    _add_mesh_box("TrackNorth", Vector3(142, 0.08, 14), Vector3(0, 0.045, -52), materials["track"], root)
    _add_mesh_box("TrackSouth", Vector3(142, 0.08, 14), Vector3(0, 0.045, 52), materials["track"], root)
    _add_mesh_box("TrackWest", Vector3(14, 0.08, 104), Vector3(-64, 0.045, 0), materials["track"], root)
    _add_mesh_box("TrackEast", Vector3(14, 0.08, 104), Vector3(64, 0.045, 0), materials["track"], root)

func _build_port_detail(root: Node3D, rng: RandomNumberGenerator) -> void:
    _add_mesh_box("HarborWater", Vector3(58, 0.05, CELL_SIZE - 18), Vector3(66, 0.03, 0), materials["water"], root)
    _add_mesh_box("Quay", Vector3(24, 0.15, CELL_SIZE - 18), Vector3(24, 0.075, 0), materials["stone"], root)
    _build_medieval_house(root, Vector3(-50, 0, -48), 0.0, "warehouses", rng)
    _instance_asset("wagon", root, Vector3(-22, 0.12, 31), Vector3(0, rng.randf_range(-PI, PI), 0))
    for i in range(5):
        _instance_asset("crate", root, Vector3(-8 + float(i % 3) * 2.0, 0.08, -30 + float(i / 3) * 2.0), Vector3.ZERO)

func _load_city_assets() -> void:
    for key in ASSET_PATHS.keys():
        var path: String = String(ASSET_PATHS[key])
        if not ResourceLoader.exists(path):
            continue
        var resource: Resource = load(path)
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
    return absi(CITY_SEED ^ (cell.x * 73856093) ^ (cell.y * 19349663))

func _prepare_materials() -> void:
    materials["ground"] = _material(Color(0.29, 0.31, 0.25), 0.98)
    materials["road"] = _material(Color(0.22, 0.205, 0.19), 0.97)
    materials["lane"] = _material(Color(0.28, 0.25, 0.21), 0.99)
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
