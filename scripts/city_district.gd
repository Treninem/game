extends Node3D

const CITY_NPC := preload("res://scripts/city_npc.gd")

var materials: Dictionary = {}
var player: Node3D

func _ready() -> void:
    _prepare_materials()
    _build_surface()
    _build_south_gate()
    _build_main_road_and_plaza()
    _build_market()
    _build_forge()
    _build_tavern()
    _build_guardhouse()
    _build_houses()
    _build_fountain()
    _build_decor()
    _spawn_people()
    player = get_tree().get_first_node_in_group("player") as Node3D

func _process(_delta: float) -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
        return
    var inside_city := player.global_position.z < -14.0 and absf(player.global_position.x) < 47.0
    var location := "Люменград • Южный квартал" if inside_city else "Окраины Люменграда"
    if GameState.current_location != location:
        GameState.set_location(location)

func _prepare_materials() -> void:
    materials["grass"] = _mat(Color(0.17, 0.29, 0.18), 0.96)
    materials["road"] = _mat(Color(0.28, 0.26, 0.23), 0.94)
    materials["stone"] = _mat(Color(0.38, 0.40, 0.41), 0.90)
    materials["stone_dark"] = _mat(Color(0.25, 0.27, 0.29), 0.93)
    materials["plaster"] = _mat(Color(0.58, 0.52, 0.43), 0.88)
    materials["plaster_light"] = _mat(Color(0.70, 0.64, 0.53), 0.88)
    materials["wood"] = _mat(Color(0.27, 0.15, 0.085), 0.94)
    materials["wood_light"] = _mat(Color(0.43, 0.27, 0.14), 0.92)
    materials["roof"] = _mat(Color(0.20, 0.08, 0.07), 0.90)
    materials["roof_blue"] = _mat(Color(0.10, 0.18, 0.26), 0.88)
    materials["cloth_red"] = _mat(Color(0.52, 0.12, 0.12), 0.82)
    materials["cloth_blue"] = _mat(Color(0.09, 0.27, 0.42), 0.82)
    materials["cloth_gold"] = _mat(Color(0.68, 0.45, 0.12), 0.82)
    materials["metal"] = _mat(Color(0.30, 0.33, 0.35), 0.55, 0.45)
    materials["water"] = _mat(Color(0.12, 0.42, 0.58), 0.24)
    materials["leaf"] = _mat(Color(0.12, 0.34, 0.16), 0.96)
    materials["lamp"] = _emissive_mat(Color(1.0, 0.62, 0.22), 2.0)

func _build_surface() -> void:
    _mesh_box("GrassSurface", Vector3(118, 0.04, 118), Vector3(0, 0.015, 0), materials["grass"])
    _mesh_box("CityFloor", Vector3(94, 0.045, 49), Vector3(0, 0.04, -37.5), materials["grass"])

func _build_south_gate() -> void:
    var z := -14.0
    _static_box("WallLeft", Vector3(36, 5.8, 2.4), Vector3(-30, 2.9, z), materials["stone"])
    _static_box("WallRight", Vector3(36, 5.8, 2.4), Vector3(30, 2.9, z), materials["stone"])
    _tower("GateTowerL", Vector3(-9.0, 0, z), 5.6)
    _tower("GateTowerR", Vector3(9.0, 0, z), 5.6)
    _static_box("GateLintel", Vector3(12.4, 2.0, 2.6), Vector3(0, 7.2, z), materials["stone_dark"])
    _static_box("GateDoorL", Vector3(3.6, 6.0, 0.35), Vector3(-1.9, 3.0, z + 0.9), materials["wood"])
    _static_box("GateDoorR", Vector3(3.6, 6.0, 0.35), Vector3(1.9, 3.0, z + 0.9), materials["wood"])
    _mesh_box("GateMetalBandL", Vector3(3.8, 0.22, 0.08), Vector3(-1.9, 3.2, z + 0.69), materials["metal"])
    _mesh_box("GateMetalBandR", Vector3(3.8, 0.22, 0.08), Vector3(1.9, 3.2, z + 0.69), materials["metal"])
    _static_box("WestWall", Vector3(2.2, 5.4, 44), Vector3(-47, 2.7, -36), materials["stone"])
    _static_box("EastWall", Vector3(2.2, 5.4, 44), Vector3(47, 2.7, -36), materials["stone"])
    var title := Label3D.new()
    title.name = "GateTitle"
    title.text = "ЛЮМЕНГРАД  •  ЮЖНЫЕ ВОРОТА"
    title.position = Vector3(0, 9.1, z + 0.2)
    title.font_size = 34
    title.outline_size = 8
    add_child(title)

func _tower(node_name: String, pos: Vector3, half_size: float) -> void:
    _static_box(node_name, Vector3(6.4, 8.8, 6.4), pos + Vector3(0, 4.4, 0), materials["stone_dark"])
    _mesh_box(node_name + "Top", Vector3(7.2, 0.6, 7.2), pos + Vector3(0, 9.0, 0), materials["stone"])
    for offset in [Vector3(-2.8, 9.8, -2.8), Vector3(2.8, 9.8, -2.8), Vector3(-2.8, 9.8, 2.8), Vector3(2.8, 9.8, 2.8)]:
        _mesh_box(node_name + "Merlon", Vector3(1.1, 1.5, 1.1), pos + offset, materials["stone"])

func _build_main_road_and_plaza() -> void:
    _mesh_box("SouthRoad", Vector3(8.0, 0.06, 45.0), Vector3(0, 0.075, -35.0), materials["road"])
    _mesh_box("Plaza", Vector3(31.0, 0.07, 21.0), Vector3(0, 0.08, -36.0), materials["road"])
    _mesh_box("WestLane", Vector3(31.0, 0.055, 5.0), Vector3(-21.0, 0.075, -35.0), materials["road"])
    _mesh_box("EastLane", Vector3(31.0, 0.055, 5.0), Vector3(21.0, 0.075, -35.0), materials["road"])

func _build_market() -> void:
    for i in range(5):
        var x := -14.0 - float(i % 2) * 7.0
        var z := -27.0 - float(i / 2) * 7.0
        var cloth := materials["cloth_red"] if i % 3 == 0 else (materials["cloth_blue"] if i % 3 == 1 else materials["cloth_gold"])
        _market_stall("Stall%d" % i, Vector3(x, 0, z), cloth)

func _market_stall(node_name: String, pos: Vector3, cloth: StandardMaterial3D) -> void:
    _mesh_box(node_name + "Counter", Vector3(4.2, 0.25, 2.0), pos + Vector3(0, 1.15, 0), materials["wood_light"])
    for x in [-1.7, 1.7]:
        _mesh_box(node_name + "Post", Vector3(0.18, 3.0, 0.18), pos + Vector3(x, 1.5, 0), materials["wood"])
    _mesh_box(node_name + "Canopy", Vector3(4.8, 0.16, 2.8), pos + Vector3(0, 3.0, 0), cloth)
    for j in range(4):
        _mesh_box(node_name + "Goods", Vector3(0.55, 0.35, 0.55), pos + Vector3(-1.1 + j * 0.72, 1.48, -0.1), materials["plaster_light"])

func _build_forge() -> void:
    var p := Vector3(24, 0, -29)
    _house("Forge", p, Vector3(12, 5.8, 9), materials["stone_dark"], materials["roof"])
    _static_box("ForgeChimney", Vector3(1.8, 7.0, 1.8), p + Vector3(3.5, 5.8, 1.8), materials["stone"])
    _mesh_box("ForgeAnvilBase", Vector3(2.0, 0.8, 1.1), p + Vector3(-5.5, 0.4, 3.2), materials["stone_dark"])
    _mesh_box("ForgeAnvil", Vector3(1.9, 0.5, 0.7), p + Vector3(-5.5, 1.05, 3.2), materials["metal"])
    var sign := Label3D.new()
    sign.text = "КУЗНИЦА РАДАНА"
    sign.position = p + Vector3(0, 3.5, 4.75)
    sign.font_size = 28
    sign.outline_size = 7
    add_child(sign)

func _build_tavern() -> void:
    var p := Vector3(20, 0, -49)
    _house("Tavern", p, Vector3(15, 6.8, 10), materials["plaster_light"], materials["roof_blue"])
    _mesh_box("TavernAwning", Vector3(7.0, 0.18, 2.5), p + Vector3(0, 3.2, 5.3), materials["cloth_blue"])
    var sign := Label3D.new()
    sign.text = "ТАВЕРНА «СИНИЙ ФОНАРЬ»"
    sign.position = p + Vector3(0, 4.2, 5.25)
    sign.font_size = 26
    sign.outline_size = 7
    add_child(sign)

func _build_guardhouse() -> void:
    var p := Vector3(-22, 0, -20)
    _house("Guardhouse", p, Vector3(12, 5.4, 8), materials["stone"], materials["roof_blue"])
    _mesh_box("GuardBanner", Vector3(0.18, 3.2, 1.3), p + Vector3(6.15, 4.0, 0), materials["cloth_blue"])

func _build_houses() -> void:
    var houses := [
        [Vector3(-34, 0, -31), Vector3(10, 5.2, 8), "light"],
        [Vector3(-34, 0, -44), Vector3(11, 6.0, 9), "dark"],
        [Vector3(-31, 0, -55), Vector3(12, 5.6, 8), "light"],
        [Vector3(34, 0, -19), Vector3(10, 5.0, 8), "dark"],
        [Vector3(35, 0, -41), Vector3(11, 5.7, 9), "light"],
        [Vector3(34, 0, -55), Vector3(12, 6.2, 8), "dark"]
    ]
    for i in range(houses.size()):
        var h: Array = houses[i]
        var wall_mat := materials["plaster_light"] if h[2] == "light" else materials["plaster"]
        var roof_mat := materials["roof"] if i % 2 == 0 else materials["roof_blue"]
        _house("House%d" % i, h[0], h[1], wall_mat, roof_mat)

func _house(node_name: String, pos: Vector3, size: Vector3, wall_mat: StandardMaterial3D, roof_mat: StandardMaterial3D) -> void:
    _static_box(node_name, size, pos + Vector3(0, size.y * 0.5, 0), wall_mat)
    _mesh_box(node_name + "Roof", Vector3(size.x + 1.0, 1.0, size.z + 1.0), pos + Vector3(0, size.y + 0.45, 0), roof_mat)
    _mesh_box(node_name + "Door", Vector3(1.5, 2.6, 0.18), pos + Vector3(0, 1.3, size.z * 0.51), materials["wood"])
    for x in [-size.x * 0.28, size.x * 0.28]:
        _mesh_box(node_name + "Window", Vector3(1.2, 1.3, 0.12), pos + Vector3(x, size.y * 0.58, size.z * 0.515), materials["water"])
    _mesh_box(node_name + "BeamTop", Vector3(size.x + 0.2, 0.18, 0.18), pos + Vector3(0, size.y - 0.6, size.z * 0.525), materials["wood"])

func _build_fountain() -> void:
    var p := Vector3(0, 0, -36)
    var basin := CylinderMesh.new()
    basin.top_radius = 3.1
    basin.bottom_radius = 3.3
    basin.height = 0.55
    basin.radial_segments = 24
    var basin_node := MeshInstance3D.new()
    basin_node.name = "FountainBasin"
    basin_node.mesh = basin
    basin_node.position = p + Vector3(0, 0.3, 0)
    basin_node.material_override = materials["stone"]
    add_child(basin_node)
    var water := CylinderMesh.new()
    water.top_radius = 2.65
    water.bottom_radius = 2.65
    water.height = 0.08
    water.radial_segments = 24
    var water_node := MeshInstance3D.new()
    water_node.name = "FountainWater"
    water_node.mesh = water
    water_node.position = p + Vector3(0, 0.57, 0)
    water_node.material_override = materials["water"]
    add_child(water_node)
    _mesh_box("FountainColumn", Vector3(0.7, 3.2, 0.7), p + Vector3(0, 2.0, 0), materials["stone_dark"])

func _build_decor() -> void:
    var lamp_positions := [
        Vector3(-5, 0, -20), Vector3(5, 0, -20), Vector3(-5, 0, -30), Vector3(5, 0, -30),
        Vector3(-13, 0, -45), Vector3(13, 0, -45), Vector3(-6, 0, -54), Vector3(7, 0, -54)
    ]
    for i in range(lamp_positions.size()):
        _lamp("Lamp%d" % i, lamp_positions[i])
    var tree_positions := [Vector3(-40, 0, -23), Vector3(-41, 0, -51), Vector3(41, 0, -28), Vector3(42, 0, -49), Vector3(-13, 0, -56), Vector3(10, 0, -57)]
    for i in range(tree_positions.size()):
        _city_tree("CityTree%d" % i, tree_positions[i])
    for i in range(6):
        _mesh_box("Bench%d" % i, Vector3(2.8, 0.22, 0.65), Vector3(-9.0 + i * 3.6, 0.65, -40.5), materials["wood_light"])
        _mesh_box("BenchLeg%dA" % i, Vector3(0.18, 0.65, 0.5), Vector3(-9.8 + i * 3.6, 0.33, -40.5), materials["metal"])
        _mesh_box("BenchLeg%dB" % i, Vector3(0.18, 0.65, 0.5), Vector3(-8.2 + i * 3.6, 0.33, -40.5), materials["metal"])

func _lamp(node_name: String, pos: Vector3) -> void:
    _mesh_box(node_name + "Post", Vector3(0.16, 3.6, 0.16), pos + Vector3(0, 1.8, 0), materials["metal"])
    _mesh_box(node_name + "Glow", Vector3(0.42, 0.62, 0.42), pos + Vector3(0, 3.45, 0), materials["lamp"])
    var light := OmniLight3D.new()
    light.name = node_name + "Light"
    light.position = pos + Vector3(0, 3.45, 0)
    light.light_color = Color(1.0, 0.61, 0.30)
    light.light_energy = 0.9
    light.omni_range = 7.0
    light.shadow_enabled = false
    add_child(light)

func _city_tree(node_name: String, pos: Vector3) -> void:
    var trunk := CylinderMesh.new()
    trunk.top_radius = 0.28
    trunk.bottom_radius = 0.38
    trunk.height = 3.8
    trunk.radial_segments = 8
    var trunk_node := MeshInstance3D.new()
    trunk_node.name = node_name + "Trunk"
    trunk_node.mesh = trunk
    trunk_node.position = pos + Vector3(0, 1.9, 0)
    trunk_node.material_override = materials["wood"]
    add_child(trunk_node)
    var crown := SphereMesh.new()
    crown.radius = 1.65
    crown.height = 3.0
    crown.radial_segments = 10
    crown.rings = 6
    var crown_node := MeshInstance3D.new()
    crown_node.name = node_name + "Crown"
    crown_node.mesh = crown
    crown_node.position = pos + Vector3(0, 4.6, 0)
    crown_node.material_override = materials["leaf"]
    add_child(crown_node)

func _spawn_people() -> void:
    _spawn_npc("Радан", "blacksmith", Vector3(18.5, 0, -27.5), Vector3(18.5, 0, -27.5), Vector3(18, 0, -45), Vector3(28, 0, -51), 1)
    _spawn_npc("Лея", "merchant", Vector3(-13, 0, -31), Vector3(-13, 0, -31), Vector3(-8, 0, -39), Vector3(-32, 0, -52), 3)
    _spawn_npc("Торен", "guard", Vector3(-2.5, 0, -16.5), Vector3(-2.5, 0, -16.5), Vector3(-18, 0, -20), Vector3(-23, 0, -20), 4)
    _spawn_npc("Орен", "innkeeper", Vector3(20, 0, -44), Vector3(20, 0, -44), Vector3(20, 0, -44), Vector3(26, 0, -51), 0)
    _spawn_npc("Мара", "artisan", Vector3(-27, 0, -43), Vector3(-27, 0, -43), Vector3(-8, 0, -36), Vector3(-35, 0, -45), 2)
    _spawn_npc("Севин", "citizen", Vector3(7, 0, -31), Vector3(9, 0, -30), Vector3(4, 0, -41), Vector3(34, 0, -55), 0)

func _spawn_npc(npc_name: String, npc_role: String, start: Vector3, work: Vector3, evening: Vector3, home: Vector3, palette: int) -> void:
    var npc = CITY_NPC.new()
    npc.name = npc_name
    npc.display_name = npc_name
    npc.role = npc_role
    npc.work_position = work
    npc.evening_position = evening
    npc.home_position = home
    npc.palette_index = palette
    add_child(npc)
    npc.global_position = start

func _mat(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = metallic
    return mat

func _emissive_mat(color: Color, energy: float) -> StandardMaterial3D:
    var mat := _mat(color, 0.45)
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = energy
    return mat

func _mesh_box(node_name: String, size: Vector3, pos: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    add_child(node)
    return node

func _static_box(node_name: String, size: Vector3, pos: Vector3, material: StandardMaterial3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    add_child(body)
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    body.add_child(visual)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body
