extends Node

signal explored_changed

const CELL_SIZE := 256.0
const REVEAL_RADIUS := 1
const STATE_KEY := "map_explored_v2"
const FEATURES_KEY := "map_features_v1"

var player: Node3D
var last_cell := Vector2i(999999, 999999)
var feature_elapsed := 0.0
var dynamic_features: Array[Dictionary] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
    if not is_instance_valid(player) or not player.is_inside_tree():
        player = get_tree().get_first_node_in_group("player") as Node3D
        if not is_instance_valid(player) or not player.is_inside_tree():
            return
        last_cell = Vector2i(999999, 999999)
    var world := Vector2(player.global_position.x, player.global_position.z)
    var cell := world_to_cell(world)
    if cell != last_cell:
        last_cell = cell
        reveal_around(cell)
    feature_elapsed += delta
    if feature_elapsed >= 0.75:
        feature_elapsed = 0.0
        refresh_features()

func refresh_features() -> void:
    var saved: Dictionary = GameState.get_world_value(FEATURES_KEY, {})
    for group in ["map_tree", "map_building", "enterable_building", "map_fixture"]:
        for node: Node3D in get_tree().get_nodes_in_group(group):
            var position := Vector2(node.global_position.x, node.global_position.z)
            var footprint: Vector2 = node.get_meta("map_footprint", Vector2(8, 8))
            var kind := "tree" if group == "map_tree" else "fixture" if group == "map_fixture" else "building"
            _remember_feature(saved, position, kind, footprint, node.global_rotation.y)
    for batch: Node3D in get_tree().get_nodes_in_group("map_tree_batch"):
        for local_position: Vector3 in batch.get_meta("map_tree_positions", []):
            var world := batch.to_global(local_position)
            _remember_feature(saved, Vector2(world.x, world.z), "tree", Vector2(5, 5), 0.0)
    for batch: Node3D in get_tree().get_nodes_in_group("map_rock_batch"):
        for local_position: Vector3 in batch.get_meta("map_rock_positions", []):
            var world := batch.to_global(local_position)
            _remember_feature(saved, Vector2(world.x, world.z), "rock", Vector2(3, 3), 0.0)
    GameState.set_world_value(FEATURES_KEY, saved)
    dynamic_features.clear()
    var seen: Dictionary = {}
    for group in ["hostile", "ally", "settlement_npc", "city_npc", "map_resource"]:
        for node: Node3D in get_tree().get_nodes_in_group(group):
            if node.is_queued_for_deletion() or seen.has(node.get_instance_id()):
                continue
            if group == "hostile" and float(node.get("health")) <= 0:
                continue
            if group == "map_resource" and int(node.get("uses")) <= 0:
                continue
            seen[node.get_instance_id()] = true
            var position := Vector2(node.global_position.x, node.global_position.z)
            if is_world_explored(position):
                var kind: String = "resource" if group == "map_resource" else String(group) if group in ["hostile", "ally"] else "npc"
                dynamic_features.append({"pos": [position.x, position.y], "kind": kind})

func _remember_feature(saved: Dictionary, position: Vector2, kind: String, footprint: Vector2, yaw: float) -> void:
    if not is_world_explored(position):
        return
    var cell := _cell_key(world_to_cell(position))
    if not saved.has(cell):
        saved[cell] = {}
    var key := "%s:%d:%d" % [kind, roundi(position.x * 0.5), roundi(position.y * 0.5)]
    saved[cell][key] = {"pos": [position.x, position.y], "kind": kind, "size": [footprint.x, footprint.y], "yaw": yaw}

func features_near(center: Vector2, radius: float) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var saved: Dictionary = GameState.get_world_value(FEATURES_KEY, {})
    var minimum := world_to_cell(center - Vector2.ONE * radius)
    var maximum := world_to_cell(center + Vector2.ONE * radius)
    for x in range(minimum.x, maximum.x + 1):
        for z in range(minimum.y, maximum.y + 1):
            var bucket: Dictionary = saved.get(_cell_key(Vector2i(x, z)), {})
            for feature: Dictionary in bucket.values():
                var position := Vector2(float(feature.pos[0]), float(feature.pos[1]))
                # Old map saves retain discovered canopy footprints after their
                # streaming cell unloads. Resolve felling from persistent world
                # state even when no live tree node is present.
                if String(feature.get("kind", "")) == "tree":
                    var id_value := "forest:%d:%d" % [roundi(position.x * 1000), roundi(position.y * 1000)]
                    if bool(GameState.get_world_value("tree_fallen:" + id_value, false)):
                        if absf(position.x - center.x) <= radius and absf(position.y - center.y) <= radius:
                            var stump := feature.duplicate(true)
                            stump.kind = "stump"
                            stump.size = [0.8, 0.8]
                            result.append(stump)
                        continue
                if absf(position.x - center.x) <= radius and absf(position.y - center.y) <= radius:
                    result.append(feature)
    for feature: Dictionary in dynamic_features:
        var position := Vector2(float(feature.pos[0]), float(feature.pos[1]))
        if absf(position.x - center.x) <= radius and absf(position.y - center.y) <= radius:
            result.append(feature)
    return result

func terrain_color(world: Vector2, pixel_width: float = 8.0) -> Color:
    if not is_world_explored(world):
        return Color(0.025, 0.035, 0.035)
    var height := WorldData.elevation_at(world)
    var water := WorldData.water_level_at(world)
    if not is_inf(water) and water >= height - 0.02:
        return Color(0.12, 0.34, 0.43).darkened(clampf((water - height) * 0.025, 0.0, 0.25))
    var shade := clampf((WorldData.elevation_at(world + Vector2(-8, 0)) - WorldData.elevation_at(world + Vector2(0, -8))) * 0.035, -0.26, 0.22)
    var color := WorldData.biome_color(WorldData.biome_at(world)).lerp(Color(0.48, 0.43, 0.32), 0.28)
    color = color.lightened(shade) if shade > 0 else color.darkened(-shade)
    if WorldGeography.distance_to_primary_road(world) < maxf(4.2, pixel_width * 0.45):
        color = Color(0.53, 0.44, 0.29)
    if CapitalData.inside_capital(world):
        var local := world - CapitalData.CENTER
        # Match the streamed 160 m city cells, whose roads cross their centers.
        var distance := minf(absf(wrapf(local.x, -80.0, 80.0)), absf(wrapf(local.y, -80.0, 80.0)))
        color = Color(0.46, 0.43, 0.36)
        if distance < maxf(7.0, pixel_width * 0.45):
            color = Color(0.23, 0.22, 0.20)
    return color

func world_to_cell(world_pos: Vector2) -> Vector2i:
    return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))

func cell_to_world_center(cell: Vector2i) -> Vector2:
    return Vector2((float(cell.x) + 0.5) * CELL_SIZE, (float(cell.y) + 0.5) * CELL_SIZE)

func reveal_around(center: Vector2i, radius: int = REVEAL_RADIUS) -> void:
    var explored := _explored_dictionary()
    var changed := false
    for x in range(center.x - radius, center.x + radius + 1):
        for y in range(center.y - radius, center.y + radius + 1):
            var cell := Vector2i(x, y)
            var world := cell_to_world_center(cell)
            if not WorldData.inside_world(world):
                continue
            if Vector2(x - center.x, y - center.y).length() > float(radius) + 0.35:
                continue
            var key := _cell_key(cell)
            if not explored.has(key):
                explored[key] = true
                changed = true
    if changed:
        GameState.set_world_value(STATE_KEY, explored)
        explored_changed.emit()

func is_cell_explored(cell: Vector2i) -> bool:
    return _explored_dictionary().has(_cell_key(cell))

func is_world_explored(world_pos: Vector2) -> bool:
    return is_cell_explored(world_to_cell(world_pos))

func explored_cells() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for key in _explored_dictionary().keys():
        var parts := String(key).split(":")
        if parts.size() == 2:
            result.append(Vector2i(int(parts[0]), int(parts[1])))
    return result

func explored_percent() -> float:
    var width := WorldData.WORLD_MAX.x - WorldData.WORLD_MIN.x
    var height := WorldData.WORLD_MAX.y - WorldData.WORLD_MIN.y
    var columns := int(ceil(width / CELL_SIZE))
    var rows := int(ceil(height / CELL_SIZE))
    var total := maxi(1, columns * rows)
    return clampf(float(_explored_dictionary().size()) / float(total) * 100.0, 0.0, 100.0)

func explored_area_km2() -> float:
    return float(_explored_dictionary().size()) * CELL_SIZE * CELL_SIZE / 1000000.0

func _explored_dictionary() -> Dictionary:
    var saved = GameState.get_world_value(STATE_KEY, {})
    if typeof(saved) == TYPE_DICTIONARY:
        return saved
    return {}

func _cell_key(cell: Vector2i) -> String:
    return "%d:%d" % [cell.x, cell.y]
