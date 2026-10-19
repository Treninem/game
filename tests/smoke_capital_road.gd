extends Node

func _ready() -> void:
    var failures: Array[String] = []
    var samples := 0
    for road: Dictionary in WorldGeography.PRIMARY_ROADS:
        if road.id != "astern_border_road":
            continue
        var points: Array = road.points
        for segment in range(points.size() - 1):
            var start: Vector2 = points[segment]
            var end: Vector2 = points[segment + 1]
            var count := ceili(start.distance_to(end) / 24.0)
            for index in range(count + 1):
                var position := start.lerp(end, float(index) / count)
                samples += 1
                if WorldData.water_kind_at(position) == "sea" or WorldData.elevation_at(position) < WorldData.SEA_LEVEL - 0.01:
                    failures.append("Canonical capital road sinks into the sea at %s" % position)
    if failures.is_empty():
        print("CAPITAL_ROAD_OK samples=", samples, " surface=continental roadbed=above_sea")
    for failure in failures:
        push_error(failure)
    get_tree().quit(0 if failures.is_empty() else 1)
