class_name WorldSettlements
extends Node3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const ENTERABLE_BUILDING_PATH := "res://scripts/enterable_building.gd"
const SETTLEMENT_NPC_PATH := "res://scripts/settlement_npc.gd"

const LOAD_RADIUS := 980.0
const UNLOAD_RADIUS := 1280.0
const UPDATE_INTERVAL := 0.45
const VILLAGE_HALF_SIZE := Vector2(78.0, 68.0)
const TOWN_HALF_SIZE := Vector2(150.0, 115.0)
const TOWN_WALL_HEIGHT := 5.6
const TOWN_WALL_THICKNESS := 2.2
const TOWN_GATE_HALF_WIDTH := 7.0
const TOWN_GATE_CLEAR_HEIGHT := 6.2

var player: Node3D
var update_elapsed := 0.0
var loaded: Dictionary = {}
var materialized_buildings := 0
var materialized_settlements := 0
var materialized_wall_segments := 0
var materialized_gate_passages := 0
var materialized_npcs := 0

var earth_material: StandardMaterial3D
var path_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var timber_material: StandardMaterial3D
var water_material: StandardMaterial3D
var _enterable_building_script: Script
var _settlement_npc_script: Script

func _ready() -> void:
    process_priority = 44
    _prepare_materials()
    call_deferred("_update_streaming")

func _process(delta: float) -> void:
    update_elapsed += delta
    if update_elapsed < UPDATE_INTERVAL:
        return
    update_elapsed = 0.0
    _update_streaming()

func settlement_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary] = []
    for poi in GEOGRAPHY.poi_catalog():
        var id := String(poi.get("id", ""))
        if id == "border_village_01" or id == "border_village_02":
            specs.append({
                "id": id,
                "name": String(poi.get("name", "Деревня")),
                "center": poi.get("pos", Vector2.ZERO),
                "kind": "village"
            })
        elif id == "first_fortified_town":
            specs.append({
                "id": id,
                "name": String(poi.get("name", "Укреплённый город")),
                "center": poi.get("pos", Vector2.ZERO),
                "kind": "fortified_town"
            })
    return specs

func settlement_spec(id: String) -> Dictionary:
    for spec in settlement_specs():
        if String(spec.get("id", "")) == id:
            return spec
    return {}

func materialize_settlement_for_test(id: String) -> Node3D:
    var spec := settlement_spec(id)
    if spec.is_empty():
        return null
    return _materialize_settlement(spec)

func loaded_settlement_count() -> int:
    return loaded.size()

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D

func _update_streaming() -> void:
    _resolve_player()
    if player == null:
        return
    var p := Vector2(player.global_position.x, player.global_position.z)
    for spec in settlement_specs():
        var id := String(spec.get("id", ""))
        var center: Vector2 = spec.get("center", Vector2.ZERO)
        var distance := p.distance_to(center)
        if distance <= LOAD_RADIUS and not loaded.has(id):
            _materialize_settlement(spec)
        elif distance > UNLOAD_RADIUS and loaded.has(id):
            var node: Node = loaded.get(id)
            if is_instance_valid(node):
                node.queue_free()
            loaded.erase(id)
    _update_location(p)

func _update_location(player_pos: Vector2) -> void:
    var closest: Dictionary = {}
    var closest_distance := INF
    for spec in settlement_specs():
        var center: Vector2 = spec.get("center", Vector2.ZERO)
        var radius := 105.0 if String(spec.get("kind", "")) == "village" else 175.0
        var distance := player_pos.distance_to(center)
        if distance <= radius and distance < closest_distance:
            closest = spec
            closest_distance = distance
    if not closest.is_empty():
        var location := String(closest.get("name", "Поселение"))
        if GameState.current_location != location:
            GameState.set_location(location)

func _materialize_settlement(spec: Dictionary) -> Node3D:
    var id := String(spec.get("id", ""))
    if loaded.has(id):
        var existing: Node3D = loaded.get(id)
        if is_instance_valid(existing):
            return existing
        loaded.erase(id)

    var center: Vector2 = spec.get("center", Vector2.ZERO)
    var root := Node3D.new()
    root.name = "Settlement_%s" % id
    root.set_meta("settlement_id", id)
    root.set_meta("settlement_kind", String(spec.get("kind", "")))
    root.position = Vector3(center.x, WorldData.elevation_at(center), center.y)
    add_child(root)
    loaded[id] = root

    if String(spec.get("kind", "")) == "fortified_town":
        _build_fortified_town(root, center)
    else:
        _build_village(root, center, id)

    materialized_settlements += 1
    return root

func _build_village(root: Node3D, center: Vector2, id: String) -> void:
    var yaw := _road_facing_yaw(center)
    root.rotation.y = yaw
    _add_surface(root, "VillageSquare", Vector2(52.0, 40.0), Vector2.ZERO, 0.055, earth_material)
    _add_surface(root, "VillageThroughRoad", Vector2(7.0, VILLAGE_HALF_SIZE.y * 2.25), Vector2.ZERO, 0.065, path_material)

    var layouts: Array[Dictionary] = [
        {"p":Vector2(-42,-34), "s":Vector3(10.0,3.35,8.5), "r":0.35},
        {"p":Vector2(0,-46), "s":Vector3(12.0,3.6,9.5), "r":0.0},
        {"p":Vector2(43,-31), "s":Vector3(9.5,3.3,8.0), "r":-0.32},
        {"p":Vector2(-48,18), "s":Vector3(11.0,3.45,9.0), "r":0.22},
        {"p":Vector2(46,20), "s":Vector3(10.5,3.5,8.8), "r":-0.25},
        {"p":Vector2(-28,48), "s":Vector3(9.5,3.25,8.0), "r":0.15},
        {"p":Vector2(28,48), "s":Vector3(14.0,4.1,11.0), "r":-0.12}
    ]
    if id == "border_village_02":
        layouts.append({"p":Vector2(58,-2), "s":Vector3(9.0,3.2,8.0), "r":-PI * 0.5})

    for i in range(layouts.size()):
        var item: Dictionary = layouts[i]
        var label := "Дом поселения"
        if i == layouts.size() - 1:
            label = "Общий дом поселения"
        _add_enterable_building(root, center, item.get("p", Vector2.ZERO), item.get("s", Vector3(10,3.4,9)), float(item.get("r", 0.0)), i, label)

    _add_village_fence(root, center)
    _add_well(root, center, Vector2(-8.0, 3.0))
    _add_crate_stack(root, center, Vector2(12.0, 8.0))
    _populate_village(root, center, id)

func _build_village_fence(root: Node3D, center: Vector2) -> void:
    var x := VILLAGE_HALF_SIZE.x
    var z := VILLAGE_HALF_SIZE.y
    var gate_half := 5.0
    _add_static_box_local(root, center, "FenceBack", Vector3(x * 2.0, 1.15, 0.24), Vector2(0, -z), 0.58, timber_material)
    _add_static_box_local(root, center, "FenceLeft", Vector3(0.24, 1.15, z * 2.0), Vector2(-x, 0), 0.58, timber_material)
    _add_static_box_local(root, center, "FenceRight", Vector3(0.24, 1.15, z * 2.0), Vector2(x, 0), 0.58, timber_material)
    var front_length := x - gate_half
    _add_static_box_local(root, center, "FenceFrontLeft", Vector3(front_length, 1.15, 0.24), Vector2(-(gate_half + front_length * 0.5), z), 0.58, timber_material)
    _add_static_box_local(root, center, "FenceFrontRight", Vector3(front_length, 1.15, 0.24), Vector2(gate_half + front_length * 0.5, z), 0.58, timber_material)
    var gate := Marker3D.new()
    gate.name = "VillageGatePassage"
    gate.position = _local_position_on_terrain(root, center, Vector2(0, z), 0.05)
    root.add_child(gate)
    materialized_gate_passages += 1

func _build_fortified_town(root: Node3D, center: Vector2) -> void:
    var yaw := _road_facing_yaw(center)
    root.rotation.y = yaw
    _add_surface(root, "TownGround", Vector2(TOWN_HALF_SIZE.x * 1.92, TOWN_HALF_SIZE.y * 1.90), Vector2.ZERO, 0.045, earth_material)
    _add_surface(root, "TownMainRoad", Vector2(10.0, TOWN_HALF_SIZE.y * 2.05), Vector2.ZERO, 0.075, path_material)
    _add_surface(root, "TownCrossRoad", Vector2(TOWN_HALF_SIZE.x * 1.75, 8.0), Vector2(0, -4), 0.073, path_material)
    _build_town_walls(root, center)

    var buildings: Array[Dictionary] = [
        {"p":Vector2(-55,-72), "s":Vector3(12,3.7,10), "r":0.15},
        {"p":Vector2(-18,-72), "s":Vector3(10,3.5,9), "r":0.05},
        {"p":Vector2(25,-70), "s":Vector3(11,3.55,9), "r":-0.08},
        {"p":Vector2(65,-68), "s":Vector3(13,3.9,10), "r":-0.18},
        {"p":Vector2(-82,-22), "s":Vector3(11,3.5,9), "r":PI*0.5},
        {"p":Vector2(80,-22), "s":Vector3(11,3.5,9), "r":-PI*0.5},
        {"p":Vector2(-82,30), "s":Vector3(12,3.7,10), "r":PI*0.5},
        {"p":Vector2(82,30), "s":Vector3(12,3.7,10), "r":-PI*0.5},
        {"p":Vector2(-62,73), "s":Vector3(11,3.55,9), "r":PI},
        {"p":Vector2(-22,72), "s":Vector3(10,3.45,9), "r":PI},
        {"p":Vector2(23,72), "s":Vector3(10,3.45,9), "r":PI},
        {"p":Vector2(64,72), "s":Vector3(12,3.7,10), "r":PI},
        {"p":Vector2(-42,16), "s":Vector3(14,4.1,11), "r":0.0},
        {"p":Vector2(42,16), "s":Vector3(14,4.1,11), "r":0.0},
        {"p":Vector2(0,18), "s":Vector3(18,5.0,13), "r":0.0}
    ]
    for i in range(buildings.size()):
        var item: Dictionary = buildings[i]
        var label := "Городской дом"
        if i == buildings.size() - 1:
            label = "Главное здание города"
        _add_enterable_building(root, center, item.get("p", Vector2.ZERO), item.get("s", Vector3(11,3.5,9)), float(item.get("r", 0.0)), i, label)

    _add_well(root, center, Vector2(0.0, -18.0))
    _add_crate_stack(root, center, Vector2(24.0, -18.0))
    _add_crate_stack(root, center, Vector2(-26.0, -18.0))
    _populate_town(root, center)

func _build_town_walls(root: Node3D, center: Vector2) -> void:
    var x := TOWN_HALF_SIZE.x
    var z := TOWN_HALF_SIZE.y
    var gate_half := TOWN_GATE_HALF_WIDTH
    var front_length := x - gate_half
    _add_town_wall(root, center, "TownWallFrontLeft", Vector3(front_length, TOWN_WALL_HEIGHT, TOWN_WALL_THICKNESS), Vector2(-(gate_half + front_length * 0.5), z))
    _add_town_wall(root, center, "TownWallFrontRight", Vector3(front_length, TOWN_WALL_HEIGHT, TOWN_WALL_THICKNESS), Vector2(gate_half + front_length * 0.5, z))
    _add_town_wall(root, center, "TownWallBack", Vector3(x * 2.0, TOWN_WALL_HEIGHT, TOWN_WALL_THICKNESS), Vector2(0, -z))
    _add_town_wall(root, center, "TownWallLeft", Vector3(TOWN_WALL_THICKNESS, TOWN_WALL_HEIGHT, z * 2.0), Vector2(-x, 0))
    _add_town_wall(root, center, "TownWallRight", Vector3(TOWN_WALL_THICKNESS, TOWN_WALL_HEIGHT, z * 2.0), Vector2(x, 0))

    for tower in [Vector2(-x,-z), Vector2(x,-z), Vector2(-x,z), Vector2(x,z), Vector2(-gate_half-3.2,z), Vector2(gate_half+3.2,z)]:
        _add_static_box_local(root, center, "WallTower", Vector3(5.5, 8.2, 5.5), tower, 4.1, stone_material)

    _add_static_box_local(root, center, "TownGateLintel", Vector3(gate_half * 2.0, 1.1, 2.5), Vector2(0, z), TOWN_GATE_CLEAR_HEIGHT + 0.55, stone_material)
    _add_open_gate_leaf(root, center, "GateLeafLeft", Vector2(-gate_half, z - 1.7), -1.0)
    _add_open_gate_leaf(root, center, "GateLeafRight", Vector2(gate_half, z - 1.7), 1.0)

    var passage := Marker3D.new()
    passage.name = "TownGatePassage"
    passage.position = _local_position_on_terrain(root, center, Vector2(0, z), 0.1)
    passage.set_meta("half_width", gate_half)
    passage.set_meta("clear_height", TOWN_GATE_CLEAR_HEIGHT)
    root.add_child(passage)
    materialized_gate_passages += 1

func _populate_village(root: Node3D, center: Vector2, id: String) -> void:
    var palette_offset := 0 if id == "border_village_01" else 2
    _add_settlement_npc(root, center, "Житель", "resident", palette_offset + 0, Vector2(-2,-30), [Vector3(-2,0,-30), Vector3(-2,0,24), Vector3(2,0,34)])
    _add_settlement_npc(root, center, "Жительница", "resident", palette_offset + 1, Vector2(2,26), [Vector3(2,0,26), Vector3(2,0,-22), Vector3(-2,0,-30)])
    _add_settlement_npc(root, center, "Торговец", "trader", palette_offset + 2, Vector2(-14,-8), [Vector3(-14,0,-8), Vector3(14,0,-8), Vector3(14,0,10), Vector3(-14,0,10)])
    _add_settlement_npc(root, center, "Ремесленник", "craftsman", palette_offset + 3, Vector2(-18,15), [Vector3(-18,0,15), Vector3(-10,0,4), Vector3(-18,0,-7)])
    _add_settlement_npc(root, center, "Страж", "watch", palette_offset + 4, Vector2(-3,55), [Vector3(-3,0,55), Vector3(3,0,62), Vector3(3,0,54)])

func _populate_town(root: Node3D, center: Vector2) -> void:
    _add_settlement_npc(root, center, "Горожанин", "resident", 0, Vector2(-2,-78), [Vector3(-2,0,-78), Vector3(-2,0,76)])
    _add_settlement_npc(root, center, "Горожанка", "resident", 1, Vector2(2,70), [Vector3(2,0,70), Vector3(2,0,-76)])
    _add_settlement_npc(root, center, "Торговец", "trader", 2, Vector2(-58,-4), [Vector3(-58,0,-4), Vector3(58,0,-4)])
    _add_settlement_npc(root, center, "Торговка", "trader", 3, Vector2(52,0), [Vector3(52,0,0), Vector3(-52,0,0)])
    _add_settlement_npc(root, center, "Ремесленник", "craftsman", 4, Vector2(-34,30), [Vector3(-34,0,30), Vector3(34,0,30)])
    _add_settlement_npc(root, center, "Ремесленница", "craftsman", 0, Vector2(30,38), [Vector3(30,0,38), Vector3(-30,0,38)])
    _add_settlement_npc(root, center, "Страж ворот", "watch", 2, Vector2(-4,96), [Vector3(-4,0,96), Vector3(-4,0,108)])
    _add_settlement_npc(root, center, "Страж ворот", "watch", 3, Vector2(4,108), [Vector3(4,0,108), Vector3(4,0,96)])
    _add_settlement_npc(root, center, "Патрульный", "watch", 4, Vector2(-60,92), [Vector3(-60,0,92), Vector3(60,0,92)])
    _add_settlement_npc(root, center, "Патрульный", "watch", 1, Vector2(60,-92), [Vector3(60,0,-92), Vector3(-60,0,-92)])

func _get_settlement_npc_script() -> Script:
    if _settlement_npc_script == null:
        _settlement_npc_script = load(SETTLEMENT_NPC_PATH) as Script
        if _settlement_npc_script == null:
            push_error("WorldSettlements: failed to load settlement NPC script")
    return _settlement_npc_script

func _get_enterable_building_script() -> Script:
    if _enterable_building_script == null:
        _enterable_building_script = load(ENTERABLE_BUILDING_PATH) as Script
        if _enterable_building_script == null:
            push_error("WorldSettlements: failed to load enterable building script")
    return _enterable_building_script

func _add_settlement_npc(root: Node3D, center: Vector2, display_name: String, role: String, palette: int, local_start: Vector2, route: Array) -> Node3D:
    var npc_script := _get_settlement_npc_script()
    if npc_script == null:
        return null
    var instance := npc_script.new()
    if not instance is Node3D:
        push_error("WorldSettlements: settlement NPC script did not create a Node3D")
        if instance != null:
            instance.free()
        return null
    var npc := instance as Node3D
    npc.name = "SettlementNPC_%02d" % materialized_npcs
    instance.call("configure", display_name, role, palette, route)
    npc.position = _local_position_on_terrain(root, center, local_start, 0.08)
    root.add_child(npc)
    materialized_npcs += 1
    return npc

func _add_town_wall(root: Node3D, center: Vector2, node_name: String, size: Vector3, local_pos: Vector2) -> void:
    _add_static_box_local(root, center, node_name, size, local_pos, size.y * 0.5, stone_material)
    materialized_wall_segments += 1

func _add_open_gate_leaf(root: Node3D, center: Vector2, node_name: String, local_pos: Vector2, side_sign: float) -> void:
    var body := _add_static_box_local(root, center, node_name, Vector3(TOWN_GATE_HALF_WIDTH - 0.55, 3.4, 0.32), local_pos, 1.7, timber_material)
    body.rotation.y = side_sign * deg_to_rad(68.0)

func _add_enterable_building(root: Node3D, center: Vector2, local_pos: Vector2, size: Vector3, local_yaw: float, index: int, label: String) -> Node3D:
    var building_script := _get_enterable_building_script()
    if building_script == null:
        return null
    var instance := building_script.new()
    if not instance is Node3D:
        push_error("WorldSettlements: enterable building script did not create a Node3D")
        if instance != null:
            instance.free()
        return null
    var building := instance as Node3D
    building.name = "Enterable_%02d" % index
    instance.call("configure", size, index % 4, label)
    building.position = _local_position_on_terrain(root, center, local_pos, 0.02)
    building.rotation.y = local_yaw
    root.add_child(building)
    materialized_buildings += 1
    return building

func _add_well(root: Node3D, center: Vector2, local_pos: Vector2) -> void:
    var base := StaticBody3D.new()
    base.name = "PhysicalWell"
    base.position = _local_position_on_terrain(root, center, local_pos, 0.55)
    root.add_child(base)
    var mesh_node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 1.35
    mesh.bottom_radius = 1.45
    mesh.height = 1.1
    mesh.radial_segments = 16
    mesh.material = stone_material
    mesh_node.mesh = mesh
    base.add_child(mesh_node)
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 1.45
    shape.height = 1.1
    collision.shape = shape
    base.add_child(collision)
    var water := MeshInstance3D.new()
    water.name = "WellWater"
    var water_mesh := CylinderMesh.new()
    water_mesh.top_radius = 0.95
    water_mesh.bottom_radius = 0.95
    water_mesh.height = 0.05
    water_mesh.radial_segments = 16
    water_mesh.material = water_material
    water.mesh = water_mesh
    water.position = Vector3(0, 0.25, 0)
    base.add_child(water)

func _add_crate_stack(root: Node3D, center: Vector2, local_pos: Vector2) -> void:
    for i in range(3):
        var offset := local_pos + Vector2(float(i % 2) * 1.15, float(i / 2) * 1.05)
        _add_static_box_local(root, center, "SupplyCrate", Vector3(1.0, 1.0, 1.0), offset, 0.5 + float(i / 2), timber_material)

func _add_surface(root: Node3D, node_name: String, size: Vector2, local_pos: Vector2, lift: float, material: Material) -> void:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = Vector3(size.x, 0.045, size.y)
    mesh.material = material
    mesh_node.mesh = mesh
    mesh_node.position = _local_position_on_terrain(root, Vector2(root.global_position.x, root.global_position.z), local_pos, lift)
    mesh_node.visibility_range_end = 780.0
    root.add_child(mesh_node)

func _add_static_box_local(root: Node3D, center: Vector2, node_name: String, size: Vector3, local_pos: Vector2, height_center: float, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = _local_position_on_terrain(root, center, local_pos, height_center)
    body.collision_layer = 1
    body.collision_mask = 1
    root.add_child(body)
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

func _local_position_on_terrain(root: Node3D, center: Vector2, local_pos: Vector2, lift: float) -> Vector3:
    var world_offset3 := Basis(Vector3.UP, root.rotation.y) * Vector3(local_pos.x, 0.0, local_pos.y)
    var world_pos := center + Vector2(world_offset3.x, world_offset3.z)
    var world_y := WorldData.elevation_at(world_pos) + lift
    return Vector3(local_pos.x, world_y - root.global_position.y, local_pos.y)

func _road_facing_yaw(center: Vector2) -> float:
    var closest_point := center + Vector2(0, 100)
    var closest_distance := INF
    for road in GEOGRAPHY.road_catalog():
        var points: Array = road.get("points", [])
        for point in points:
            var p: Vector2 = point
            if p == center:
                continue
            var distance := p.distance_to(center)
            if distance < closest_distance:
                closest_distance = distance
                closest_point = p
    var toward_road := (closest_point - center).normalized()
    if toward_road.length_squared() < 0.1:
        toward_road = Vector2(0, 1)
    return atan2(toward_road.x, toward_road.y)

func _prepare_materials() -> void:
    earth_material = _material(Color(0.34, 0.255, 0.15, 1.0), 0.99)
    path_material = _material(Color(0.27, 0.205, 0.13, 1.0), 0.995)
    stone_material = _material(Color(0.36, 0.37, 0.35, 1.0), 0.97)
    timber_material = _material(Color(0.22, 0.115, 0.05, 1.0), 0.96)
    water_material = _material(Color(0.20, 0.46, 0.56, 0.82), 0.22)
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
