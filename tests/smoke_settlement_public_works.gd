extends Node3D

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const PUBLIC_WORKS_SCRIPT := preload("res://scripts/settlement_public_works.gd")

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Settlement public works smoke::%s" % clean)
    push_error("Settlement public works smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    if not ResourceLoader.exists("res://assets/production/medieval/quaternius_market/Stall_Empty.gltf"):
        _fail(2, "production market stall asset is missing")
        return
    if not ResourceLoader.exists("res://assets/production/medieval/quaternius_market/Stall_Cart_Empty.gltf"):
        _fail(3, "production cart-stall asset is missing")
        return

    var settlements := SETTLEMENTS_SCRIPT.new() as WorldSettlements
    settlements.name = "Settlements"
    add_child(settlements)

    var works := PUBLIC_WORKS_SCRIPT.new() as SettlementPublicWorks
    works.name = "SettlementPublicWorks"
    add_child(works)

    await get_tree().process_frame

    var town := settlements.materialize_settlement_for_test("first_fortified_town")
    if town == null:
        _fail(4, "fortified town could not be materialized")
        return
    if not works.decorate_settlement(town):
        _fail(5, "public works could not decorate fortified town")
        return
    await get_tree().process_frame

    var public_works := town.get_node_or_null("PublicWorks") as Node3D
    if public_works == null:
        _fail(6, "fortified town has no streamed PublicWorks root")
        return
    if public_works.get_parent() != town or not bool(public_works.get_meta("streamed_with_settlement", false)):
        _fail(7, "public infrastructure is not owned by the streamed settlement root")
        return

    var market := public_works.get_node_or_null("MarketDistrict") as Node3D
    if market == null or not bool(market.get_meta("physical_market", false)):
        _fail(8, "fortified town has no physical market district")
        return
    var square := market.get_node_or_null("MarketSquareSurface") as MeshInstance3D
    if square == null or square.mesh == null:
        _fail(9, "market has no visible surfaced square")
        return
    if String(square.get_meta("physical_support", "")) != "streamed_world_terrain":
        _fail(10, "market square is not explicitly supported by physical world terrain")
        return

    var corridor := market.get_node_or_null("MarketCartCorridor") as Marker3D
    if corridor == null:
        _fail(11, "market has no cart corridor")
        return
    var corridor_width := float(corridor.get_meta("clear_width", 0.0))
    if corridor_width < 8.0:
        _fail(12, "market cart corridor is too narrow for two-way service access")
        return
    if String(corridor.get_meta("connected_road", "")) != "TownMainRoad":
        _fail(13, "market cart corridor is not connected to the physical town road")
        return

    var stall_count := 0
    var cart_stall_count := 0
    for candidate in market.get_children():
        var stall := candidate as StaticBody3D
        if stall == null or not stall.name.begins_with("MarketStall_"):
            continue
        stall_count += 1
        if bool(stall.get_meta("cart_variant", false)):
            cart_stall_count += 1
        if absf(stall.position.x) < corridor_width * 0.5 + 2.0:
            _fail(14, "%s blocks the required cart corridor" % stall.name)
            return
        var collision := stall.get_node_or_null("StallCollision") as CollisionShape3D
        if collision == null or collision.shape == null:
            _fail(15, "%s is visual-only and lacks physical collision" % stall.name)
            return
        var model := stall.get_node_or_null("RealStallModel") as Node3D
        if model == null or not bool(model.get_meta("production_asset", false)):
            _fail(16, "%s does not use the promoted real Quaternius model" % stall.name)
            return
        if String(stall.get_meta("license", "")) != "CC0":
            _fail(17, "%s lost verified license metadata" % stall.name)
            return
        var mesh_count := 0
        if model is MeshInstance3D and (model as MeshInstance3D).mesh != null:
            mesh_count += 1
        for mesh_candidate in model.find_children("*", "MeshInstance3D", true, false):
            var mesh_instance := mesh_candidate as MeshInstance3D
            if mesh_instance != null and mesh_instance.mesh != null:
                mesh_count += 1
        if mesh_count < 1:
            _fail(18, "%s production model contains no imported mesh" % stall.name)
            return
    if stall_count < 6:
        _fail(19, "fortified market has fewer than six physical vendor positions")
        return
    if cart_stall_count < 2:
        _fail(20, "market lacks cart-based vendor positions")
        return

    var loading_yard := market.get_node_or_null("LoadingYard") as Marker3D
    if loading_yard == null or float(loading_yard.get_meta("turning_diameter", 0.0)) < 10.0:
        _fail(21, "market has no usable cart turning/loading yard")
        return

    var original_well := town.get_node_or_null("PhysicalWell")
    var secondary_well := public_works.get_node_or_null("SecondaryWell") as Node3D
    if original_well == null or secondary_well == null:
        _fail(22, "fortified town still depends on a single physical water point")
        return
    if not bool(secondary_well.get_meta("independent_source", false)):
        _fail(23, "secondary well is not classified as an independent water source")
        return
    if secondary_well.get_node_or_null("WellWater") == null:
        _fail(24, "secondary well has no visible water surface")
        return
    var physical_well_parts := 0
    for child in secondary_well.get_children():
        if child is StaticBody3D:
            var child_body := child as StaticBody3D
            var shape_node := child_body.get_node_or_null("Collision") as CollisionShape3D
            if shape_node != null and shape_node.shape != null:
                physical_well_parts += 1
    if physical_well_parts < 10:
        _fail(25, "secondary well does not have a physical stone/timber structure")
        return

    var warehouse_specs := [
        {"name":"GrainWarehouse", "commodity":"grain"},
        {"name":"DryGoodsWarehouse", "commodity":"dry_goods"}
    ]
    for warehouse_spec in warehouse_specs:
        var warehouse_name := String(warehouse_spec.get("name", ""))
        var commodity := String(warehouse_spec.get("commodity", ""))
        var warehouse := public_works.get_node_or_null(warehouse_name) as EnterableWarehouse
        if warehouse == null:
            _fail(26, "%s is missing" % warehouse_name)
            return
        if String(warehouse.get_meta("commodity_class", "")) != commodity:
            _fail(27, "%s is not commodity-specific" % warehouse_name)
            return
        if warehouse.front_door == null or warehouse.door_count < 1:
            _fail(28, "%s cannot be physically entered through a real door" % warehouse_name)
            return
        var storage := warehouse.get_node_or_null("WarehouseStorage") as Node3D
        if storage == null:
            _fail(29, "%s has no physical storage interior" % warehouse_name)
            return
        if warehouse.get_node_or_null("InteriorFurniture") != null:
            _fail(30, "%s incorrectly retained dwelling furniture" % warehouse_name)
            return
        var aisle := storage.get_node_or_null("CentralLoadingAisle") as Marker3D
        if aisle == null or float(aisle.get_meta("clear_width", 0.0)) < 2.2:
            _fail(31, "%s loading aisle is not physically usable" % warehouse_name)
            return
        var storage_collision_count := 0
        for prop in storage.get_children():
            if prop is StaticBody3D:
                var prop_body := prop as StaticBody3D
                var prop_collision := prop_body.get_node_or_null("Collision") as CollisionShape3D
                if prop_collision != null and prop_collision.shape != null:
                    storage_collision_count += 1
        if storage_collision_count < 6:
            _fail(32, "%s has fewer than six physical storage fixtures" % warehouse_name)
            return

    var village := settlements.materialize_settlement_for_test("border_village_01")
    if village == null or not works.decorate_settlement(village):
        _fail(33, "border village public works could not materialize")
        return
    await get_tree().process_frame
    var village_market := village.get_node_or_null("PublicWorks/VillageMarket") as Node3D
    if village_market == null:
        _fail(34, "border village has no physical market frontage")
        return
    var village_stalls := 0
    for candidate in village_market.get_children():
        if candidate is StaticBody3D and candidate.name.begins_with("VillageStall"):
            village_stalls += 1
    if village_stalls < 2:
        _fail(35, "border village market is not physically represented")
        return

    if works.market_stall_count() < 8 or works.warehouse_count() < 2 or works.water_point_count() < 1:
        _fail(36, "public works counters disagree with materialized infrastructure")
        return

    print("SETTLEMENT_PUBLIC_WORKS_SMOKE_OK town_stalls=", stall_count, " village_stalls=", village_stalls, " warehouses=", works.warehouse_count(), " new_water_points=", works.water_point_count())
    get_tree().quit(0)
