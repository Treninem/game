class_name WorldGeography
extends RefCounted

# Canonical first-continent geography derived from story/CANON.md and
# story/world/00_WORLD_CORE.md. Coordinates are stable world-space anchors so
# future settlement, road, quest and political work does not require moving the
# whole world again.

const START_SPAWN := Vector2(-72.0, 48.0)
const ASTERN_CAPITAL := Vector2(13500.0, -7000.0)
const START_REGION_RADIUS := 1800.0
const START_RIVER_HALF_WIDTH := 26.0
const START_RIVER_BANK_WIDTH := 72.0
const START_RIVER_WATER_LEVEL := 1.2

const STATES := [
    {"id":"astern", "name":"Королевство Астэрн", "center":Vector2(6500, -1000), "radius":Vector2(11500, 12000), "culture":"human_feudal", "climate":"temperate"},
    {"id":"vardheim", "name":"Северный союз Вардхейм", "center":Vector2(1500, -23500), "radius":Vector2(11500, 8500), "culture":"northern_union", "climate":"cold"},
    {"id":"liorel", "name":"Лесной доминион Лиорель", "center":Vector2(-22500, -3500), "radius":Vector2(9000, 13500), "culture":"elven_woodland", "climate":"humid_forest"},
    {"id":"dor_karn", "name":"Горные королевства Дор-Карн", "center":Vector2(-13500, -20500), "radius":Vector2(9000, 8500), "culture":"dwarven_holds", "climate":"mountain"},
    {"id":"saharin", "name":"Султанаты Сахарин", "center":Vector2(9000, 22500), "radius":Vector2(13000, 8500), "culture":"desert_trade", "climate":"arid"},
    {"id":"tarvel", "name":"Морская лига Тарвель", "center":Vector2(24500, 11500), "radius":Vector2(8000, 13000), "culture":"maritime_league", "climate":"coastal"},
    {"id":"kaldera", "name":"Империя Кальдера", "center":Vector2(24500, -10500), "radius":Vector2(8500, 12500), "culture":"imperial", "climate":"continental"},
    {"id":"ordan", "name":"Степная конфедерация Ордан", "center":Vector2(-10500, 20500), "radius":Vector2(14500, 9000), "culture":"steppe_confederation", "climate":"steppe"}
]

# The starting region is deliberately modest and rural. The first fortified
# town is reachable on foot but the royal capital remains far away, matching the
# prologue. Names outside explicit story canon are implementation placeholders
# and can be replaced by the story chat without moving their coordinates.
const POIS := [
    {"id":"start_river", "name":"Лесная река", "pos":Vector2(110, 40), "kind":"river", "state":"astern", "visibility":"local"},
    {"id":"start_ford", "name":"Старый брод", "pos":Vector2(180, -760), "kind":"ford", "state":"astern", "visibility":"local"},
    {"id":"border_village_01", "name":"Пограничная деревня", "pos":Vector2(1650, -420), "kind":"village", "state":"astern", "visibility":"regional"},
    {"id":"border_village_02", "name":"Речная деревня", "pos":Vector2(-1350, 1180), "kind":"village", "state":"astern", "visibility":"regional"},
    {"id":"first_fortified_town", "name":"Укреплённый город Астэрна", "pos":Vector2(3650, -1750), "kind":"fortified_town", "state":"astern", "visibility":"regional"},
    {"id":"lumengrad", "name":"Люменград", "pos":ASTERN_CAPITAL, "kind":"capital", "state":"astern", "visibility":"continental"},
    {"id":"vardheim_capital", "name":"Столица Вардхейма", "pos":Vector2(1200, -24800), "kind":"capital", "state":"vardheim", "visibility":"continental"},
    {"id":"liorel_capital", "name":"Главный город Лиореля", "pos":Vector2(-23800, -4200), "kind":"capital", "state":"liorel", "visibility":"continental"},
    {"id":"dor_karn_capital", "name":"Королевский чертог Дор-Карна", "pos":Vector2(-14200, -21700), "kind":"capital", "state":"dor_karn", "visibility":"continental"},
    {"id":"saharin_capital", "name":"Главный город Сахарина", "pos":Vector2(9800, 23600), "kind":"capital", "state":"saharin", "visibility":"continental"},
    {"id":"tarvel_capital", "name":"Главный порт Тарвеля", "pos":Vector2(25400, 12400), "kind":"capital", "state":"tarvel", "visibility":"continental"},
    {"id":"kaldera_capital", "name":"Столица Кальдеры", "pos":Vector2(25400, -11200), "kind":"capital", "state":"kaldera", "visibility":"continental"},
    {"id":"ordan_capital", "name":"Сезонная столица Ордана", "pos":Vector2(-9800, 21400), "kind":"capital", "state":"ordan", "visibility":"continental"},
    {"id":"north_pass", "name":"Северный перевал", "pos":Vector2(-3500, -15500), "kind":"mountain", "state":"frontier", "visibility":"continental"},
    {"id":"lake_vael", "name":"Озеро Ваэль", "pos":Vector2(6200, 5200), "kind":"lake", "state":"astern", "visibility":"regional"},
    {"id":"whisper_marsh", "name":"Шепчущие болота", "pos":Vector2(-6300, 6400), "kind":"marsh", "state":"frontier", "visibility":"regional"},
    {"id":"red_canyon", "name":"Красный каньон", "pos":Vector2(12100, 12100), "kind":"danger", "state":"frontier", "visibility":"regional"},
    {"id":"old_mines", "name":"Старые королевские шахты", "pos":Vector2(-6200, -9100), "kind":"mine", "state":"frontier", "visibility":"regional"},
    {"id":"western_forest", "name":"Западный древний лес", "pos":Vector2(-16500, -1500), "kind":"forest", "state":"liorel", "visibility":"continental"},
    {"id":"south_isles", "name":"Южный архипелаг", "pos":Vector2(21600, 26000), "kind":"coast", "state":"tarvel", "visibility":"continental"}
]

const PRIMARY_ROADS := [
    {"id":"astern_border_road", "state":"astern", "points":[Vector2(1550,-420), Vector2(2450,-900), Vector2(3650,-1750), Vector2(7200,-3300), ASTERN_CAPITAL]},
    {"id":"astern_river_track", "state":"astern", "points":[Vector2(-1350,1180), Vector2(-500,620), Vector2(650,120), Vector2(1650,-420)]},
    {"id":"north_trade_road", "state":"frontier", "points":[ASTERN_CAPITAL, Vector2(8500,-11200), Vector2(2600,-16500), Vector2(1200,-24800)]},
    {"id":"western_trade_road", "state":"frontier", "points":[Vector2(1650,-420), Vector2(-6500,-2200), Vector2(-14500,-3500), Vector2(-23800,-4200)]},
    {"id":"imperial_road", "state":"frontier", "points":[ASTERN_CAPITAL, Vector2(18500,-8200), Vector2(25400,-11200)]},
    {"id":"southern_caravan_road", "state":"frontier", "points":[Vector2(3650,-1750), Vector2(6500,6000), Vector2(8000,14500), Vector2(9800,23600)]}
]

static func start_spawn() -> Vector2:
    return START_SPAWN

static func capital_position() -> Vector2:
    return ASTERN_CAPITAL

static func start_river_x(z: float) -> float:
    return 115.0 + sin(z / 310.0) * 68.0 + sin(z / 93.0) * 13.0

static func distance_to_start_river(pos: Vector2) -> float:
    return absf(pos.x - start_river_x(pos.y))

static func in_start_region(pos: Vector2) -> bool:
    return pos.distance_to(START_SPAWN) <= START_REGION_RADIUS

static func state_at(pos: Vector2) -> Dictionary:
    var best: Dictionary = {}
    var best_score := INF
    for state in STATES:
        var center: Vector2 = state.get("center", Vector2.ZERO)
        var radius: Vector2 = state.get("radius", Vector2.ONE)
        var dx := (pos.x - center.x) / maxf(radius.x, 1.0)
        var dz := (pos.y - center.y) / maxf(radius.y, 1.0)
        var score := dx * dx + dz * dz
        if score < best_score:
            best_score = score
            best = state
    if best_score > 1.0:
        return {"id":"frontier", "name":"Свободные и спорные земли", "culture":"mixed", "climate":"mixed"}
    return best.duplicate(true)

static func state_id_at(pos: Vector2) -> String:
    return String(state_at(pos).get("id", "frontier"))

static func poi_catalog() -> Array:
    return POIS.duplicate(true)

static func road_catalog() -> Array:
    return PRIMARY_ROADS.duplicate(true)
