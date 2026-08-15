class_name WorldHydrology
extends RefCounted

const GEOGRAPHY := preload("res://scripts/world_geography.gd")

# Stable implementation geometry for already-established world features. These
# values are rendering/terrain data, not new story canon.
const LAKE_VAEL_CENTER := Vector2(6200.0, 5200.0)
const LAKE_VAEL_RADIUS := Vector2(620.0, 430.0)
const LAKE_VAEL_WATER_LEVEL := 3.4
const LAKE_VAEL_MAX_DEPTH := 4.8
const LAKE_BANK_BLEND := 90.0

# This matches the existing start_ford POI in world_geography.gd. The ford is
# intentionally still water: traversal is created by a shallow raised bed, not
# by cutting an unrealistic dry gap through the river.
const START_FORD_CENTER := Vector2(180.0, -760.0)
const START_FORD_RADIUS := 46.0
const START_FORD_DEPTH := 0.42
const START_FORD_APPROACH_RADIUS := 96.0

static func lake_normalized_distance(pos: Vector2) -> float:
    var offset := pos - LAKE_VAEL_CENTER
    return sqrt(
        pow(offset.x / LAKE_VAEL_RADIUS.x, 2.0)
        + pow(offset.y / LAKE_VAEL_RADIUS.y, 2.0)
    )

static func in_lake_vael(pos: Vector2) -> bool:
    return lake_normalized_distance(pos) <= 1.0

static func near_lake_vael(pos: Vector2) -> bool:
    var expanded := Vector2(
        LAKE_VAEL_RADIUS.x + LAKE_BANK_BLEND,
        LAKE_VAEL_RADIUS.y + LAKE_BANK_BLEND
    )
    var offset := pos - LAKE_VAEL_CENTER
    var normalized := sqrt(
        pow(offset.x / expanded.x, 2.0)
        + pow(offset.y / expanded.y, 2.0)
    )
    return normalized <= 1.0

static func in_start_ford(pos: Vector2) -> bool:
    return pos.distance_to(START_FORD_CENTER) <= START_FORD_RADIUS \
        and GEOGRAPHY.distance_to_start_river(pos) <= GEOGRAPHY.START_RIVER_HALF_WIDTH

static func crossing_kind_at(pos: Vector2) -> String:
    if in_start_ford(pos):
        return "ford"
    return ""

static func freshwater_kind_at(pos: Vector2) -> String:
    if GEOGRAPHY.in_start_region(pos) \
    and GEOGRAPHY.distance_to_start_river(pos) <= GEOGRAPHY.START_RIVER_HALF_WIDTH:
        return "river"
    if in_lake_vael(pos):
        return "lake"
    return ""

static func freshwater_level_at(pos: Vector2) -> float:
    var kind := freshwater_kind_at(pos)
    if kind == "river":
        return GEOGRAPHY.START_RIVER_WATER_LEVEL
    if kind == "lake":
        return LAKE_VAEL_WATER_LEVEL
    return -INF

static func water_depth_at(pos: Vector2, terrain_height: float) -> float:
    var level := freshwater_level_at(pos)
    if is_inf(level):
        return 0.0
    return maxf(0.0, level - terrain_height)

static func carve_height(pos: Vector2, terrain_height: float) -> float:
    var height := terrain_height

    # Preserve the canonical opening river profile already locked by smoke tests.
    if GEOGRAPHY.in_start_region(pos):
        var river_distance := GEOGRAPHY.distance_to_start_river(pos)
        if river_distance < GEOGRAPHY.START_RIVER_BANK_WIDTH:
            var riverbed_y := GEOGRAPHY.START_RIVER_WATER_LEVEL - 1.55
            var bank_blend := smoothstep(
                GEOGRAPHY.START_RIVER_HALF_WIDTH,
                GEOGRAPHY.START_RIVER_BANK_WIDTH,
                river_distance
            )
            height = lerpf(riverbed_y, height, bank_blend)

            # Raise the existing Old Ford riverbed into a broad shallow shelf.
            # The blend extends onto both approaches so the player does not meet
            # a vertical lip when entering or leaving the crossing.
            var ford_distance := pos.distance_to(START_FORD_CENTER)
            if ford_distance < START_FORD_APPROACH_RADIUS:
                var ford_weight := 1.0 - smoothstep(
                    START_FORD_RADIUS,
                    START_FORD_APPROACH_RADIUS,
                    ford_distance
                )
                var ford_bed := GEOGRAPHY.START_RIVER_WATER_LEVEL - START_FORD_DEPTH
                height = maxf(height, lerpf(height, ford_bed, ford_weight))

    # Lake Vael is an existing POI. Give it a real basin with a shallow littoral
    # shelf and smooth banks instead of leaving a map marker on noisy terrain.
    var normalized := lake_normalized_distance(pos)
    if normalized <= 1.18:
        var edge_weight := 1.0 - smoothstep(0.82, 1.18, normalized)
        var depth_weight := 1.0 - smoothstep(0.0, 0.92, normalized)
        var lakebed := LAKE_VAEL_WATER_LEVEL - lerpf(1.15, LAKE_VAEL_MAX_DEPTH, depth_weight)
        height = lerpf(height, lakebed, edge_weight)

    return height
