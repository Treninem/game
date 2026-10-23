extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")
const FACADES := preload("res://scripts/modular_city_facades.gd")
const MARKET_COURT := preload("res://scripts/capital_market_court.gd")
const SQUARE_LIFE := preload("res://scripts/capital_square_life.gd")
const MARKET_STALL_SCENE: PackedScene = preload("res://assets/production/medieval/quaternius_market/Stall_Empty.gltf")
const RESIDENT := preload("res://scripts/settlement_npc.gd")
const LANDMARKS := preload("res://scripts/capital_landmarks.gd")
const WINDOW_SCENE := preload("res://assets/production/medieval/quaternius_city_core/Wall_Plaster_Window_Wide_Round.gltf")
const DOOR_SCENE := preload("res://assets/production/medieval/building_shell/Door_1_Flat.gltf")
const PLASTER := preload("res://assets/production/medieval/quaternius_city_core/T_Plaster_BaseColor.png")
const PLASTER_NORMAL := preload("res://assets/production/medieval/quaternius_city_core/T_Plaster_Normal.png")

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
var residents_elapsed := 0.0

var ground_material: StandardMaterial3D
var road_material: StandardMaterial3D
var plaza_material: StandardMaterial3D
var wall_materials: Array[StandardMaterial3D] = []
var roof_fallback_material: StandardMaterial3D
var trim_material: StandardMaterial3D

func _ready() -> void:
    process_priority = 40
    _prepare_materials()
    SettingsManager.settings_changed.connect(_apply_facade_quality)
    var landmarks := LANDMARKS.new()
    landmarks.name = "CapitalLandmarks"
    add_child(landmarks)
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
    residents_elapsed += delta
    if residents_elapsed >= 0.5:
        residents_elapsed = 0.0
        _refresh_residents()

func _refresh_residents() -> void:
    var player_xz := Vector2(player.global_position.x, player.global_position.z)
    for cell: Vector2i in loaded_cells:
        var root := loaded_cells[cell] as Node3D
        var residents := root.get_node_or_null("Residents")
        var distance := _cell_center_2d(cell).distance_to(player_xz)
        if distance > 240.0:
            if residents != null:
                residents.free()
            continue
        if distance > 190.0 or residents != null:
            continue
        residents = Node3D.new()
        residents.name = "Residents"
        root.add_child(residents)
        var center := _cell_center_2d(cell)
        var district := CAPITAL.district_at(center)
        for index in range(2):
            var role := "trader" if String(district.get("id", "")) == "market" else "craftsman" if index == 0 else "traveler" if absi(cell.x + cell.y) % 3 == 0 else "resident"
            var npc := RESIDENT.new()
            npc.name = "CityResident_%d" % index
            npc.add_to_group("capital_resident")
            npc.autonomous = true
            npc.set_meta("citizen_id", "capital:%d:%d:%d" % [cell.x, cell.y, index])
            var route: Array = []
            for point in [Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)]:
                var xz: Vector2 = center + point
                route.append(Vector3(point.x, WorldData.elevation_at(xz) + 0.08, point.y))
            var names := ["Марек", "Лада", "Борис", "Ирина", "Лев", "Марта", "Роман", "Вера"]
            npc.configure(names[absi(cell.x * 3 + cell.y * 5 + index) % names.size()], role, absi(cell.x + cell.y + index) % 5, route)
            npc.position = route[index * 2]
            npc.route_index = (index * 2 + 1) % route.size()
            residents.add_child(npc)

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
    var facades := FACADES.new()
    root.set_meta("facades", facades)

    var base_y := WorldData.elevation_at(center)
    _add_mesh_box("DistrictPaving", Vector3(CELL_SIZE - 2.0, 0.08, CELL_SIZE - 2.0), Vector3(0.0, base_y - 0.025, 0.0), ground_material, root)
    _add_mesh_box("RoadNS", Vector3(14.0, 0.11, CELL_SIZE), Vector3(0.0, base_y - 0.035, 0.0), road_material, root)
    _add_mesh_box("RoadEW", Vector3(CELL_SIZE, 0.11, 14.0), Vector3(0.0, base_y - 0.033, 0.0), road_material, root)

    var district: Dictionary = CAPITAL.district_at(center)
    var district_id := String(district.get("id", "city"))
    if district_id == "central" and cell == Vector2i.ZERO:
        _build_spawn_square(root, center)
        facades.finish(root)
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = absi(CITY_SEED ^ (cell.x * 73856093) ^ (cell.y * 19349663))
    var lots: Array[Vector2] = []
    for offset in [Vector2(28, 28), Vector2(52, 28), Vector2(28, 52), Vector2(52, 52)]:
        for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
            lots.append(offset * direction)
    var house_count := 8
    if district_id in ["market", "crafts", "old_town", "residential"]:
        house_count = 12
    elif district_id in ["arena", "hippodrome", "farms", "canals"]:
        house_count = 2

    for i in range(mini(house_count, lots.size())):
        var lot := lots[i]
        lot.x += rng.randf_range(-2.0, 2.0)
        lot.y += rng.randf_range(-2.0, 2.0)
        var world_lot := center + lot
        if CAPITAL.in_gate_approach(world_lot, 15.0):
            continue
        # Reserve courtyards and approach space for the canonical civic buildings.
        if not CAPITAL.protected_infrastructure_near(world_lot, 58.0).is_empty():
            continue
        var y := WorldData.elevation_at(world_lot)
        var width := rng.randf_range(12.0, 18.0)
        var depth := rng.randf_range(11.0, 17.0)
        var height := rng.randf_range(6.5, 10.5)
        var yaw := (PI if lot.y > 0.0 else 0.0)
        if absf(lot.x) < absf(lot.y):
            yaw = -PI * 0.5 if lot.x > 0.0 else PI * 0.5
        _build_house(root, Vector3(lot.x, y, lot.y), Vector3(width, height, depth), i, yaw)

    if district_id == "market" and cell.x % 2 == 0:
        _spawn_real_market_stall(root, Vector3(18.0, base_y + 0.12, -22.0), float(cell.y) * 0.31)
    facades.finish(root)

func _build_spawn_square(root: Node3D, center: Vector2) -> void:
    var base_y := WorldData.elevation_at(center)
    _add_mesh_box("CentralPlaza", Vector3(118.0, 0.14, 118.0), Vector3(0.0, base_y - 0.045, 0.0), plaza_material, root)
    var square_life := SQUARE_LIFE.new()
    square_life.name = "CapitalSquareLife"
    root.add_child(square_life)

    var hall_world := center + Vector2(0.0, -58.0)
    var hall_y := WorldData.elevation_at(hall_world)
    _build_house(root, Vector3(0.0, hall_y, -58.0), Vector3(30.0, 14.0, 20.0), 0)

    var right_world := center + Vector2(45.0, -30.0)
    # The left square home is physically built by CapitalSquareLife, including
    # its door and interior. Do not seal it again with the old facade collider.
    _build_house(root, Vector3(45.0, WorldData.elevation_at(right_world), -30.0), Vector3(16.0, 8.5, 14.0), 2)

    _build_square_edges(root,center)
    for side:float in [-1.0,1.0]:
        for z:float in [18.0,34.0,50.0]:
            var canopy:=square_life._place(MARKET_STALL_SCENE,"ConceptMarketCanopy",Vector3(side*11,0,z),2.65,-side*PI*.5,true)
            MARKET_COURT.dress_canopy(canopy,int(z/16.0))
    root.set_meta("concept_market_canopies",6)
    MARKET_COURT.build(square_life)

func _build_square_edges(root:Node3D,center:Vector2) -> void:
    # Continuous street walls enclose the square. Preserve the 14m cardinal
    # streets, working home/workplace/door anchors and the existing civic hall.
    var index := 0
    var lots:Array[Vector3]=[]
    for side:float in [-1.0,1.0]:
        for z:float in [14.0,25.0,36.0,47.0,58.0]:lots.append(Vector3(side*25, -side*PI*.5, z))
        for z:float in [-57.0,-36.0,-15.0]:lots.append(Vector3(side*66, -side*PI*.5, z))
    for x:float in [-31.0,31.0]:lots.append(Vector3(x,0,-61))
    for x:float in [-44.0,-20.0,20.0,44.0]:lots.append(Vector3(x,PI,73))
    for lot in lots:
        var point:=Vector2(lot.x,lot.z)
        var height:=6.24 if index%3!=0 else 9.36
        _build_house(root,Vector3(point.x,WorldData.elevation_at(center+point),point.y),Vector3(9.5,height,12),index,lot.y,"ConceptTownhouse_%02d"%index)
        index += 1
    root.set_meta("concept_edge_houses",index)

func _build_house(parent: Node3D, base_pos: Vector3, size: Vector3, variant: int, yaw: float = 0.0, label: String = "") -> void:
    var stories := clampi(roundi(size.y / 3.12), 1, 4)
    size.y = float(stories) * 3.12
    var body := StaticBody3D.new()
    body.name = label if not label.is_empty() else "House_%d" % variant
    body.add_to_group("map_building")
    body.set_meta("map_footprint", Vector2(size.x, size.z))
    body.position = Vector3(base_pos.x, base_pos.y + size.y * 0.5, base_pos.z)
    body.rotation.y = yaw
    parent.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    if label.begins_with("ConceptTownhouse"):
        var roof_collision:=CollisionShape3D.new()
        roof_collision.name="AuthoredRoofSupport"
        var roof_shape:=ConvexPolygonShape3D.new()
        var points:=PackedVector3Array()
        for z:float in [-size.z*.545,size.z*.545]:
            points.append(Vector3(-size.x*.55,size.y*.5-.38,z))
            points.append(Vector3(size.x*.55,size.y*.5-.38,z))
            points.append(Vector3(0,size.y*.5+3.8,z))
        roof_shape.points=points
        roof_collision.shape=roof_shape
        body.add_child(roof_collision)
        var ridge_collision:=CollisionShape3D.new()
        ridge_collision.name="AuthoredRidgeSupport"
        var ridge_shape:=ConvexPolygonShape3D.new()
        var ridge_points:=PackedVector3Array()
        for z:float in [-size.z*.545,size.z*.545]:
            for k in range(7):
                var angle:=PI*k/6.0
                ridge_points.append(Vector3(cos(angle)*.22*size.x/8.0,size.y*.5+3.6+sin(angle)*.32,z))
        ridge_shape.points=ridge_points
        ridge_collision.shape=ridge_shape
        body.add_child(ridge_collision)

    var facades = parent.get_meta("facades")
    facades.add_house(base_pos, yaw, Vector2(size.x, size.z), stories, variant % 4 == 0, label.begins_with("ConceptTownhouse"))

func _limit_facade_range(node: Node) -> void:
    if node is GeometryInstance3D:
        node.visibility_range_end = 140.0
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for child in node.get_children():
        _limit_facade_range(child)

func _spawn_real_market_stall(parent: Node3D, pos: Vector3, yaw: float) -> void:
    var node := MARKET_STALL_SCENE.instantiate() as Node3D
    if node == null:
        return
    node.name = "RealMarketStall"
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
    for material in [ground_material, road_material, plaza_material]:
        material.albedo_texture = preload("res://assets/production/materials/ground/stone_paving.jpg")
        material.uv1_triplanar = true
        material.uv1_world_triplanar = true
        material.uv1_scale = Vector3.ONE * 0.30
        material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    ground_material.albedo_color = Color(0.64, 0.62, 0.58)
    road_material.albedo_color = Color(0.46, 0.44, 0.40)
    plaza_material.albedo_color = Color(0.67, 0.66, 0.63)
    wall_materials = [
        _material(Color(0.52, 0.43, 0.31), 0.92),
        _material(Color(0.63, 0.56, 0.43), 0.90),
        _material(Color(0.43, 0.34, 0.27), 0.95),
        _material(Color(0.70, 0.66, 0.55), 0.91)
    ]
    for material in wall_materials:
        material.albedo_texture = PLASTER
        material.normal_enabled = true
        material.normal_texture = PLASTER_NORMAL
        material.normal_scale = 0.65
        material.uv1_triplanar = true
        material.uv1_world_triplanar = true
        material.uv1_scale = Vector3.ONE * 0.35
        material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
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

func _apply_facade_quality() -> void:
    FACADES.apply_surface_quality(int(SettingsManager.get_value("graphics","quality_preset")))
