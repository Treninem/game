extends Node

const CARTOGRAPHY := preload("res://scripts/local_map_renderer.gd")
var failures: Array[String] = []

func _ready() -> void:
    GameState.reset_new_game()
    var world := Node3D.new()
    add_child(world)
    var origin := Vector2(65, 48)
    MapSystem.reveal_around(MapSystem.world_to_cell(origin), 2)
    var house := Node3D.new()
    house.position = Vector3(85, 2, 48)
    house.add_to_group("map_building")
    house.set_meta("map_footprint", Vector2(12, 8))
    world.add_child(house)
    var tree := Node3D.new()
    tree.position = Vector3(75, 2, 48)
    tree.add_to_group("map_tree")
    world.add_child(tree)
    var rocks := Node3D.new()
    rocks.add_to_group("map_rock_batch")
    rocks.set_meta("map_rock_positions", [Vector3(80, 2, 60)])
    world.add_child(rocks)
    var ally := Node3D.new()
    ally.position = Vector3(65, 2, 58)
    ally.add_to_group("ally")
    world.add_child(ally)
    MapSystem.refresh_features()
    var kinds: Array = MapSystem.features_near(origin, 100).map(func(feature): return feature.kind)
    for kind in ["building", "tree", "ally", "rock"]:
        if kind not in kinds:
            failures.append("Map omits a real nearby %s" % kind)
    var rectangle := Rect2(0, 0, 200, 200)
    if CARTOGRAPHY.project(rectangle, origin, 100, origin + Vector2(0, -10)).y >= 100:
        failures.append("North is inverted on the local map")
    if CARTOGRAPHY.project(rectangle, origin, 100, origin + Vector2(10, 0)).x <= 100:
        failures.append("East is inverted on the local map")
    house.queue_free()
    ally.queue_free()
    await get_tree().process_frame
    MapSystem.refresh_features()
    kinds = MapSystem.features_near(origin, 100).map(func(feature): return feature.kind)
    if "building" not in kinds:
        failures.append("Discovered building disappears when its cell unloads")
    if "ally" in kinds:
        failures.append("Map retains a stale living actor after removal")
    var saved := JSON.stringify(GameState.get_world_value(MapSystem.FEATURES_KEY, {}))
    var restored = JSON.parse_string(saved)
    GameState.set_world_value(MapSystem.FEATURES_KEY, restored)
    if MapSystem.features_near(origin, 100).is_empty():
        failures.append("Map feature data does not survive save serialization")
    GameState.set_world_value("tree_fallen:forest:75000:48000", true)
    MapSystem.refresh_features()
    kinds = MapSystem.features_near(origin, 100).map(func(feature): return feature.kind)
    if "tree" in kinds or "building" not in kinds:
        failures.append("Felling leaves a standing-tree footprint or removes a building")
    if "stump" not in kinds or "rock" not in kinds:
        failures.append("Map loses felled stump or actual boulder footprint")
    tree.free()
    var snapshot = JSON.parse_string(JSON.stringify(GameState.world_state))
    GameState.world_state = snapshot
    MapSystem.refresh_features()
    kinds = MapSystem.features_near(origin, 100).map(func(feature): return feature.kind)
    if "tree" in kinds or "building" not in kinds:
        failures.append("Felled canopy returns after unloading and save round-trip")
    var unknown := Vector2(15000, 15000)
    if MapSystem.terrain_color(unknown).get_luminance() > 0.1:
        failures.append("Map reveals unexplored terrain")
    MapSystem.reveal_around(MapSystem.world_to_cell(CapitalData.CENTER), 2)
    if MapSystem.terrain_color(CapitalData.CENTER).get_luminance() >= MapSystem.terrain_color(CapitalData.CENTER + Vector2(40, 40)).get_luminance():
        failures.append("Map omits the streamed capital streets")
    if failures.is_empty():
        print("CARTOGRAPHY_OK north=correct objects=real unloaded_buildings=remembered living_actors=live save=roundtrip fog=preserved")
    for failure in failures:
        push_error(failure)
    get_tree().quit(0 if failures.is_empty() else 1)
