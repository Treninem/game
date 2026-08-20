extends Node

const WORLD_GEOGRAPHY := preload("res://scripts/world_geography.gd")
const WORLD_HYDROLOGY := preload("res://scripts/world_hydrology.gd")

const WORLD_HALF_SIZE := 32000.0
const WORLD_MIN := Vector2(-WORLD_HALF_SIZE, -WORLD_HALF_SIZE)
const WORLD_MAX := Vector2(WORLD_HALF_SIZE, WORLD_HALF_SIZE)
const SEA_LEVEL := 0.0
const CITY_FLAT_RADIUS := 2100.0
const CITY_BLEND_RADIUS := 2700.0
const WORLD_SEED := 260814

var elevation_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var ridge_noise := FastNoiseLite.new()

func _ready() -> void:
    elevation_noise.seed = WORLD_SEED
    elevation_noise.frequency = 0.00018
    elevation_noise.fractal_octaves = 5

    detail_noise.seed = WORLD_SEED + 71
    detail_noise.frequency = 0.0011
    detail_noise.fractal_octaves = 3

    moisture_noise.seed = WORLD_SEED + 311
    moisture_noise.frequency = 0.00013
    moisture_noise.fractal_octaves = 4

    ridge_noise.seed = WORLD_SEED + 911
    ridge_noise.frequency = 0.00009
    ridge_noise.fractal_octaves = 4

func inside_world(pos: Vector2) -> bool:
    return absf(pos.x) <= WORLD_HALF_SIZE and absf(pos.y) <= WORLD_HALF_SIZE

func elevation_at(pos: Vector2) -> float:
    if not inside_world(pos):
        return -80.0

    var broad := elevation_noise.get_noise_2d(pos.x, pos.y) * 34.0
    var detail := detail_noise.get_noise_2d(pos.x, pos.y) * 7.0
    var ridges := pow(absf(ridge_noise.get_noise_2d(pos.x, pos.y)), 2.4) * 48.0
    var macro_relief := 0.0
    var height := broad + detail + ridges

    # Political regions describe inhabited pieces of the continent. Procedural
    # noise may shape their coasts, lakes and lowlands, but it must never sink a
    # state's geographic core into the ocean. The floor only affects low terrain
    # and fades well before the ellipse boundary, so borders do not become hard
    # terrain seams and coastal states can still have natural shorelines.
    var sovereign_state := WORLD_GEOGRAPHY.state_at(pos)
    if String(sovereign_state.get("id", "frontier")) != "frontier":
        var sovereign_center: Vector2 = sovereign_state.get("center", Vector2.ZERO)
        var sovereign_radius: Vector2 = sovereign_state.get("radius", Vector2.ONE)
        var sovereign_dx := (pos.x - sovereign_center.x) / maxf(sovereign_radius.x, 1.0)
        var sovereign_dz := (pos.y - sovereign_center.y) / maxf(sovereign_radius.y, 1.0)
        var sovereign_normalized := sqrt(sovereign_dx * sovereign_dx + sovereign_dz * sovereign_dz)
        var sovereign_weight := 1.0 - smoothstep(0.42, 0.92, sovereign_normalized)
        if sovereign_weight > 0.0:
            var sovereign_floor := lerpf(-3.5, 7.0, sovereign_weight)
            height = maxf(height, sovereign_floor)

    # The canonical mountain federation must read as mountain country at macro
    # scale rather than depending on a lucky noise seed. The added relief blends
    # through the state's ellipse and leaves frontier terrain continuous.
    var state := WORLD_GEOGRAPHY.state_at(pos)
    if String(state.get("id", "")) == "dor_karn":
        var center: Vector2 = state.get("center", Vector2.ZERO)
        var radius: Vector2 = state.get("radius", Vector2.ONE)
        var dx := (pos.x - center.x) / maxf(radius.x, 1.0)
        var dz := (pos.y - center.y) / maxf(radius.y, 1.0)
        var normalized := sqrt(dx * dx + dz * dz)
        var mountain_weight := 1.0 - smoothstep(0.35, 1.0, normalized)
        macro_relief = mountain_weight * 42.0
        height += macro_relief

    # Primary roads are actual graded terrain corridors, not map-only lines.
    # Suppress high-frequency bumps and most ridge noise at the carriageway,
    # then blend through a broad shoulder so traversal stays smooth without a
    # hard trench or political-border seam.
    var road_distance := WORLD_GEOGRAPHY.distance_to_primary_road(pos)
    if road_distance < WORLD_GEOGRAPHY.PRIMARY_ROAD_SHOULDER_WIDTH:
        var road_weight := 1.0 - smoothstep(
            WORLD_GEOGRAPHY.PRIMARY_ROAD_HALF_WIDTH,
            WORLD_GEOGRAPHY.PRIMARY_ROAD_SHOULDER_WIDTH,
            road_distance
        )
        var roadbed := broad + ridges * 0.34 + macro_relief
        height = lerpf(height, roadbed, road_weight * 0.88)

    # The 4 x 4 km Asterna capital remains a stable buildable plateau, but it is
    # deliberately far from the story spawn instead of flattening the origin.
    var city_distance := pos.distance_to(WORLD_GEOGRAPHY.ASTERN_CAPITAL)
    if city_distance < CITY_BLEND_RADIUS:
        var city_factor := smoothstep(CITY_FLAT_RADIUS, CITY_BLEND_RADIUS, city_distance)
        height *= city_factor

    # Freshwater features are physical basins/riverbeds, not map-only markers.
    # The hydrology helper preserves the already-locked prologue river profile
    # and gives existing Lake Vael a stable basin and shoreline.
    height = WORLD_HYDROLOGY.carve_height(pos, height)

    var edge := maxf(absf(pos.x), absf(pos.y)) / WORLD_HALF_SIZE
    if edge > 0.84:
        height -= smoothstep(0.84, 1.0, edge) * 105.0
    return height

func moisture_at(pos: Vector2) -> float:
    var base := clampf(0.5 + moisture_noise.get_noise_2d(pos.x, pos.y) * 0.5, 0.0, 1.0)
    if WORLD_GEOGRAPHY.in_start_region(pos):
        var river_distance := WORLD_GEOGRAPHY.distance_to_start_river(pos)
        if river_distance < 180.0:
            base = maxf(base, lerpf(0.80, base, clampf(river_distance / 180.0, 0.0, 1.0)))

    var lake_normalized := WORLD_HYDROLOGY.lake_normalized_distance(pos)
    if lake_normalized < 1.45:
        base = maxf(base, lerpf(0.86, base, clampf((lake_normalized - 1.0) / 0.45, 0.0, 1.0)))

    var state_id := WORLD_GEOGRAPHY.state_id_at(pos)
    match state_id:
        "liorel": base += 0.24
        "vardheim": base += 0.05
        "saharin": base -= 0.34
        "tarvel": base += 0.18
        "ordan": base -= 0.18
        "kaldera": base -= 0.04
    return clampf(base, 0.0, 1.0)

func temperature_at(pos: Vector2) -> float:
    var latitude := clampf((pos.y + WORLD_HALF_SIZE) / (WORLD_HALF_SIZE * 2.0), 0.0, 1.0)
    var altitude_penalty := maxf(0.0, elevation_at(pos) - 18.0) / 120.0
    var temperature := 0.18 + latitude * 0.72 - altitude_penalty

    var state_id := WORLD_GEOGRAPHY.state_id_at(pos)
    match state_id:
        "vardheim": temperature -= 0.28
        "dor_karn": temperature -= 0.14
        "saharin": temperature += 0.22
        "tarvel": temperature += 0.05
        "ordan": temperature += 0.02
    return clampf(temperature, 0.0, 1.0)

func water_kind_at(pos: Vector2) -> String:
    var freshwater := WORLD_HYDROLOGY.freshwater_kind_at(pos)
    if not freshwater.is_empty():
        return freshwater
    if elevation_at(pos) < SEA_LEVEL - 0.35:
        return "sea"
    return ""

func water_level_at(pos: Vector2) -> float:
    var freshwater := WORLD_HYDROLOGY.freshwater_kind_at(pos)
    if not freshwater.is_empty():
        return WORLD_HYDROLOGY.freshwater_level_at(pos)
    if elevation_at(pos) < SEA_LEVEL - 0.35:
        return SEA_LEVEL
    return -INF

func biome_at(pos: Vector2) -> String:
    var water_kind := water_kind_at(pos)
    var elevation := elevation_at(pos)
    if water_kind == "sea":
        return "underwater" if elevation < SEA_LEVEL - 8.0 else "ocean"
    if water_kind in ["river", "lake"]:
        return "freshwater"

    if elevation < SEA_LEVEL - 2.0:
        return "ocean"

    # The opening chapter is explicitly a forested river region of Asterna.
    # Keep its ecological identity deterministic so story landmarks do not move
    # between noise changes. The actual river cells above are freshwater.
    if WORLD_GEOGRAPHY.in_start_region(pos):
        return "forest"

    var state_id := WORLD_GEOGRAPHY.state_id_at(pos)
    var temperature := temperature_at(pos)
    var moisture := moisture_at(pos)

    if pos.distance_to(Vector2(21600.0, 26000.0)) < 5200.0 and moisture > 0.48:
        return "tropical"
    if temperature < 0.16 or (temperature < 0.26 and elevation > 42.0):
        return "snow"

    # Canonical macro-regions bias biome selection without turning political
    # borders into visible hard biome walls. Noise still controls local variety.
    match state_id:
        "dor_karn":
            if elevation > 26.0:
                return "mountains"
            return "taiga" if moisture > 0.40 else "plains"
        "vardheim":
            if elevation > 48.0:
                return "mountains"
            return "taiga" if moisture > 0.36 else "tundra"
        "liorel":
            if elevation > 58.0:
                return "mountains"
            return "forest"
        "saharin":
            if moisture > 0.62 and elevation < 18.0:
                return "plains"
            return "drylands"
        "ordan":
            if elevation > 55.0:
                return "mountains"
            return "steppe"

    if elevation > 50.0:
        return "mountains"
    if temperature < 0.28:
        return "taiga" if moisture > 0.42 else "tundra"
    if temperature > 0.76 and moisture < 0.38:
        return "drylands"
    if moisture > 0.76 and elevation < 20.0:
        return "marsh"
    if moisture > 0.53:
        return "forest"
    return "plains"

func biome_display_name(biome: String) -> String:
    match biome:
        "ocean": return "Море"
        "underwater": return "Подводный мир"
        "freshwater": return "Пресная вода"
        "tropical": return "Тропики"
        "snow": return "Снежные земли"
        "mountains": return "Горный хребет"
        "taiga": return "Северная тайга"
        "tundra": return "Тундра"
        "drylands": return "Сухие земли"
        "marsh": return "Болота"
        "forest": return "Лес"
        "steppe": return "Степь"
        _: return "Равнины"

func biome_color(biome: String) -> Color:
    match biome:
        "ocean": return Color(0.06, 0.20, 0.31, 1.0)
        "underwater": return Color(0.035, 0.10, 0.16, 1.0)
        "freshwater": return Color(0.08, 0.29, 0.40, 1.0)
        "tropical": return Color(0.08, 0.36, 0.15, 1.0)
        "snow": return Color(0.72, 0.79, 0.82, 1.0)
        "mountains": return Color(0.31, 0.32, 0.33, 1.0)
        "taiga": return Color(0.10, 0.22, 0.17, 1.0)
        "tundra": return Color(0.45, 0.50, 0.48, 1.0)
        "drylands": return Color(0.46, 0.35, 0.20, 1.0)
        "marsh": return Color(0.16, 0.23, 0.14, 1.0)
        "forest": return Color(0.10, 0.27, 0.13, 1.0)
        "steppe": return Color(0.34, 0.39, 0.18, 1.0)
        _: return Color(0.24, 0.36, 0.18, 1.0)

func political_region_at(pos: Vector2) -> Dictionary:
    return WORLD_GEOGRAPHY.state_at(pos)

func state_id_at(pos: Vector2) -> String:
    return WORLD_GEOGRAPHY.state_id_at(pos)

func poi_catalog() -> Array:
    return WORLD_GEOGRAPHY.poi_catalog()

func road_catalog() -> Array:
    return WORLD_GEOGRAPHY.road_catalog()
