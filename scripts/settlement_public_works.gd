class_name SettlementPublicWorks
extends Node3D

const ENTERABLE_WAREHOUSE := preload("res://scripts/enterable_warehouse.gd")
const STALL_SCENE: PackedScene = preload("res://assets/production/medieval/quaternius_market/Stall_Empty.gltf")
const CART_STALL_SCENE: PackedScene = preload("res://assets/production/medieval/quaternius_market/Stall_Cart_Empty.gltf")

const MARKET_CENTER := Vector2(0.0, -39.0)
const MARKET_SIZE := Vector2(44.0, 32.0)
const MARKET_CART_CLEAR_WIDTH := 9.0

var market_stalls_materialized := 0
var warehouses_materialized := 0
var water_points_materialized := 0
var settlements_decorated := 0

var market_ground_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var timber_material: StandardMaterial3D
var water_material: StandardMaterial3D

func _ready() -> void:
    process_priority = 45
    _prepare_materials()
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_decorate_existing")

func _exit_tree() -> void:
    if get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.disconnect(_on_node_added)

func _prepare_materials() -> void:
    market_ground_material = StandardMaterial3D.new()
    market_ground_material.albedo_color = Color(0.36, 0.30, 0.22, 1.0)
    market_ground_material.roughness = 0.97

    stone_material = StandardMaterial3D.new()
    stone_material.albedo_color = Color(0.36, 0.35, 0.33, 1.0)
    stone_material.roughness = 0.95

    timber_material = StandardMaterial3D.new()
    timber_material.albedo_color = Color(0.29, 0.19, 0.10, 1.0)
    timber_material.roughness = 0.94

    water_material = StandardMaterial3D.new()
    water_material.albedo_color = Color(0.13, 0.38, 0.50, 0.72)
    water_material.roughness = 0.22
    water_material.metallic = 0.04
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name.begins_with("Settlement_"):
        call_deferred("_decorate_candidate", node)

func _decorate_existing() -> void:
    for candidate in get_tree().get_nodes_in_group("streamed_settlement"):
        _decorate_candidate(candidate)
    # Older settlement roots predate the group, so also scan by metadata/name.
    var world := get_parent()
    if world == null:
        return
    for candidate in world.find_children("Settlement_*", "Node3D", true, false):
        _decorate_candidate(candidate)

func _decorate_candidate(node: Node) -> void:
    var root := node as Node3D
    if root == null or not is_instance_valid(root):
        return
    if not root.has_meta("settlement_id"):
        return
    decorate_settlement(root)

func decorate_settlement(root: Node3D) -> bool:
    if root == null or not is_instance_valid(root):
        return false
    if root.get_meta("public_works_ready", false):
        return true
    if market_ground_material == null:
        _prepare_materials()

    var public_works := Node3D.new()
    public_works.name = "PublicWorks"
    public_works.set_meta("streamed_with_settlement", true)
    root.add_child(public_works)

    var kind := String(root.get_meta("settlement_kind", ""))
    if kind == "fortified_town":
        _build_town_public_works(root, public_works)
    elif kind == "village":
        _build_village_public_works(root, public_works)
    else:
        public_works.queue_free()
        return false

    root.set_meta("public_works_ready", true)
    settlements_decorated += 1
    return true

func _build_village_public_works(settlement: Node3D, public_works: Node3D) -> void:
    var market := Node3D.new()
    market.name = "VillageMarket"
    market.set_meta("cart_access_width", 7.0)
    public_works.add_child(market)

    _add_market_stall(settlement, market, Vector2(-13.5, 8.5), -PI * 0.5, false, "VillageStallLeft")
    _add_market_stall(settlement, market, Vector2(13.5, 8.5), PI * 0.5, false, "VillageStallRight")

    var corridor := Marker3D.new()
    corridor.name = "VillageCartAccess"
    corridor.position = _terrain_local_position(settlement, Vector2(0.0, 8.5), 0.1)
    corridor.set_meta("clear_width", 7.0)
    corridor.set_meta("uses_existing_through_road", true)
    market.add_child(corridor)

func _build_town_public_works(settlement: Node3D, public_works: Node3D) -> void:
    var market := Node3D.new()
    market.name = "MarketDistrict"
    market.set_meta("physical_market", true)
    market.set_meta("cart_access_width", MARKET_CART_CLEAR_WIDTH)
    public_works.add_child(market)

    _add_market_square(settlement, market)

    var stall_specs := [
        {"p":Vector2(-15.0, -48.0), "r":-PI * 0.5, "cart":false},
        {"p":Vector2(15.0, -48.0), "r":PI * 0.5, "cart":false},
        {"p":Vector2(-15.0, -39.0), "r":-PI * 0.5, "cart":false},
        {"p":Vector2(15.0, -39.0), "r":PI * 0.5, "cart":false},
        {"p":Vector2(-15.0, -30.0), "r":-PI * 0.5, "cart":true},
        {"p":Vector2(15.0, -30.0), "r":PI * 0.5, "cart":true}
    ]
    for i in range(stall_specs.size()):
        var spec: Dictionary = stall_specs[i]
        _add_market_stall(
            settlement,
            market,
            spec.get("p", Vector2.ZERO),
            float(spec.get("r", 0.0)),
            bool(spec.get("cart", false)),
            "MarketStall_%02d" % i
        )

    var corridor := Marker3D.new()
    corridor.name = "MarketCartCorridor"
    corridor.position = _terrain_local_position(settlement, MARKET_CENTER, 0.12)
    corridor.set_meta("clear_width", MARKET_CART_CLEAR_WIDTH)
    corridor.set_meta("clear_length", MARKET_SIZE.y + 10.0)
    corridor.set_meta("connected_road", "TownMainRoad")
    market.add_child(corridor)

    var loading_yard := Marker3D.new()
    loading_yard.name = "LoadingYard"
    loading_yard.position = _terrain_local_position(settlement, Vector2(0.0, -58.0), 0.12)
    loading_yard.set_meta("turning_diameter", 12.0)
    loading_yard.set_meta("connected_to_market", true)
    market.add_child(loading_yard)

    _add_secondary_well(settlement, public_works, Vector2(27.0, -43.0))
    _add_warehouse(settlement, public_works, "GrainWarehouse", Vector2(-61.0, 43.0), PI * 0.5, "grain", 2)
    _add_warehouse(settlement, public_works, "DryGoodsWarehouse", Vector2(61.0, 43.0), -PI * 0.5, "dry_goods", 3)

func _add_market_square(settlement: Node3D, market: Node3D) -> void:
    var surface := MeshInstance3D.new()
    surface.name = "MarketSquareSurface"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(MARKET_SIZE.x, 0.05, MARKET_SIZE.y)
    mesh.material = market_ground_material
    surface.mesh = mesh
    surface.position = _terrain_local_position(settlement, MARKET_CENTER, 0.055)
    surface.set_meta("physical_support", "streamed_world_terrain")
    surface.set_meta("cart_clear_width", MARKET_CART_CLEAR_WIDTH)
    surface.visibility_range_end = 620.0
    market.add_child(surface)

func _add_market_stall(settlement: Node3D, parent: Node3D, local_pos: Vector2, yaw: float, cart_variant: bool, node_name: String) -> StaticBody3D:
    var stall := StaticBody3D.new()
    stall.name = node_name
    stall.position = _terrain_local_position(settlement, local_pos, 0.03)
    stall.rotation.y = yaw
    stall.collision_layer = 1
    stall.collision_mask = 1
    stall.add_to_group("market_stall")
    stall.set_meta("source_pack", "quaternius_fantasy_props_megakit_standard")
    stall.set_meta("license", "CC0")
    stall.set_meta("cart_variant", cart_variant)
    parent.add_child(stall)

    var scene := CART_STALL_SCENE if cart_variant else STALL_SCENE
    var model := scene.instantiate() as Node3D
    if model != null:
        model.name = "RealStallModel"
        model.scale = Vector3(1.85, 1.45, 2.0) if not cart_variant else Vector3(1.55, 1.40, 1.65)
        model.set_meta("production_asset", true)
        stall.add_child(model)

    var collision := CollisionShape3D.new()
    collision.name = "StallCollision"
    var shape := BoxShape3D.new()
    shape.size = Vector3(3.55, 2.85, 1.95) if not cart_variant else Vector3(4.25, 2.75, 2.35)
    collision.shape = shape
    collision.position = Vector3(0.0, shape.size.y * 0.5, 0.0)
    stall.add_child(collision)

    market_stalls_materialized += 1
    return stall

func _add_secondary_well(settlement: Node3D, parent: Node3D, local_pos: Vector2) -> Node3D:
    var well := Node3D.new()
    well.name = "SecondaryWell"
    well.position = _terrain_local_position(settlement, local_pos, 0.02)
    well.add_to_group("public_water_source")
    well.set_meta("water_source_kind", "well")
    well.set_meta("independent_source", true)
    parent.add_child(well)

    var segment_count := 10
    var ring_radius := 1.45
    for i in range(segment_count):
        var angle := TAU * float(i) / float(segment_count)
        var segment := _make_static_box(
            "WellStone_%02d" % i,
            Vector3(0.88, 0.78, 0.42),
            stone_material
        )
        segment.position = Vector3(cos(angle) * ring_radius, 0.39, sin(angle) * ring_radius)
        segment.rotation.y = -angle
        well.add_child(segment)

    var water := MeshInstance3D.new()
    water.name = "WellWater"
    var water_mesh := CylinderMesh.new()
    water_mesh.top_radius = 1.15
    water_mesh.bottom_radius = 1.15
    water_mesh.height = 0.035
    water_mesh.material = water_material
    water.mesh = water_mesh
    water.position = Vector3(0.0, 0.38, 0.0)
    well.add_child(water)

    var post_left := _make_static_box("WellPostLeft", Vector3(0.22, 2.45, 0.22), timber_material)
    post_left.position = Vector3(-1.35, 1.45, 0.0)
    well.add_child(post_left)
    var post_right := _make_static_box("WellPostRight", Vector3(0.22, 2.45, 0.22), timber_material)
    post_right.position = Vector3(1.35, 1.45, 0.0)
    well.add_child(post_right)
    var beam := _make_static_box("WellBeam", Vector3(3.05, 0.22, 0.22), timber_material)
    beam.position = Vector3(0.0, 2.62, 0.0)
    well.add_child(beam)

    water_points_materialized += 1
    return well

func _add_warehouse(settlement: Node3D, parent: Node3D, node_name: String, local_pos: Vector2, yaw: float, commodity: String, variant: int) -> EnterableWarehouse:
    var warehouse := ENTERABLE_WAREHOUSE.new() as EnterableWarehouse
    warehouse.name = node_name
    warehouse.configure_warehouse(Vector3(18.0, 4.35, 13.0), variant, "Городской склад", commodity)
    warehouse.position = _terrain_local_position(settlement, local_pos, 0.02)
    warehouse.rotation.y = yaw
    warehouse.add_to_group("public_warehouse")
    warehouse.set_meta("market_service", true)
    parent.add_child(warehouse)
    warehouses_materialized += 1
    return warehouse

func _make_static_box(node_name: String, size: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.collision_layer = 1
    body.collision_mask = 1

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
    return body

func _terrain_local_position(settlement: Node3D, local_pos: Vector2, lift: float) -> Vector3:
    var horizontal_world := settlement.to_global(Vector3(local_pos.x, 0.0, local_pos.y))
    var ground_y := WorldData.elevation_at(Vector2(horizontal_world.x, horizontal_world.z))
    return settlement.to_local(Vector3(horizontal_world.x, ground_y + lift, horizontal_world.z))

func market_stall_count() -> int:
    return market_stalls_materialized

func warehouse_count() -> int:
    return warehouses_materialized

func water_point_count() -> int:
    return water_points_materialized
