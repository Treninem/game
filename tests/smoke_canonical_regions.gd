extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")

func _ready() -> void:
    await get_tree().process_frame
    var failures: Array[String] = []

    if GEOGRAPHY.STATES.size() != 8:
        failures.append("Expected exactly eight canonical major states, got %d" % GEOGRAPHY.STATES.size())

    for state in GEOGRAPHY.STATES:
        var expected_id := String(state.get("id", ""))
        var center: Vector2 = state.get("center", Vector2.ZERO)
        var actual_id := WorldData.state_id_at(center)
        if actual_id != expected_id:
            failures.append("State center mismatch: %s resolved as %s" % [expected_id, actual_id])

    if WorldData.biome_at(GEOGRAPHY.START_SPAWN) != "forest":
        failures.append("Asterna prologue spawn must remain forest")

    var vardheim := Vector2(1500.0, -23500.0)
    var liorel := Vector2(-22500.0, -3500.0)
    var dor_karn := Vector2(-13500.0, -20500.0)
    var saharin := Vector2(9000.0, 22500.0)
    var ordan := Vector2(-10500.0, 20500.0)

    var vardheim_biome := WorldData.biome_at(vardheim)
    if vardheim_biome not in ["taiga", "tundra", "mountains"]:
        failures.append("Vardheim lost its cold-region biome: %s" % vardheim_biome)

    var liorel_biome := WorldData.biome_at(liorel)
    if liorel_biome not in ["forest", "mountains"]:
        failures.append("Liorel lost its old-forest identity: %s" % liorel_biome)

    var dor_karn_biome := WorldData.biome_at(dor_karn)
    if dor_karn_biome not in ["mountains", "taiga", "plains"]:
        failures.append("Dor-Karn resolved to invalid macro biome: %s" % dor_karn_biome)

    var saharin_biome := WorldData.biome_at(saharin)
    if saharin_biome not in ["drylands", "plains"]:
        failures.append("Saharin lost its arid identity: %s" % saharin_biome)

    var ordan_biome := WorldData.biome_at(ordan)
    if ordan_biome not in ["steppe", "mountains"]:
        failures.append("Ordan lost its steppe identity: %s" % ordan_biome)

    if WorldData.moisture_at(liorel) <= WorldData.moisture_at(saharin):
        failures.append("Liorel must remain wetter than Saharin")
    if WorldData.temperature_at(vardheim) >= WorldData.temperature_at(saharin):
        failures.append("Vardheim must remain colder than Saharin")

    var river_center := Vector2(GEOGRAPHY.start_river_x(0.0), 0.0)
    var river_height := WorldData.elevation_at(river_center)
    if absf(river_height - (GEOGRAPHY.START_RIVER_WATER_LEVEL - 1.55)) > 0.15:
        failures.append("Prologue river bed carving moved unexpectedly: %.3f" % river_height)

    if failures.is_empty():
        print("CANONICAL_REGIONS_SMOKE_OK states=8 start=forest climates=locked river=stable")
        get_tree().quit(0)
        return

    for failure in failures:
        push_error(failure)
    get_tree().quit(1)