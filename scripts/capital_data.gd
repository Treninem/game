class_name CapitalData
extends RefCounted

const WORLD_GEOGRAPHY := preload("res://scripts/world_geography.gd")

# Canonical capital geometry from the master specification. District and gate
# coordinates below remain local to the city, while CENTER places the whole
# 4 x 4 km capital far from the prologue region as required by story canon.
const CENTER := WORLD_GEOGRAPHY.ASTERN_CAPITAL
const HALF_EXTENT := 2000.0
const WALL_HEIGHT := 18.0
const WALL_THICKNESS := 8.0
const GATE_OPENING := 22.0
const GATE_TOWER_SIZE := 18.0
const DEFENSE_BELT := 125.0
const GATE_OPEN_MINUTE := 6 * 60
const GATE_CLOSE_MINUTE := 21 * 60
const GATES_PER_SIDE := 8
const TOTAL_GATES := 32

const GATE_OFFSETS := [-1750.0, -1250.0, -750.0, -250.0, 250.0, 750.0, 1250.0, 1750.0]

const NORTH_GATE_NAMES := [
    "Ворота Ледяного Пика", "Ворота Соснового Дозора", "Ворота Серебряной Дороги", "Ворота Рассветной Башни",
    "Ворота Белого Оленя", "Ворота Северного Тракта", "Ворота Высокого Камня", "Ворота Звёздного Моста"
]
const EAST_GATE_NAMES := [
    "Ворота Солнечного Тракта", "Ворота Янтарного Рынка", "Ворота Речной Дуги", "Ворота Кузнечных Огней",
    "Ворота Гильдейского Пути", "Ворота Сапфировой Башни", "Ворота Караванов", "Ворота Восточного Порта"
]
const SOUTH_GATE_NAMES := [
    "Ворота Золотых Полей", "Ворота Южного Тракта", "Ворота Паломников", "Ворота Конного Двора",
    "Ворота Арены", "Ворота Садов", "Ворота Красного Знамени", "Ворота Тёплого Ветра"
]
const WEST_GATE_NAMES := [
    "Ворота Древнего Леса", "Ворота Охотников", "Ворота Старого Камня", "Ворота Шахтёров",
    "Ворота Лесопилки", "Ворота Сумерек", "Ворота Озёрного Пути", "Ворота Западного Дозора"
]

const DISTRICTS := [
    {"id":"starter", "name":"Стартовая площадь", "center":Vector2(0, 1500), "size":Vector2(520, 360)},
    {"id":"central", "name":"Центральная площадь", "center":Vector2(0, 0), "size":Vector2(520, 520)},
    {"id":"market", "name":"Большой рынок", "center":Vector2(-520, 280), "size":Vector2(620, 520)},
    {"id":"crafts", "name":"Ремесленный квартал", "center":Vector2(560, 260), "size":Vector2(620, 540)},
    {"id":"old_town", "name":"Старый и бедный квартал", "center":Vector2(-1200, 720), "size":Vector2(760, 760)},
    {"id":"residential", "name":"Жилой квартал", "center":Vector2(1120, 760), "size":Vector2(820, 760)},
    {"id":"rich", "name":"Богатый квартал", "center":Vector2(1040, -650), "size":Vector2(700, 680)},
    {"id":"aristocratic", "name":"Аристократический квартал", "center":Vector2(300, -1250), "size":Vector2(760, 620)},
    {"id":"guilds", "name":"Квартал гильдий и фракций", "center":Vector2(-520, -820), "size":Vector2(760, 680)},
    {"id":"adventurers", "name":"Гильдия приключенцев и Зал Врат", "center":Vector2(-60, -620), "size":Vector2(420, 360)},
    {"id":"guards", "name":"Казармы и штаб стражи", "center":Vector2(-1280, -700), "size":Vector2(620, 620)},
    {"id":"training", "name":"Тренировочный комплекс", "center":Vector2(-1350, 100), "size":Vector2(560, 620)},
    {"id":"arena", "name":"Арена", "center":Vector2(-1180, 1450), "size":Vector2(520, 420)},
    {"id":"hippodrome", "name":"Ипподром", "center":Vector2(1080, 1450), "size":Vector2(820, 420)},
    {"id":"stables", "name":"Конюшни", "center":Vector2(620, 1420), "size":Vector2(360, 300)},
    {"id":"warehouses", "name":"Склады", "center":Vector2(1320, 220), "size":Vector2(520, 520)},
    {"id":"port", "name":"Порт и причалы", "center":Vector2(1520, -1150), "size":Vector2(650, 760)},
    {"id":"canals", "name":"Озеро, каналы и шлюзы", "center":Vector2(1180, -120), "size":Vector2(620, 720)},
    {"id":"farms", "name":"Фермы и пастбища", "center":Vector2(-1050, 1370), "size":Vector2(700, 520)},
    {"id":"sawmill", "name":"Лесопилка", "center":Vector2(-1580, 1180), "size":Vector2(350, 360)},
    {"id":"training_mine", "name":"Учебная шахта", "center":Vector2(-1600, -50), "size":Vector2(340, 360)},
    {"id":"royal", "name":"Королевская зона", "center":Vector2(250, -1580), "size":Vector2(980, 520)}
]

const PROTECTED_ANCHORS := [
    {"id":"town_hall", "name":"Ратуша", "pos":Vector2(0, -140)},
    {"id":"treasury", "name":"Казначейство", "pos":Vector2(170, -220)},
    {"id":"guild_hall", "name":"Гильдия приключенцев", "pos":Vector2(-130, -610)},
    {"id":"gate_hall", "name":"Зал Врат", "pos":Vector2(100, -630)},
    {"id":"guard_hq", "name":"Штаб стражи", "pos":Vector2(-1280, -700)},
    {"id":"royal_estate", "name":"Королевское поместье", "pos":Vector2(250, -1580)}
]

static func gates() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    _append_side_gates(result, "north", NORTH_GATE_NAMES, Vector2(0, -1))
    _append_side_gates(result, "east", EAST_GATE_NAMES, Vector2(1, 0))
    _append_side_gates(result, "south", SOUTH_GATE_NAMES, Vector2(0, 1))
    _append_side_gates(result, "west", WEST_GATE_NAMES, Vector2(-1, 0))
    assert(result.size() == TOTAL_GATES)
    return result

static func _append_side_gates(target: Array[Dictionary], side: String, names: Array, normal: Vector2) -> void:
    for i in range(GATES_PER_SIDE):
        var offset := float(GATE_OFFSETS[i])
        var local_pos := Vector2.ZERO
        match side:
            "north": local_pos = Vector2(offset, -HALF_EXTENT)
            "south": local_pos = Vector2(offset, HALF_EXTENT)
            "east": local_pos = Vector2(HALF_EXTENT, offset)
            "west": local_pos = Vector2(-HALF_EXTENT, offset)
        target.append({
            "id": "%s_%02d" % [side, i + 1],
            "name": String(names[i]),
            "side": side,
            "index": i,
            "position": CENTER + local_pos,
            "local_position": local_pos,
            "normal": normal
        })

static func gate_by_id(gate_id: String) -> Dictionary:
    for gate in gates():
        if String(gate.get("id", "")) == gate_id:
            return gate
    return {}

static func gates_are_open(world_minutes: float) -> bool:
    var minute := int(world_minutes) % 1440
    return minute >= GATE_OPEN_MINUTE and minute < GATE_CLOSE_MINUTE

static func to_local(pos: Vector2) -> Vector2:
    return pos - CENTER

static func to_world(local_pos: Vector2) -> Vector2:
    return CENTER + local_pos

static func inside_capital(pos: Vector2) -> bool:
    var local := to_local(pos)
    return absf(local.x) < HALF_EXTENT and absf(local.y) < HALF_EXTENT

static func in_defense_belt(pos: Vector2) -> bool:
    var local := to_local(pos)
    var d := maxf(absf(local.x), absf(local.y))
    return d >= HALF_EXTENT and d <= HALF_EXTENT + DEFENSE_BELT

static func can_build_at(pos: Vector2) -> bool:
    if in_defense_belt(pos):
        return false
    if inside_capital(pos):
        return false
    return true

static func district_at(pos: Vector2) -> Dictionary:
    var local := to_local(pos)
    for district in DISTRICTS:
        var center: Vector2 = district.get("center", Vector2.ZERO)
        var size: Vector2 = district.get("size", Vector2.ZERO)
        var half := size * 0.5
        if local.x >= center.x - half.x and local.x <= center.x + half.x and local.y >= center.y - half.y and local.y <= center.y + half.y:
            var result := district.duplicate(true)
            result["local_center"] = center
            result["center"] = CENTER + center
            return result
    return {}

static func protected_infrastructure_near(pos: Vector2, radius: float = 90.0) -> Dictionary:
    for anchor in PROTECTED_ANCHORS:
        var local_anchor: Vector2 = anchor.get("pos", Vector2.ZERO)
        var world_anchor := CENTER + local_anchor
        if world_anchor.distance_to(pos) <= radius:
            var result := anchor.duplicate(true)
            result["local_pos"] = local_anchor
            result["pos"] = world_anchor
            return result
    return {}
