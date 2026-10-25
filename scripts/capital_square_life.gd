extends Node3D

const MARKET_STRUCTURE := preload("res://scripts/market_structures.gd")
const NPC := preload("res://scripts/settlement_npc.gd")
const PROP_ROOT := "res://assets/production/medieval/capital_square/"
const STALL := preload("res://assets/production/medieval/quaternius_market/Stall_Empty.gltf")
const SHOP_ID := "capital:square:provisions"
const ARROW := preload("res://scripts/weapon_model_catalog.gd").ARROW
var lamps: Array[OmniLight3D] = []
var light_elapsed := 1.0
var indoor_light: OmniLight3D
var workpieces: Node3D
var working_artisan: CharacterBody3D

func _ready() -> void:
    var home := preload("res://scripts/enterable_building.gd").new()
    home.name = "SquareHome"
    home.configure(Vector3(12, 3.2, 10), 1, "Ð”Ð¾Ð¼ ÐœÐ°Ñ€Ñ‚Ñ‹ Ð¸ ÐœÐ°Ñ€ÐµÐºÐ°")
    # A small physical threshold separates the floor from the plaza mesh;
    # coplanar surfaces flicker badly at the capital's large coordinates.
    home.position = Vector3(-45, _ground_y(Vector3(-45, 0, -30)) + 0.03 - home.floor_thickness, -30)
    home.add_to_group("map_building")
    home.set_meta("map_footprint", Vector2(12, 10))
    home.set_meta("household_owners", [SHOP_ID, "capital:square:fletcher"])
    home.set_meta("external_interior_lantern", true)
    add_child(home)
    preload("res://scripts/cottage_exterior.gd").build(home)
    home.front_door.persistence_key = "door:capital:square:home"
    home.front_door.set_open(bool(GameState.get_world_value(home.front_door.persistence_key, false)), true)
    # Use the same measured-scale interior surfaces as other enterable homes.
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
    for side:float in [-1.0,1.0]:
        _prop("Bench",Vector3(side*10,0,15.8),.47,0)
        _place(preload("res://assets/production/interiors/quaternius_furniture/Table.fbx"),"PublicMealTable",Vector3(side*10,0,13.9),.72,0,true)
    var workbench := _prop("Workbench", Vector3(-23, 0, -12), 0.95)
    _resident("ÐœÐ°Ñ€Ñ‚Ð°", "trader", "SquareTrader", SHOP_ID, Vector3(-16, 0, -8.5), Vector3(-16, 0, -12), 1)
    # Stand just outside the measured bench footprint, within arm's reach.
    var work_depth: Vector2 = workbench.get_meta("map_footprint")
    var workplace := Vector3(-23, 0, -12 + work_depth.y * 0.5 + 0.42)
    var artisan := _resident("ÐœÐ°Ñ€ÐµÐº", "craftsman", "SquareArtisan", "capital:square:fletcher", workplace, Vector3(-23, 0, -12), 0)
    artisan.set_meta("work_shop_id", SHOP_ID)
    artisan.set_meta("work_recipe", "arrow")
    working_artisan = artisan
    _prepare_workpieces(workbench)

func _prepare_workpieces(bench: Node3D) -> void:
    workpieces = Node3D.new()
    workpieces.name = "ArrowWorkpieces"
    workpieces.visible = false
    bench.add_child(workpieces)
    var footprint: Vector2 = bench.get_meta("map_footprint")
    for index in range(int(InventorySystem.RECIPES.arrow.amount)):
        var arrow := Node3D.new()
        workpieces.add_child(arrow)
        arrow.add_child(ARROW.instantiate())
        arrow.scale = Vector3.ONE * 0.75
        arrow.rotation.x = -PI * 0.5
        var bounds := _bounds(arrow, Transform3D.IDENTITY)
        # Rest the actual feather/shaft geometry on the board, near the hands.
        arrow.position = Vector3((index-2)*0.035, float(bench.get_meta("authored_height"))-bounds.position.y+0.001, footprint.y*0.5-0.29)
        for mesh: MeshInstance3D in arrow.find_children("*", "MeshInstance3D", true, false):
            mesh.visibility_range_end = 45.0
            mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
    light_elapsed += delta
    if light_elapsed < 1.0:
        return
    light_elapsed = 0
    var hour := fmod(GameState.world_minutes / 60.0, 24.0)
    for light in lamps:
        light.visible = (hour >= 17.5 or hour < 7.0) and (not light.get_meta("medium_only",false) or int(SettingsManager.get_value("graphics","quality_preset"))>=1)
    if is_instance_valid(workpieces) and is_instance_valid(working_artisan):
        var stock: Dictionary = GameState.get_world_value("shop:"+SHOP_ID,{})
        var recipe: Dictionary = InventorySystem.RECIPES.arrow
        var supplied := true
        for item: String in recipe.requirements:
            supplied = supplied and int(stock.get(item,0)) >= int(recipe.requirements[item])
        workpieces.visible = supplied and working_artisan.get_meta("activity","idle")=="work"

func _ground_y(point: Vector3) -> float:
    var world := to_global(point)
    return WorldData.elevation_at(Vector2(world.x, world.z)) + 0.025 - global_position.y

func _prop(kind: String, point: Vector3, height: float, yaw: float = 0.0, physical: bool = true) -> Node3D:
    return _place(load(PROP_ROOT + kind + ".gltf") as PackedScene, "Square" + kind, point, height, yaw, physical)

func _place(scene: PackedScene, node_name: String, point: Vector3, height: float, yaw: float, physical: bool) -> Node3D:
    var public_bench := node_name=="SquareBench"
    var body: Node3D = HouseholdFurniture.new() if public_bench else StaticBody3D.new() if physical else Node3D.new()
    body.name = "BenchPublic_%d_%d"%[roundi(point.x*100),roundi(point.z*100)] if public_bench else node_name
    if public_bench:
        body.add_to_group("public_rest_furniture")
        body.set_meta("rest_support_y",height)
        body.set_meta("approach_offset",Vector3(0,0,-1.05))
    body.add_to_group("capital_square_prop")
    body.position = Vector3(point.x, _ground_y(point), point.z)
    body.rotation.y = yaw
    if public_bench:
        var furniture:=get_node_or_null("PublicFurniture")
        if furniture==null:
            furniture=Node3D.new();furniture.name="PublicFurniture";add_child(furniture)
        furniture.add_child(body)
    else:add_child(body)
    var visual := scene.instantiate() as Node3D
    body.add_child(visual)
    var bounds := _bounds(visual, Transform3D.IDENTITY)
    assert(bounds.size.y > 0.001, "Selected square prop has no physical mesh height")
    var scale_factor := height / bounds.size.y
    visual.scale *= scale_factor
    var center := bounds.get_center()
    visual.position -= Vector3(center.x, bounds.position.y, center.z) * scale_factor
    if public_bench or node_name=="PublicMealTable":
        for part in [visual]+visual.find_children("*","MeshInstance3D",true,false):
            if part is MeshInstance3D:
                for slot in range(part.mesh.get_surface_count()):
                    part.set_surface_override_material(slot,preload("res://assets/production/exteriors/family_home/Timber.tres"))
    body.set_meta("authored_height", height)
    if physical:
        body.add_to_group("map_fixture")
        body.set_meta("map_footprint", Vector2(bounds.size.x, bounds.size.z) * scale_factor)
        if node_name in ["SquareMarketStall","ConceptMarketCanopy"]:
            MARKET_STRUCTURE.physical_mesh(body,visual,scene.resource_path+"|"+str(height))
        else:
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
    resident.body_sex = "female" if id == SHOP_ID else "male"
    resident.position = Vector3(workplace.x, _ground_y(workplace) + 0.08, workplace.z)
    add_child(resident)
    return resident

func _apply_indoor_quality() -> void:
    if is_instance_valid(indoor_light):
        indoor_light.shadow_enabled = bool(SettingsManager.quality_profile().get("shadows", false))
