extends "res://scripts/world_data.gd"

const GEOGRAPHY_RUNTIME := preload("res://scripts/world_geography.gd")

func biome_at(pos: Vector2) -> String:
    var water_kind := water_kind_at(pos)
    var elevation := elevation_at(pos)
    if water_kind == "sea":
        return "underwater" if elevation < SEA_LEVEL - 8.0 else "ocean"
    if water_kind in ["river", "lake"]:
        return "freshwater"
    if elevation < SEA_LEVEL - 2.0:
        return "ocean"

    if GEOGRAPHY_RUNTIME.in_start_region(pos):
        return "forest"

    var state_id := GEOGRAPHY_RUNTIME.state_id_at(pos)
    var temperature := temperature_at(pos)
    var moisture := moisture_at(pos)

    # Canonical political macro-regions keep their tested identities first.
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

    # Extended world identities only apply outside canonical state anchors.
    if pos.distance_to(Vector2(21600.0, 26000.0)) < 5200.0 and moisture > 0.48:
        return "tropical"
    if temperature < 0.16 or (temperature < 0.26 and elevation > 42.0):
        return "snow"

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
