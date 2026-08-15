extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const CAPITAL := preload("res://scripts/capital_data.gd")

func _ready() -> void:
    print("CANONICAL_REGIONS_SMOKE_START")
    var failures: Array[String] = []

    if GEOGRAPHY.STATES.size() != 8:
        failures.append("Expected exactly eight canonical major states, got %d" % GEOGRAPHY.STATES.size())

    for state in GEOGRAPHY.STATES:
        var expected_id := String(state.get("id", ""))
        var center: Vector2 = state.get("center", Vector2.ZERO)
        var actual_id := WorldData.state_id_at(center)
        if actual_id != expected_id:
            failures.append("State center mismatch: %s resolved as %s" % [expected_id, actual_id])

    print("CANONICAL_REGIONS_SMOKE_STAGE political")

    if CAPITAL.CENTER != GEOGRAPHY.ASTERN_CAPITAL:
        failures.append("CapitalData.CENTER must follow the canonical Asterna capital anchor")
    if CAPITAL.CENTER == Vector2.ZERO:
        failures.append("Asterna capital must stay far from the prologue origin")
    if CAPITAL.CENTER.distance_to(GEOGRAPHY.START_SPAWN) < 5000.0:
        failures.append("Asterna capital drifted too close to the prologue region")

    var central_district := CAPITAL.district_at(CAPITAL.CENTER)
    if String(central_district.get("id", "")) != "central":
        failures.append("Capital center no longer resolves to the central district")
    var central_world: Vector2 = central_district.get("center", Vector2.ZERO)
    if central_world != CAPITAL.CENTER:
        failures.append("Capital district coordinates must resolve in world space")

    print("CANONICAL_REGIONS_SMOKE_STAGE capital")

    print("CANONICAL_REGIONS_PROBE start_spawn begin")
    var start_biome := WorldData.biome_at(GEOGRAPHY.START_SPAWN)
    print("CANONICAL_REGIONS_PROBE start_spawn end biome=%s" % start_biome)
    if start_biome != "forest":
        failures.append("Asterna prologue spawn must remain forest")

    var vardheim := Vector2(1500.0, -23500.0)
    var liorel := Vector2(-22500.0, -3500.0)
    var dor_karn := Vector2(-13500.0, -20500.0)
    var saharin := Vector2(9000.0, 22500.0)
    var ordan := Vector2(-10500.0, 20500.0)

    print("CANONICAL_REGIONS_PROBE vardheim begin")
    var vardheim_biome := WorldData.biome_at(vardheim)
    print("CANONICAL_REGIONS_PROBE vardheim end biome=%s" % vardheim_biome)
    if vardheim_biome not in ["taiga", "tundra", "mountains"]:
        failures.append("Vardheim lost its cold-region biome: %s" % vardheim_biome)

    print("CANONICAL_REGIONS_PROBE liorel begin")
    var liorel_biome := WorldData.biome_at(liorel)
    print("CANONICAL_REGIONS_PROBE liorel end biome=%s" % liorel_biome)
    if liorel_biome not in ["forest", "mountains"]:
        failures.append("Liorel lost its old-forest identity: %s" % liorel_biome)

    print("CANONICAL_REGIONS_PROBE dor_karn begin")
    var dor_karn_biome := WorldData.biome_at(dor_karn)
    print("CANONICAL_REGIONS_PROBE dor_karn end biome=%s" % dor_karn_biome)
    if dor_karn_biome not in ["mountains", "taiga", "plains"]:
        failures.append("Dor-Karn resolved to invalid macro biome: %s" % dor_karn_biome)

    print("CANONICAL_REGIONS_PROBE saharin begin")
    var saharin_biome := WorldData.biome_at(saharin)
    print("CANONICAL_REGIONS_PROBE saharin end biome=%s" % saharin_biome)
    if saharin_biome not in ["drylands", "plains"]:
        failures.append("Saharin lost its arid identity: %s" % saharin_biome)

    print("CANONICAL_REGIONS_PROBE ordan begin")
    var ordan_biome := WorldData.biome_at(ordan)
    print("CANONICAL_REGIONS_PROBE ordan end biome=%s" % ordan_biome)
    if ordan_biome not in ["steppe", "mountains"]:
        failures.append("Ordan lost its steppe identity: %s" % ordan_biome)

    print("CANONICAL_REGIONS_PROBE moisture begin")
    var liorel_moisture := WorldData.moisture_at(liorel)
    var saharin_moisture := WorldData.moisture_at(saharin)
    print("CANONICAL_REGIONS_PROBE moisture end liorel=%.4f saharin=%.4f" % [liorel_moisture, saharin_moisture])
    if liorel_moisture <= saharin_moisture:
        failures.append("Liorel must remain wetter than Saharin")

    print("CANONICAL_REGIONS_PROBE temperature begin")
    var vardheim_temperature := WorldData.temperature_at(vardheim)
    var saharin_temperature := WorldData.temperature_at(saharin)
    print("CANONICAL_REGIONS_PROBE temperature end vardheim=%.4f saharin=%.4f" % [vardheim_temperature, saharin_temperature])
    if vardheim_temperature >= saharin_temperature:
        failures.append("Vardheim must remain colder than Saharin")

    print("CANONICAL_REGIONS_SMOKE_STAGE climate")

    var river_center := Vector2(GEOGRAPHY.start_river_x(0.0), 0.0)
    var river_height := WorldData.elevation_at(river_center)
    if absf(river_height - (GEOGRAPHY.START_RIVER_WATER_LEVEL - 1.55)) > 0.15:
        failures.append("Prologue river bed carving moved unexpectedly: %.3f" % river_height)

    if failures.is_empty():
        print("CANONICAL_REGIONS_SMOKE_OK states=8 start=forest capital=anchored climates=locked river=stable")
        get_tree().quit(0)
        return

    for failure in failures:
        push_error(failure)
    get_tree().quit(1)
