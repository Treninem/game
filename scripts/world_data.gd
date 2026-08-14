extends Node

const WORLD_HALF_SIZE := 32000.0
const WORLD_MIN := Vector2(-WORLD_HALF_SIZE, -WORLD_HALF_SIZE)
const WORLD_MAX := Vector2(WORLD_HALF_SIZE, WORLD_HALF_SIZE)
const SEA_LEVEL := 0.0
const CITY_FLAT_RADIUS := 420.0
const CITY_BLEND_RADIUS := 900.0
const WORLD_SEED := 260814

const POIS := [
    {"id": "lumengrad", "name": "Люменград", "pos": Vector2(0, -36), "kind": "capital"},
    {"id": "north_pass", "name": "Северный перевал", "pos": Vector2(1200, -11800), "kind": "mountain"},
    {"id": "pinewatch", "name": "Сосновый дозор", "pos": Vector2(-8600, -7200), "kind": "settlement"},
    {"id": "lake_vael", "name": "Озеро Ваэль", "pos": Vector2(5200, -6900), "kind": "lake"},
    {"id": "whisper_marsh", "name": "Шепчущие болота", "pos": Vector2(-9200, 5200), "kind": "marsh"},
    {"id": "red_canyon", "name": "Красный каньон", "pos": Vector2(10800, 7600), "kind": "danger"},
    {"id": "old_mines", "name": "Старые королевские шахты", "pos": Vector2(-3500, 9600), "kind": "mine"},
    {"id": "sun_coast", "name": "Солнечное побережье", "pos": Vector2(13800, 15400), "kind": "coast"},
    {"id": "frost_ruins", "name": "Руины ледяной башни", "pos": Vector2(-4300, -18400), "kind": "ruin"},
    {"id": "ashen_peak", "name": "Пепельная вершина", "pos": Vector2(14200, -12200), "kind": "danger"},
    {"id": "western_forest", "name": "Западный древний лес", "pos": Vector2(-15800, -1200), "kind": "forest"},
    {"id": "south_isles", "name": "Южный архипелаг", "pos": Vector2(-2400, 23600), "kind": "coast"}
]

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
    var height := broad + detail + ridges

    var city_distance := pos.length()
    if city_distance < CITY_BLEND_RADIUS:
        var city_factor := smoothstep(CITY_FLAT_RADIUS, CITY_BLEND_RADIUS, city_distance)
        height *= city_factor

    var edge := maxf(absf(pos.x), absf(pos.y)) / WORLD_HALF_SIZE
    if edge > 0.84:
        height -= smoothstep(0.84, 1.0, edge) * 105.0
    return height

func moisture_at(pos: Vector2) -> float:
    return clampf(0.5 + moisture_noise.get_noise_2d(pos.x, pos.y) * 0.5, 0.0, 1.0)

func temperature_at(pos: Vector2) -> float:
    var latitude := clampf((pos.y + WORLD_HALF_SIZE) / (WORLD_HALF_SIZE * 2.0), 0.0, 1.0)
    var altitude_penalty := maxf(0.0, elevation_at(pos) - 18.0) / 120.0
    return clampf(0.18 + latitude * 0.72 - altitude_penalty, 0.0, 1.0)

func biome_at(pos: Vector2) -> String:
    var elevation := elevation_at(pos)
    if elevation < SEA_LEVEL - 2.0:
        return "ocean"
    if elevation > 50.0:
        return "mountains"
    var temperature := temperature_at(pos)
    var moisture := moisture_at(pos)
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
        "mountains": return "Горный хребет"
        "taiga": return "Северная тайга"
        "tundra": return "Тундра"
        "drylands": return "Сухие земли"
        "marsh": return "Болота"
        "forest": return "Лес"
        _: return "Равнины"

func biome_color(biome: String) -> Color:
    match biome:
        "ocean": return Color(0.06, 0.20, 0.31, 1.0)
        "mountains": return Color(0.31, 0.32, 0.33, 1.0)
        "taiga": return Color(0.10, 0.22, 0.17, 1.0)
        "tundra": return Color(0.45, 0.50, 0.48, 1.0)
        "drylands": return Color(0.46, 0.35, 0.20, 1.0)
        "marsh": return Color(0.16, 0.23, 0.14, 1.0)
        "forest": return Color(0.10, 0.27, 0.13, 1.0)
        _: return Color(0.24, 0.36, 0.18, 1.0)

func poi_catalog() -> Array:
    return POIS.duplicate(true)
