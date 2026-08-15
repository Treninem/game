extends Node3D

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const REQUIRED_IDS := ["border_village_01", "border_village_02", "first_fortified_town"]

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=World settlements smoke::%s" % clean)
    push_error("World settlements smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var settlements := SETTLEMENTS_SCRIPT.new() as WorldSettlements
    settlements.name = "TestSettlements"
    add_child(settlements)
    await get_tree().process_frame

    var specs := settlements.settlement_specs()
    if specs.size() != 3:
        _fail(2, "expected exactly the two established border villages and first fortified town; got %d" % specs.size())
        return
    for required_id in REQUIRED_IDS:
        if settlements.settlement_spec(required_id).is_empty():
            _fail(3, "missing established settlement spec %s" % required_id)
            return
    if settlements.UNLOAD_RADIUS <= settlements.LOAD_RADIUS:
        _fail(4, "settlement streamer has no unload hysteresis and may thrash near its boundary")
        return

    var village_a := settlements.materialize_settlement_for_test("border_village_01")
    var village_b := settlements.materialize_settlement_for_test("border_village_02")
    var town := settlements.materialize_settlement_for_test("first_fortified_town")
    if village_a == null or village_b == null or town == null:
        _fail(5, "one or more established settlements could not materialize")
        return

    for _i in range(5):
        await get_tree().physics_frame

    if settlements.loaded_settlement_count() != 3:
        _fail(6, "manual materialization did not register all three settlements")
        return

    if _enterable_count(village_a) < 7:
        _fail(7, "first border village has fewer than seven real enterable buildings")
        return
    if _enterable_count(village_b) < 8:
        _fail(8, "river village has fewer than eight real enterable buildings")
        return
    if _enterable_count(town) < 15:
        _fail(9, "fortified town has fewer than fifteen real enterable buildings")
        return

    if not _validate_enterable(village_a, "first border village"):
        return
    if not _validate_enterable(village_b, "river village"):
        return
    if not _validate_enterable(town, "fortified town"):
        return

    for village in [village_a, village_b]:
        var gate := village.get_node_or_null("VillageGatePassage") as Marker3D
        if gate == null:
            _fail(20, "%s has no physical fence entrance passage" % village.name)
            return
        for fence_name in ["FenceFrontLeft", "FenceFrontRight", "FenceBack", "FenceLeft", "FenceRight"]:
            if not _validate_static_shape(village.get_node_or_null(fence_name), "%s/%s" % [village.name, fence_name]):
                return
        if not _validate_static_shape(village.get_node_or_null("PhysicalWell"), "%s/PhysicalWell" % village.name):
            return

    var passage := town.get_node_or_null("TownGatePassage") as Marker3D
    if passage == null:
        _fail(30, "fortified town has no explicit gate passage")
        return
    var half_width := float(passage.get_meta("half_width", 0.0))
    var clear_height := float(passage.get_meta("clear_height", 0.0))
    if half_width < 6.5 or clear_height < 5.5:
        _fail(31, "fortified town gate is too small for people, mounted traffic and carts")
        return

    for wall_name in ["TownWallFrontLeft", "TownWallFrontRight", "TownWallBack", "TownWallLeft", "TownWallRight"]:
        if not _validate_static_shape(town.get_node_or_null(wall_name), "fortified town/%s" % wall_name):
            return
    for leaf_name in ["GateLeafLeft", "GateLeafRight"]:
        if not _validate_static_shape(town.get_node_or_null(leaf_name), "fortified town/%s" % leaf_name):
            return

    var left := town.get_node_or_null("TownWallFrontLeft") as StaticBody3D
    var right := town.get_node_or_null("TownWallFrontRight") as StaticBody3D
    var left_shape := _box_shape(left)
    var right_shape := _box_shape(right)
    if left_shape == null or right_shape == null:
        _fail(32, "front town wall segments are not box-shaped physical walls")
        return
    var left_inner := left.position.x + left_shape.size.x * 0.5
    var right_inner := right.position.x - right_shape.size.x * 0.5
    var physical_gap := right_inner - left_inner
    if physical_gap < settlements.TOWN_GATE_HALF_WIDTH * 2.0 - 0.2:
        _fail(33, "town wall collision closes the declared gate passage; gap=%.2f" % physical_gap)
        return

    if settlements.materialized_buildings < 30:
        _fail(34, "settlement batch did not actually create the expected building volume")
        return
    if settlements.materialized_gate_passages < 3:
        _fail(35, "settlement entrances were not all materialized")
        return
    if settlements.materialized_wall_segments < 5:
        _fail(36, "fortified town has no complete physical perimeter")
        return

    print("WORLD_SETTLEMENTS_SMOKE_OK settlements=3 enterable_buildings=", settlements.materialized_buildings, " walls=", settlements.materialized_wall_segments, " gates=", settlements.materialized_gate_passages)
    get_tree().quit(0)

func _enterable_count(root: Node3D) -> int:
    var count := 0
    for child in root.get_children():
        if child is EnterableBuilding:
            count += 1
    return count

func _validate_enterable(root: Node3D, label: String) -> bool:
    for child in root.get_children():
        if child is EnterableBuilding:
            var building := child as EnterableBuilding
            if not building.is_in_group("enterable_building"):
                _fail(40, "%s building is not registered as enterable" % label)
                return false
            if building.front_door == null or building.door_count != 1:
                _fail(41, "%s building has no real front door" % label)
                return false
            if building.structural_piece_count < 14:
                _fail(42, "%s building is monolithic instead of having a physical shell" % label)
                return false
            if building.interior_size.x <= 4.0 or building.interior_size.z <= 4.0:
                _fail(43, "%s building has no usable interior standing space" % label)
                return false
            return true
    _fail(44, "%s contains no EnterableBuilding nodes" % label)
    return false

func _validate_static_shape(node: Node, label: String) -> bool:
    var body := node as StaticBody3D
    if body == null:
        _fail(50, "%s is not a StaticBody3D" % label)
        return false
    for child in body.get_children():
        if child is CollisionShape3D and (child as CollisionShape3D).shape != null:
            return true
    _fail(51, "%s has no physical collision shape" % label)
    return false

func _box_shape(body: StaticBody3D) -> BoxShape3D:
    if body == null:
        return null
    for child in body.get_children():
        if child is CollisionShape3D:
            var shape := (child as CollisionShape3D).shape
            if shape is BoxShape3D:
                return shape as BoxShape3D
    return null
