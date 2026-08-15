extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")
const ROOF_SCENE: PackedScene = preload("res://assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/glTF/Roof_RoundTiles_8x8.gltf")
const CRATE_SCENE: PackedScene = preload("res://assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/glTF/Prop_Crate.gltf")

const CELL_SIZE := 160.0
const LOAD_RADIUS_CELLS := 2
const UNLOAD_RADIUS := 520.0
const BUILD_INTERVAL := 0.10
const CITY_SEED := 470219

var player: Node3D
var loaded_cells: Dictionary = {}
var pending_cells: Array[Vector2i] = []
var queued_cells: Dictionary = {}
var last_player_cell := Vector2i(999999, 999999)
var build_elapsed := 0.0
var last_location := ""

var ground_material: StandardMaterial3D
var road_material: StandardMaterial3D
var plaza_material: StandardMaterial3D
var wall_materials: Array[StandardMaterial3D] = []
var roof_fallback_material: StandardMaterial3D
var trim_material: StandardMaterial3D

func _ready() -> void:
    process_priority = 40
    _prepare_materials()
    call_deferred("_bootstrap_city")

func _bootstrap_city() -> void:
    _resolve_player()
    if player == null:
        return
    last_player_cell = _cell_for_world(player.global_position)
    _build_cell(last_player_cell)
    _refresh_queue(last_player_cell)

func _process(delta: float) -> void:
    _resolve_player()
    if player == null:
        return

    _update_location()
    var current := _cell_for_world(player.global_position)
    if current != last_player_cell:
        last_player_cell = current
        _refresh_queue(current)

    build_elapsed += delta
    if build_elapsed >= BUILD_INTERVAL and not pending_cells.is_empty():
        build_elapsed = 0.0
        var cell: Vector2i = pending_cells.pop_front()
        queued_cells.erase(cell)
        if not loaded_cells.has(cell) and _should_keep_cell(cell):
            _build_cell(cell)

    _unload_far_cells()

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D

func _update_location() -> void:
    var p := Vector2(player.global_position.x, player.global_position.z)
    if not CAPITAL.inside_capital(p):
        return
    var district: Dictionary = CAPITAL.district_at(p)
    var location := "Люменград"
    if not district.is_empty():
        location += " • " + String(district.get("name", "Городской квартал"))
    if location != last_location:
        last_location = location
        if GameState.current_location != location:
            GameState.set_location(location)

func _refresh_queue(center: Vector2i) -> void:
    pending_cells.clear()
    queued_cells.clear()
    for ring in range(0, LOAD_RADIUS_CELLS + 1):
        for x in range(center.x - ring, center.x + ring + 1):
            for z in range(center.y - ring, center.y + ring + 1):
                var cell := Vector2i(x, z)
                if maxi(absi(cell.x - center.x), absi(cell.y - center.y)) != ring:
                    continue
                if loaded_cells.has(cell) or queued_cells.has(cell):
                    continue
                if not CAPITAL.inside_capital(_cell_center_2d(cell)):
                    continue
                queued_cells[cell] = true
                pending_cells.append(cell)

func _should_keep_cell(cell: Vector2i) -> bool:
    if player == null:
        return false
    return _cell_center_2d(cell).distance_to(Vector2(player.global_position.x, player.global_position.z)) <= UNLOAD_RADIUS

func _unload_far_cells() -> void:
    var remove: Array[Vector2i] = []
    var p := Vector2(player.global_position.x, player.global_position.z)
    for key in loaded_cells.keys():
        var cell: Vector2i = key
        if _cell_center_2d(cell).distance_to(p) > UNLOAD_RADIUS:
            remove.append(cell)
    for cell in remove:
        var node: Node = loaded_cells.get(cell)
        if is_instance_valid(node):
            node.queue_free()
        loaded_cells.erase(cell)

func _build_cell(cell: Vector2i) -> void:
    if loaded_cells.has(cell):
        return
    var center := _cell_center_2d(cell)
    if not CAPITAL.inside_capital(center):
        return

    var root := Node3D.new()
    root.name = "CityCell_%d_%d" % [cell.x, cell.y]
    root.position = Vector3(center.x, 0.0, center.y)
    add_child(root)
    loaded_cells[cell] = root

    var base_y := WorldData.elevation_at(center)
    _add_mesh_box("DistrictPaving", Vector3(CELL_SIZE - 2.0, 0.08, CELL_SIZE - 2.0), Vector3(0.0, base_y + 0.015, 0.0), ground_material, root)
    _add_mesh_box("RoadNS", Vector3(14.0, 0.11, CELL_SIZE), Vector3(0.0, base_y + 0.07, 0.0), road_material, root)
    _add_mesh_box("RoadEW", Vector3(CELL_SIZE, 0.11, 14.0), Vector3(0.0, base_y + 0.075, 0.0), road_material, root)

    var district: Dictionary = CAPITAL.district_at(center)
    var district_id := String(district.get("id", "city"))
    if district_id == "central" and cell == Vector2i.ZERO:
        _build_spawn_square(root, center)
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = absi(CITY_SEED ^ (cell.x * 73856093) ^ (cell.y * 19349663))
    var lots: Array[Vector2] = [Vector2(-48, -48), Vector2(48, -48), Vector2(-48, 48), Vector2(48, 48)]
    var house_count := 2
    if district_id in ["market", "crafts", "old_town", "residential"]:
        house_count = 3
    elif district_id in ["arena", "hippodrome", "farms", "canals"]:
        house_count = 1

    for i in range(mini(house_count, lots.size())):
        var lot := lots[i]
        lot.x += rng.randf_range(-7.0, 7.0)
        lot.y += rng.randf_range(-7.0, 7.0)
        var world_lot := center + lot
        var y := WorldData.elevation_at(world_lot)
        var width := rng.randf_range(12.0, 18.0)
        var depth := rng.randf_range(11.0, 17.0)
        var height := rng.randf_range(6.5, 10.5)
        _build_house(root, Vector3(lot.x, y, lot.y), Vector3(width, height, depth), i, rng)

    if cell.x % 2 == 0:
        _spawn_real_crate(root, Vector3(18.0, base_y + 0.12, -22.0), float(cell.y) * 0.31)

func _build_spawn_square(root: Node3D, center: Vector2) -> void:
    var base_y := WorldData.elevation_at(center)
    _add_mesh_box("CentralPlaza", Vector3(118.0, 0.14, 118.0), Vector3(0.0, base_y + 0.10, 0.0), plaza_material, root)

    var hall_world := center + Vector2(0.0, -58.0)
    var hall_y := WorldData.elevation_at(hall_world)
    _build_house(root, Vector3(0.0, hall_y, -58.0), Vector3(30.0, 14.0, 20.0), 0, null)

    var left_world := center + Vector2(-45.0, -30.0)
    var right_world := center + Vector2(45.0, -30.0)
    _build_house(root, Vector3(-45.0, WorldData.elevation_at(left_world), -30.0), Vector3(16.0, 8.0, 14.0), 1, null)
    _build_house(root, Vector3(45.0, WorldData.elevation_at(right_world), -30.0), Vector3(16.0, 8.5, 14.0), 2, null)

    for i in range(4):
        _spawn_real_crate(root, Vector3(-12.0 + float(i) * 8.0, base_y + 0.12, 28.0), float(i) * 0.35)

func _build_house(parent: Node3D, base_pos: Vector3, size: Vector3, variant: int, rng: RandomNumberGenerator) -> void:
    var body := StaticBody3D.new()
    body.name = "House_%d" % variant
    body.position = Vector3(base_pos.x, base_pos.y + size.y * 0.5, base_pos.z)
    parent.add_child(body)

    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = wall_materials[variant % wall_materials.size()]
    mesh_node.mesh = mesh
    body.add_child(mesh_node)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

    var roof := ROOF_SCENE.instantiate() as Node3D
    if roof != null:
        roof.name = "RealPackRoof"
        roof.position = Vector3(0.0, size.y * 0.5 + 0.15, 0.0)
        roof.scale = Vector3(maxf(0.7, size.x / 8.0), maxf(0.7, size.y / 12.0), maxf(0.7, size.z / 8.0))
        body.add_child(roof)
    else:
        _add_mesh_box("RoofFallback", Vector3(size.x + 1.0, 1.0, size.z + 1.0), Vector3(0.0, size.y * 0.5 + 0.5, 0.0), roof_fallback_material, body)

    var door := MeshInstance3D.new()
    var door_mesh := BoxMesh.new()
    door_mesh.size = Vector3(2.0, 3.2, 0.18)
    door_mesh.material = trim_material
    door.mesh = door_mesh
    door.position = Vector3(0.0, -size.y * 0.5 + 1.6, size.z * 0.5 + 0.10)
    body.add_child(door)

    if rng != null and rng.randf() < 0.45:
        _spawn_real_crate(parent, Vector3(base_pos.x + size.x * 0.6, base_pos.y + 0.1, base_pos.z + size.z * 0.35), rng.randf_range(-PI, PI))

func _spawn_real_crate(parent: Node3D, pos: Vector3, yaw: float) -> void:
    var node := CRATE_SCENE.instantiate() as Node3D
    if node == null:
        return
    node.name = "RealPackCrate"
    node.position = pos
    node.rotation.y = yaw
    parent.add_child(node)

func _cell_for_world(pos: Vector3) -> Vector2i:
    var local := Vector2(pos.x, pos.z) - CAPITAL.CENTER
    return Vector2i(
        floori((local.x + CELL_SIZE * 0.5) / CELL_SIZE),
        floori((local.y + CELL_SIZE * 0.5) / CELL_SIZE)
    )

func _cell_center_2d(cell: Vector2i) -> Vector2:
    return CAPITAL.CENTER + Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE)

func _prepare_materials() -> void:
    ground_material = _material(Color(0.27, 0.28, 0.24), 0.98)
    road_material = _material(Color(0.20, 0.19, 0.18), 0.96)
    plaza_material = _material(Color(0.39, 0.39, 0.38), 0.93)
    wall_materials = [
        _material(Color(0.52, 0.43, 0.31), 0.92),
        _material(Color(0.63, 0.56, 0.43), 0.90),
        _material(Color(0.43, 0.34, 0.27), 0.95),
        _material(Color(0.70, 0.66, 0.55), 0.91)
    ]
    roof_fallback_material = _material(Color(0.25, 0.09, 0.055), 0.95)
    trim_material = _material(Color(0.16, 0.075, 0.035), 0.94)

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
