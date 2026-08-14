extends Node3D

const TRACK_SHADER := preload("res://assets/shaders/environment/track_mark.gdshader")

@export var max_marks: int = 160
@export var default_lifetime: float = 45.0
@export var fade_fraction: float = 0.25
@export var visibility_distance: float = 38.0

var _marks: Array[Dictionary] = []

func spawn_footprint(position: Vector3, normal: Vector3, forward: Vector3, size: Vector2 = Vector2(0.26, 0.52), lifetime: float = -1.0) -> MeshInstance3D:
    return spawn_mark(position, normal, forward, size, 0, Color(0.12, 0.09, 0.06, 0.72), lifetime)

func spawn_tire_track(position: Vector3, normal: Vector3, forward: Vector3, size: Vector2 = Vector2(0.42, 1.15), lifetime: float = -1.0) -> MeshInstance3D:
    return spawn_mark(position, normal, forward, size, 1, Color(0.08, 0.07, 0.06, 0.55), lifetime)

func spawn_mud_mark(position: Vector3, normal: Vector3, forward: Vector3 = Vector3.FORWARD, size: Vector2 = Vector2(0.55, 0.55), lifetime: float = -1.0) -> MeshInstance3D:
    return spawn_mark(position, normal, forward, size, 2, Color(0.16, 0.10, 0.05, 0.62), lifetime)

func spawn_scorch_mark(position: Vector3, normal: Vector3, forward: Vector3 = Vector3.FORWARD, size: Vector2 = Vector2(0.85, 0.85), lifetime: float = 90.0) -> MeshInstance3D:
    return spawn_mark(position, normal, forward, size, 3, Color(0.025, 0.02, 0.018, 0.82), lifetime)

func spawn_spill_mark(position: Vector3, normal: Vector3, forward: Vector3 = Vector3.FORWARD, size: Vector2 = Vector2(0.50, 0.50), color: Color = Color(0.23, 0.035, 0.025, 0.58), lifetime: float = 55.0) -> MeshInstance3D:
    return spawn_mark(position, normal, forward, size, 4, color, lifetime)

func spawn_mark(position: Vector3, normal: Vector3, forward: Vector3, size: Vector2, kind: int, color: Color, lifetime: float = -1.0) -> MeshInstance3D:
    _trim_if_needed()

    var n := normal.normalized()
    if n.length_squared() < 0.5:
        n = Vector3.UP

    var f := forward - n * forward.dot(n)
    if f.length_squared() < 0.001:
        f = Vector3.FORWARD - n * Vector3.FORWARD.dot(n)
    if f.length_squared() < 0.001:
        f = Vector3.RIGHT - n * Vector3.RIGHT.dot(n)
    f = f.normalized()

    var right := n.cross(f).normalized()
    var basis := Basis(right, n, -f)

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "EnvironmentMark"
    mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mesh_instance.visibility_range_end = visibility_distance
    mesh_instance.visibility_range_end_margin = 4.0

    var plane := PlaneMesh.new()
    plane.size = size
    plane.subdivide_width = 0
    plane.subdivide_depth = 0
    mesh_instance.mesh = plane

    var material := ShaderMaterial.new()
    material.shader = TRACK_SHADER
    material.set_shader_parameter("mark_kind", clampi(kind, 0, 4))
    material.set_shader_parameter("mark_color", color)
    material.set_shader_parameter("mark_alpha", 1.0)
    mesh_instance.material_override = material

    add_child(mesh_instance)
    mesh_instance.global_transform = Transform3D(basis, position + n * 0.012)

    var resolved_lifetime := default_lifetime if lifetime <= 0.0 else lifetime
    _marks.append({
        "node": mesh_instance,
        "material": material,
        "age": 0.0,
        "lifetime": maxf(resolved_lifetime, 0.5)
    })
    return mesh_instance

func clear_marks() -> void:
    for item in _marks:
        var node := item.get("node") as Node
        if is_instance_valid(node):
            node.queue_free()
    _marks.clear()

func _process(delta: float) -> void:
    for i in range(_marks.size() - 1, -1, -1):
        var item: Dictionary = _marks[i]
        var node := item.get("node") as Node
        var material := item.get("material") as ShaderMaterial
        if not is_instance_valid(node) or material == null:
            _marks.remove_at(i)
            continue

        var age: float = float(item.get("age", 0.0)) + delta
        var lifetime: float = float(item.get("lifetime", default_lifetime))
        item["age"] = age
        _marks[i] = item

        var fade_start := lifetime * (1.0 - clampf(fade_fraction, 0.05, 0.95))
        var alpha := 1.0
        if age > fade_start:
            alpha = 1.0 - clampf((age - fade_start) / maxf(lifetime - fade_start, 0.001), 0.0, 1.0)
        material.set_shader_parameter("mark_alpha", alpha)

        if age >= lifetime:
            node.queue_free()
            _marks.remove_at(i)

func _trim_if_needed() -> void:
    while _marks.size() >= max(max_marks, 1):
        var oldest: Dictionary = _marks.pop_front()
        var node := oldest.get("node") as Node
        if is_instance_valid(node):
            node.queue_free()
