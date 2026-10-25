extends SceneTree

const GEOGRAPHY := preload("res://scripts/world_geography.gd")

func _initialize() -> void:
    call_deferred("_run")

func _reference(point: Vector2) -> float:
    # Deliberately unpruned oracle, independent of the production broad phase.
    var best := INF
    for road: Dictionary in GEOGRAPHY.road_catalog():
        var points: Array = road.points
        for i in range(points.size() - 1):
            var nearest := Geometry2D.get_closest_point_to_segment(point, points[i], points[i + 1])
            best = minf(best, point.distance_to(nearest))
    return best

func _run() -> void:
    var points: Array[Vector2] = []
    var rng := RandomNumberGenerator.new()
    rng.seed = 260822
    for i in range(1800):
        points.append(Vector2(rng.randf_range(-32000, 32000), rng.randf_range(-32000, 32000)))
    # Endpoints, joins and either side of the inclusive road/shoulder boundaries.
    for road: Dictionary in GEOGRAPHY.road_catalog():
        var vertices: Array = road.points
        for i in range(vertices.size() - 1):
            var a: Vector2 = vertices[i]
            var b: Vector2 = vertices[i + 1]
            var direction := (b - a).normalized()
            var normal := Vector2(-direction.y, direction.x)
            for fraction in [-0.01, 0.0, 0.5, 1.0, 1.01]:
                for width in [0.0, 4.199, 4.2, 4.201, 12.999, 13.0, 13.001, 14.0]:
                    for side in [-1.0, 1.0]:
                        points.append(a.lerp(b, fraction) + normal * width * side)
    var maximum_error := 0.0
    for point: Vector2 in points:
        var reference := _reference(point)
        var actual := GEOGRAPHY.distance_to_primary_road(point)
        var error := absf(reference - actual)
        maximum_error = maxf(maximum_error, error)
        assert(error <= 0.004, "Unbounded road distance disagrees with independent oracle")
        for cap in [0.0, 4.2, 5.2, 13.0, 14.0, 96.0, 10000.0]:
            var bounded := GEOGRAPHY.distance_to_primary_road(point, cap)
            assert(absf(bounded - minf(actual, cap)) <= 0.000001, "Capped road distance changes geometry inside its radius")
        assert(GEOGRAPHY.is_on_primary_road(point) == (actual <= GEOGRAPHY.PRIMARY_ROAD_HALF_WIDTH), "Inclusive road boundary changed")
    print("ROAD_DISTANCE_OK points=", points.size(), " maximum_oracle_error_m=", maximum_error)
    quit()
