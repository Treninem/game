extends Node3D

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const OVERLAY_SCRIPT := preload("res://scripts/settlement_road_gate_overlay.gd")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_test")

func _run_test() -> void:
    var overlay := OVERLAY_SCRIPT.new() as SettlementRoadGateOverlay
    overlay.name = "GateOverlay"
    add_child(overlay)

    var settlements := SETTLEMENTS_SCRIPT.new() as WorldSettlements
    settlements.name = "Settlements"
    add_child(settlements)
    await get_tree().process_frame

    var town := settlements.materialize_settlement_for_test("first_fortified_town")
    if town == null:
        _fail("fortified town could not materialize")
        return

    for _i in range(4):
        await get_tree().process_frame

    var network := town.get_node_or_null("RoadGateNetwork") as Node3D
    if network == null:
        _fail("road-aware gate overlay did not replace the legacy town perimeter")
        return

    var gate_count := int(network.get_meta("gate_count", 0))
    if gate_count != 3:
        _fail("fortified town must expose all three incident road gates; got %d" % gate_count)
        return

    for gate_index in range(gate_count):
        var marker := network.get_node_or_null("RoadGatePassage_%02d" % gate_index) as Marker3D
        if marker == null:
            _fail("gate %d has no physical passage marker" % gate_index)
            return
        if not bool(marker.get_meta("road_connected", false)):
            _fail("gate %d is not marked as connected to the world road network" % gate_index)
            return
        var half_width := float(marker.get_meta("half_width", 0.0))
        if half_width < 6.5:
            _fail("gate %d is too narrow for mounted and cart traffic" % gate_index)
            return

        var approach := network.get_node_or_null("RoadApproach_%02d" % gate_index) as Node3D
        if approach == null or not bool(approach.get_meta("extends_outside_perimeter", false)):
            _fail("gate %d has no road approach extending beyond the wall" % gate_index)
            return
        var boundary: Vector2 = approach.get_meta("gate_boundary", Vector2.ZERO)
        var outer: Vector2 = approach.get_meta("outer_endpoint", Vector2.ZERO)
        if outer.distance_to(boundary) < OVERLAY_SCRIPT.ROAD_OUTSIDE_LENGTH - 0.1:
            _fail("gate %d road approach does not reach the outside world road" % gate_index)
            return
        if int(approach.get_meta("patch_count", 0)) < 8:
            _fail("gate %d road approach is not continuously surfaced" % gate_index)
            return

        for leaf_index in range(2):
            var leaf := network.get_node_or_null("Gate_%02d_Leaf_%d" % [gate_index, leaf_index]) as StaticBody3D
            if leaf == null:
                _fail("gate %d is missing physical leaf %d" % [gate_index, leaf_index])
                return
            if not bool(leaf.get_meta("hinged_correctly", false)):
                _fail("gate %d leaf %d is not positioned from a real hinge" % [gate_index, leaf_index])
                return
            var hinge: Vector2 = leaf.get_meta("hinge_local", Vector2.ZERO)
            var leaf_center := Vector2(leaf.position.x, leaf.position.z)
            var hinge_distance := leaf_center.distance_to(hinge)
            if hinge_distance < 2.7 or hinge_distance > 3.6:
                _fail("gate %d leaf %d center is not physically offset from its hinge; distance=%.2f" % [gate_index, leaf_index, hinge_distance])
                return
            var angle := absf(float(leaf.get_meta("open_angle_degrees", 0.0)))
            if angle < 65.0:
                _fail("gate %d leaf %d does not open far enough for traffic" % [gate_index, leaf_index])
                return
            if not _has_collision(leaf):
                _fail("gate %d leaf %d is visual-only and has no collision" % [gate_index, leaf_index])
                return

    print("SETTLEMENT_GATE_OVERLAY_SMOKE_OK gates=3 hinged_leaves=6 road_approaches=3")
    get_tree().quit(0)

func _has_collision(body: StaticBody3D) -> bool:
    for child in body.get_children():
        if child is CollisionShape3D and (child as CollisionShape3D).shape != null:
            return true
    return false

func _fail(message: String) -> void:
    failures.append(message)
    push_error(message)
    get_tree().quit(1)
