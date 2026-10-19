extends Node3D

const NPC := preload("res://scripts/settlement_npc.gd")
const PROP_ROOT := "res://assets/production/medieval/capital_square/"
const STALL := preload("res://assets/production/medieval/quaternius_market/Stall_Empty.gltf")
const SHOP_ID := "capital:square:provisions"
var lamps: Array[OmniLight3D] = []
var light_elapsed := 1.0
var indoor_light: OmniLight3D

func _ready() -> void:
    var home := preload("res://scripts/enterable_building.gd").new()
    home.name = "SquareHome"
    home.configure(Vector3(12, 3.2, 10), 1, "Дом Марты и Марека")
    # A small physical threshold separates the floor from the plaza mesh;
    # coplanar surfaces flicker badly at the capital's large coordinates.
    home.position = Vector3(-45, _ground_y(Vector3(-45, 0, -30)) + 0.03 - home.floor_thickness, -30)
    home.add_to_group("map_building")
    home.set_meta("map_footprint", Vector2(12, 10))
    home.set_meta("household_owners", [SHOP_ID, "capital:square:fletcher"])
    add_child(home)
    home.front_door.persistence_key = "door:capital:square:home"
    home.front_door.set_open(bool(GameState.get_world_value(home.front_door.persistence_key, false)), true)
    home.floor_material.albedo_texture = preload("res://assets/production/medieval/building_shell/T_WoodTrim_BaseColor.png")
    home.floor_material.albedo_color = Color(0.65, 0.52, 0.38)
    home.floor_material.uv1_triplanar = true
    home.floor_material.uv1_world_triplanar = true
    home.floor_material.uv1_scale = Vector3.ONE * 0.6
    for material: StandardMaterial3D in home.wall_materials:
        material.albedo_texture = preload("res://assets/production/medieval/quaternius_city_core/T_Plaster_BaseColor.png")
        material.uv1_triplanar = true
        material.uv1_world_triplanar = true
        material.uv1_scale = Vector3.ONE * 0.35
    # A real wall lantern lights the occupied room, including the beds. The
    # exterior stall lights cannot reach it through the physical house walls.
    var indoor_lantern := _prop("Lantern_Wall", Vector3.ZERO, 0.42, 0, false)
    indoor_lantern.name = "HomeWallLantern"
    indoor_lantern.position = home.position + Vector3(0, 2.35, -4.64)
    indoor_light = OmniLight3D.new()
    indoor_light.name = "HomeLanternLight"
    indoor_light.position = home.position + Vector3(0, 2.5, -4.1)
    indoor_light.light_color = Color(1.0, 0.78, 0.53)
    indoor_light.light_energy = 2.5
    indoor_light.omni_range = 11.0
    _apply_indoor_quality()
    SettingsManager.settings_changed.connect(_apply_indoor_quality)
    add_child(indoor_light)
    for side: float in [-1.0, 1.0]:
        _prop("Bench", Vector3(side * 10, 0, 12), 0.47, PI)
        _prop("Bench", Vector3(side * 30, 0, -8), 0.47, side * PI * 0.5)
        _prop("Barrel", Vector3(side * 20, 0, -13), 1.0)
        _prop("Barrel_Apples", Vector3(side * 19, 0, -9), 0.9)
        _prop("Barrel_Apples", Vector3(side * 21, 0, -6), 0.75)
        var stall := _place(STALL, "SquareMarketStall", Vector3(side * 16, 0, -12), 2.65, 0, true)
        stall.add_to_group("capital_square_stall")
        # Mounted on the authored stall's front upright, not floating in space.
        var lantern := _prop("Lantern_Wall", Vector3.ZERO, 0.55, 0, false)
        lantern.position = Vector3(side * 16 - 1.1, _ground_y(Vector3(side * 16, 0, -12)) + 1.85, -10.95)
        var light := OmniLight3D.new()
        light.name = "SquareLanternLight"
        light.position = lantern.position + Vector3(0, 0.2, 0.15)
        light.light_color = Color(1.0, 0.67, 0.32)
        light.light_energy = 1.4
        light.omni_range = 11.0
        light.shadow_enabled = false
        add_child(light)
        lamps.append(light)
    _prop("Workbench", Vector3(-23, 0, -12), 0.95)
    _resident("Марта", "trader", "SquareTrader", SHOP_ID, Vector3(-16, 0, -8.5), Vector3(-16, 0, -12), 1)
    var artisan := _resident("Марек", "craftsman", "SquareArtisan", "capital:square:fletcher", Vector3(-23, 0, -10.3), Vector3(-23, 0, -12), 0)
    artisan.set_meta("work_shop_id", SHOP_ID)
    artisan.set_meta("work_recipe", "arrow")

func _process(delta: float) -> void:
    light_elapsed += delta
    if light_elapsed < 1.0:
        return
    light_elapsed = 0
    var hour := fmod(GameState.world_minutes / 60.0, 24.0)
    for light in lamps:
        light.visible = hour >= 17.5 or hour < 7.0

func _ground_y(point: Vector3) -> float:
    var world := to_global(point)
    return WorldData.elevation_at(Vector2(world.x, world.z)) + 0.025 - global_position.y

func _prop(kind: String, point: Vector3, height: float, yaw: float = 0.0, physical: bool = true) -> Node3D:
    return _place(load(PROP_ROOT + kind + ".gltf") as PackedScene, "Square" + kind, point, height, yaw, physical)

func _place(scene: PackedScene, node_name: String, point: Vector3, height: float, yaw: float, physical: bool) -> Node3D:
    var body: Node3D = StaticBody3D.new() if physical else Node3D.new()
    body.name = node_name
    body.add_to_group("capital_square_prop")
    body.position = Vector3(point.x, _ground_y(point), point.z)
    body.rotation.y = yaw
    add_child(body)
    var visual := scene.instantiate() as Node3D
    body.add_child(visual)
    var bounds := _bounds(visual, Transform3D.IDENTITY)
    assert(bounds.size.y > 0.001, "Selected square prop has no physical mesh height")
    var scale_factor := height / bounds.size.y
    visual.scale *= scale_factor
    var center := bounds.get_center()
    visual.position -= Vector3(center.x, bounds.position.y, center.z) * scale_factor
    body.set_meta("authored_height", height)
    if physical:
        body.add_to_group("map_fixture")
        body.set_meta("map_footprint", Vector2(bounds.size.x, bounds.size.z) * scale_factor)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = bounds.size * scale_factor
        collision.shape = shape
        collision.position.y = height * 0.5
        body.add_child(collision)
    return body

func _bounds(node: Node3D, inherited: Transform3D) -> AABB:
    var transform := inherited * node.transform
    var result := AABB()
    var found := false
    if node is MeshInstance3D:
        result = transform * (node as MeshInstance3D).get_aabb()
        found = true
    for child in node.get_children():
        if child is Node3D:
            var child_bounds := _bounds(child, transform)
            if child_bounds.size.length_squared() > 0.0:
                result = result.merge(child_bounds) if found else child_bounds
                found = true
    return result

func _resident(label: String, role: String, node_name: String, id: String, workplace: Vector3, facing: Vector3, palette: int) -> CharacterBody3D:
    var resident := NPC.new()
    resident.name = node_name
    resident.autonomous = true
    resident.set_meta("citizen_id", id)
    resident.set_meta("routine_places", {"work": workplace, "home": Vector3(-45 + (-1.4 if role == "trader" else 1.4), 0, -29), "meal": Vector3(-10, 0, 13.5), "social": Vector3(10, 0, 13.5)})
    resident.set_meta("home_building", "SquareHome")
    resident.set_meta("work_facing", facing)
    resident.set_meta("work_approach_path", [Vector3(-35, 0, -4), Vector3(workplace.x, 0, -4)])
    resident.configure(label, role, palette, [])
    resident.position = Vector3(workplace.x, _ground_y(workplace) + 0.08, workplace.z)
    add_child(resident)
    return resident

func _apply_indoor_quality() -> void:
    if is_instance_valid(indoor_light):
        indoor_light.shadow_enabled = bool(SettingsManager.quality_profile().get("shadows", false))
