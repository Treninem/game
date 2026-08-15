class_name SettlementGateNetwork
extends RefCounted

const GEOGRAPHY := preload("res://scripts/world_geography.gd")

const CENTER_EPSILON := 2.0
const DIRECTION_MERGE_DOT := 0.985

static func incident_world_directions(center: Vector2) -> Array[Vector2]:
    var directions: Array[Vector2] = []
    for road in GEOGRAPHY.road_catalog():
        var points: Array = road.get("points", [])
        for i in range(points.size()):
            var point: Vector2 = points[i]
            if point.distance_to(center) > CENTER_EPSILON:
                continue
            if i > 0:
                _append_unique_direction(directions, points[i - 1] - center)
            if i + 1 < points.size():
                _append_unique_direction(directions, points[i + 1] - center)
    return directions

static func local_gate_specs(center: Vector2, root_yaw: float, half_size: Vector2, half_width: float) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var inverse_basis := Basis(Vector3.UP, root_yaw).inverse()
    for world_direction in incident_world_directions(center):
        var world3 := Vector3(world_direction.x, 0.0, world_direction.y)
        var local3 := inverse_basis * world3
        var local_direction := Vector2(local3.x, local3.z).normalized()
        if local_direction.length_squared() < 0.5:
            continue
        var hit := _rectangle_intersection(local_direction, half_size)
        var side := _side_for_hit(hit, half_size)
        var tangent_coordinate := hit.x if side == "front" or side == "back" else hit.y
        result.append({
            "side": side,
            "point": hit,
            "half_width": half_width,
            "local_direction": local_direction,
            "world_direction": world_direction,
            "tangent": tangent_coordinate
        })
    return _merge_overlapping_gates(result, half_size)

static func gate_count_for(center: Vector2, root_yaw: float, half_size: Vector2, half_width: float) -> int:
    return local_gate_specs(center, root_yaw, half_size, half_width).size()

static func side_intervals(gates: Array[Dictionary], side: String, half_extent: float) -> Array[Vector2]:
    var blocked: Array[Vector2] = []
    for gate in gates:
        if String(gate.get("side", "")) != side:
            continue
        var coordinate := float(gate.get("tangent", 0.0))
        var half_width := float(gate.get("half_width", 0.0))
        blocked.append(Vector2(maxf(-half_extent, coordinate - half_width), minf(half_extent, coordinate + half_width)))
    blocked.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)

    var merged: Array[Vector2] = []
    for interval in blocked:
        if interval.y <= interval.x:
            continue
        if merged.is_empty() or interval.x > merged[-1].y + 0.01:
            merged.append(interval)
        else:
            var last := merged[-1]
            last.y = maxf(last.y, interval.y)
            merged[-1] = last

    var solids: Array[Vector2] = []
    var cursor := -half_extent
    for interval in merged:
        if interval.x > cursor + 0.05:
            solids.append(Vector2(cursor, interval.x))
        cursor = maxf(cursor, interval.y)
    if cursor < half_extent - 0.05:
        solids.append(Vector2(cursor, half_extent))
    return solids

static func road_strip_spec(gate: Dictionary, half_size: Vector2, outside_length: float, width: float) -> Dictionary:
    var direction: Vector2 = gate.get("local_direction", Vector2(0, 1))
    var boundary_point: Vector2 = gate.get("point", Vector2.ZERO)
    var outer := boundary_point + direction * outside_length
    var center := outer * 0.5
    var length := outer.length()
    return {
        "center": center,
        "length": length,
        "width": width,
        "angle": atan2(direction.x, direction.y),
        "end": outer
    }

static func _append_unique_direction(directions: Array[Vector2], raw: Vector2) -> void:
    if raw.length_squared() < 1.0:
        return
    var direction := raw.normalized()
    for existing in directions:
        if existing.normalized().dot(direction) >= DIRECTION_MERGE_DOT:
            return
    directions.append(direction)

static func _rectangle_intersection(direction: Vector2, half_size: Vector2) -> Vector2:
    var tx := INF
    var tz := INF
    if absf(direction.x) > 0.0001:
        tx = half_size.x / absf(direction.x)
    if absf(direction.y) > 0.0001:
        tz = half_size.y / absf(direction.y)
    var t := minf(tx, tz)
    return direction * t

static func _side_for_hit(hit: Vector2, half_size: Vector2) -> String:
    var x_score := absf(absf(hit.x) - half_size.x)
    var z_score := absf(absf(hit.y) - half_size.y)
    if x_score < z_score:
        return "right" if hit.x > 0.0 else "left"
    return "front" if hit.y > 0.0 else "back"

static func _merge_overlapping_gates(gates: Array[Dictionary], half_size: Vector2) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for gate in gates:
        var merged := false
        for i in range(result.size()):
            var existing := result[i]
            if String(existing.get("side", "")) != String(gate.get("side", "")):
                continue
            var half_a := float(existing.get("half_width", 0.0))
            var half_b := float(gate.get("half_width", 0.0))
            var delta := absf(float(existing.get("tangent", 0.0)) - float(gate.get("tangent", 0.0)))
            if delta > half_a + half_b:
                continue
            var combined_direction := (Vector2(existing.get("local_direction", Vector2.ZERO)) + Vector2(gate.get("local_direction", Vector2.ZERO))).normalized()
            if combined_direction.length_squared() < 0.5:
                combined_direction = Vector2(existing.get("local_direction", Vector2(0, 1)))
            var hit := _rectangle_intersection(combined_direction, half_size)
            existing["point"] = hit
            existing["local_direction"] = combined_direction
            existing["tangent"] = hit.x if String(existing.get("side", "")) == "front" or String(existing.get("side", "")) == "back" else hit.y
            existing["half_width"] = maxf(half_a, half_b)
            result[i] = existing
            merged = true
            break
        if not merged:
            result.append(gate)
    return result
