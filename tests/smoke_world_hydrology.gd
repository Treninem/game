extends Node

const HYDROLOGY := preload("res://scripts/world_hydrology.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")

func _ready() -> void:
    await get_tree().process_frame
    var failures: Array[String] = []

    var river_center := Vector2(GEOGRAPHY.start_river_x(0.0), 0.0)
    if WorldData.water_kind_at(river_center) != "river":
        failures.append("Prologue river is not classified as physical freshwater")
    if absf(WorldData.water_level_at(river_center) - GEOGRAPHY.START_RIVER_WATER_LEVEL) > 0.01:
        failures.append("Prologue river water level drifted")
    if WorldData.elevation_at(river_center) >= WorldData.water_level_at(river_center):
        failures.append("Prologue riverbed is not below its water surface")

    # The existing Old Ford POI must be a real shallow crossing, not a map icon.
    var ford_probe := Vector2(GEOGRAPHY.start_river_x(HYDROLOGY.START_FORD_CENTER.y), HYDROLOGY.START_FORD_CENTER.y)
    if HYDROLOGY.crossing_kind_at(ford_probe) != "ford":
        failures.append("Old Ford is not classified as a physical crossing")
    if WorldData.water_kind_at(ford_probe) != "river":
        failures.append("Old Ford incorrectly removes river water")
    var ford_depth := HYDROLOGY.water_depth_at(ford_probe, WorldData.elevation_at(ford_probe))
    if ford_depth <= 0.08 or ford_depth > HYDROLOGY.START_FORD_DEPTH + 0.12:
        failures.append("Old Ford depth is outside traversable shallow-water range")

    var normal_river_probe := Vector2(GEOGRAPHY.start_river_x(-520.0), -520.0)
    var normal_depth := HYDROLOGY.water_depth_at(normal_river_probe, WorldData.elevation_at(normal_river_probe))
    if normal_depth <= ford_depth + 0.55:
        failures.append("Old Ford is not materially shallower than the normal river channel")

    # The existing Asterna river road physically crosses the same river on a
    # bridge. The bridge classification must never punch a dry hole in water.
    var bridge_probe := HYDROLOGY.ROAD_BRIDGE_CENTER
    if HYDROLOGY.crossing_kind_at(bridge_probe) != "bridge":
        failures.append("Asterna river road crossing is not classified as a bridge")
    if WorldData.water_kind_at(bridge_probe) != "river":
        failures.append("Bridge incorrectly removes the flowing river below it")
    if WorldData.water_level_at(bridge_probe) <= WorldData.elevation_at(bridge_probe):
        failures.append("Bridge crossing no longer spans a physical river channel")

    var lake_center := HYDROLOGY.LAKE_VAEL_CENTER
    if WorldData.water_kind_at(lake_center) != "lake":
        failures.append("Lake Vael POI has no physical freshwater body")
    if WorldData.biome_at(lake_center) != "freshwater":
        failures.append("Lake Vael center does not resolve to freshwater biome")
    if WorldData.elevation_at(lake_center) >= HYDROLOGY.LAKE_VAEL_WATER_LEVEL - 0.5:
        failures.append("Lake Vael basin is too shallow or missing")

    var lake_shore := lake_center + Vector2(HYDROLOGY.LAKE_VAEL_RADIUS.x * 1.05, 0.0)
    if WorldData.water_kind_at(lake_shore) == "lake":
        failures.append("Lake Vael water mask leaks beyond its shoreline")

    # Whispering Marsh already exists in the world catalog and must now resolve
    # to a real shallow, discontinuous wetland rather than a map-only marker.
    var marsh_probe := HYDROLOGY.WHISPER_MARSH_CENTER + Vector2(110.0, 40.0)
    if not HYDROLOGY.in_whisper_marsh(marsh_probe):
        # Deterministically search a nearby pool in case the center-side hummock
        # changes after an intentional implementation tuning.
        var found_pool := false
        for z in range(-5, 6):
            for x in range(-6, 7):
                var candidate := HYDROLOGY.WHISPER_MARSH_CENTER + Vector2(float(x) * 70.0, float(z) * 70.0)
                if HYDROLOGY.in_whisper_marsh(candidate):
                    marsh_probe = candidate
                    found_pool = true
                    break
            if found_pool:
                break
        if not found_pool:
            failures.append("Whispering Marsh has no physical open-water pools")

    if HYDROLOGY.in_whisper_marsh(marsh_probe):
        if WorldData.water_kind_at(marsh_probe) != "marsh":
            failures.append("Whispering Marsh pool is not classified as marsh water")
        var marsh_depth := HYDROLOGY.water_depth_at(marsh_probe, WorldData.elevation_at(marsh_probe))
        if marsh_depth <= 0.08 or marsh_depth > HYDROLOGY.WHISPER_MARSH_MAX_DEPTH + 0.12:
            failures.append("Whispering Marsh water is not in the intended shallow wading range")

    var marsh_outside := HYDROLOGY.WHISPER_MARSH_CENTER + Vector2(HYDROLOGY.WHISPER_MARSH_RADIUS.x * 1.08, 0.0)
    if WorldData.water_kind_at(marsh_outside) == "marsh":
        failures.append("Whispering Marsh water mask leaks beyond its physical wetland boundary")

    var sea_probe := Vector2(WorldData.WORLD_HALF_SIZE - 150.0, 0.0)
    if WorldData.elevation_at(sea_probe) < WorldData.SEA_LEVEL - 0.35:
        if WorldData.water_kind_at(sea_probe) != "sea":
            failures.append("Below-sea-level coastal terrain is missing sea classification")
        if absf(WorldData.water_level_at(sea_probe) - WorldData.SEA_LEVEL) > 0.01:
            failures.append("Sea surface no longer matches global sea level")

    if failures.is_empty():
        print("WORLD_HYDROLOGY_SMOKE_OK river=physical ford=shallow bridge=spanning lake=basin marsh=shallow_pools sea=classified")
        get_tree().quit(0)
        return

    for failure in failures:
        push_error(failure)
    get_tree().quit(1)
