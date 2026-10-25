extends RefCounted

# Compact, JSON-safe state for explicitly identified streamed residents. Never
# persist Node references, instance IDs or a shared doorway's transient owner.
static func decode(value: Variant, anchor: Vector3, spawn: Vector3, role: String) -> Dictionary:
    if not value is Dictionary:
        return {}
    if not _number(value.get("runtime_version")) or float(value.runtime_version) != 1.0:
        return {}
    if not value.get("role") is String or String(value.role) != role:
        return {}
    var saved_anchor := _vector(value.get("anchor"))
    var saved_position := _vector(value.get("position"))
    if saved_anchor.is_empty() or saved_position.is_empty():
        return {}
    var point: Vector3 = saved_position.value
    if Vector3(saved_anchor.value).distance_to(anchor) > 0.05:
        return {}
    if Vector2(point.x - spawn.x, point.z - spawn.z).length() > 512.0 or absf(point.y - spawn.y) > 64.0:
        return {}
    if not _number(value.get("yaw")):
        return {}
    return {
        "position": point,
        "yaw": wrapf(float(value.yaw), -PI, PI),
        "home_crossing": value.get("home_crossing") is bool and bool(value.home_crossing),
        "pause_elapsed": _bounded(value.get("pause_elapsed"), 10.0),
        "witnessed_pause": _bounded(value.get("witnessed_pause"), 6.0),
        "route_index": int(_bounded(value.get("route_index"), 10000.0))
    }

static func _vector(value: Variant) -> Dictionary:
    if not value is Array or value.size() != 3:
        return {}
    for component in value:
        if not _number(component):
            return {}
    return {"value": Vector3(float(value[0]), float(value[1]), float(value[2]))}

static func _number(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value))

static func _bounded(value: Variant, maximum: float) -> float:
    return clampf(float(value), 0.0, maximum) if _number(value) else 0.0
