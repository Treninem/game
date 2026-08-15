extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const GATES := preload("res://scripts/settlement_gate_network.gd")

func _ready() -> void:
    var failures: Array[String] = []
    var expected := {
        "border_village_01": 3,
        "border_village_02": 1,
        "first_fortified_town": 3
    }
    var half_sizes := {
        "border_village_01": Vector2(78.0, 68.0),
        "border_village_02": Vector2(78.0, 68.0),
        "first_fortified_town": Vector2(150.0, 115.0)
    }
    for poi in GEOGRAPHY.poi_catalog():
        var id := String(poi.get("id", ""))
        if not expected.has(id):
            continue
        var center: Vector2 = poi.get("pos", Vector2.ZERO)
        var yaw := _road_facing_yaw(center)
        var half_size: Vector2 = half_sizes[id]
        var gate_half_width := 5.0 if id != "first_fortified_town" else 7.0
        var directions := GATES.incident_world_directions(center)
        if directions.size() != int(expected[id]):
            failures.append("%s expected %d incident road directions, got %d" % [id, int(expected[id]), directions.size()])
            continue
        var gates := GATES.local_gate_specs(center, yaw, half_size, gate_half_width)
        if gates.size() != int(expected[id]):
            failures.append("%s expected %d distinct perimeter gates, got %d" % [id, int(expected[id]), gates.size()])
            continue
        for gate in gates:
            var point: Vector2 = gate.get("point", Vector2.ZERO)
            var on_x := absf(absf(point.x) - half_size.x) < 0.05
            var on_z := absf(absf(point.y) - half_size.y) < 0.05
            if not on_x and not on_z:
                failures.append("%s road gate does not land on perimeter: %s" % [id, point])
            var side := String(gate.get("side", ""))
            var tangent_half := half_size.x if side == "front" or side == "back" else half_size.y
            var intervals := GATES.side_intervals(gates, side, tangent_half)
            var tangent := float(gate.get("tangent", 0.0))
            for solid in intervals:
                if tangent > solid.x and tangent < solid.y:
                    failures.append("%s gate at %.2f remains sealed by generated wall interval %s" % [id, tangent, solid])
        var strip := GATES.road_strip_spec(gates[0], half_size, 26.0, 8.5)
        if float(strip.get("length", 0.0)) <= half_size.y:
            failures.append("%s road strip does not extend outside its perimeter" % id)
        if float(strip.get("width", 0.0)) < gate_half_width:
            failures.append("%s road strip is narrower than usable gate passage" % id)

    if failures.is_empty():
        print("SETTLEMENT_GATE_NETWORK_SMOKE_OK village_junction=3 river_village=1 fortified_town=3")
        get_tree().quit(0)
        return
    for failure in failures:
        push_error(failure)
    get_tree().quit(1)

func _road_facing_yaw(center: Vector2) -> float:
    var directions := GATES.incident_world_directions(center)
    if directions.is_empty():
        return 0.0
    var direction := directions[0]
    return atan2(direction.x, direction.y)
