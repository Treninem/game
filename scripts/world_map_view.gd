extends Control

const CITY_MIN := Vector2(-47.0, -60.0)
const CITY_MAX := Vector2(47.0, -14.0)

const POIS := [
    {"name": "Южные ворота", "pos": Vector2(0, -14), "kind": "gate"},
    {"name": "Площадь", "pos": Vector2(0, -36), "kind": "city"},
    {"name": "Рынок", "pos": Vector2(-18, -34), "kind": "shop"},
    {"name": "Кузница Радана", "pos": Vector2(24, -29), "kind": "quest"},
    {"name": "Синий фонарь", "pos": Vector2(20, -49), "kind": "inn"},
    {"name": "Караульня", "pos": Vector2(-22, -20), "kind": "guard"},
    {"name": "Мира", "pos": Vector2(0, -4), "kind": "quest"},
    {"name": "Западные руины", "pos": Vector2(-55, -66), "kind": "danger"},
    {"name": "Восточные руины", "pos": Vector2(56, -72), "kind": "danger"}
]

var player: Node3D
var redraw_elapsed := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(700, 470)
    if not MapSystem.explored_changed.is_connected(queue_redraw):
        MapSystem.explored_changed.connect(queue_redraw)
    queue_redraw()

func _process(delta: float) -> void:
    redraw_elapsed += delta
    if redraw_elapsed >= 0.2:
        redraw_elapsed = 0.0
        if player == null or not is_instance_valid(player):
            player = get_tree().get_first_node_in_group("player") as Node3D
        queue_redraw()

func _draw() -> void:
    var map_rect := Rect2(Vector2(8, 8), size - Vector2(16, 46))
    draw_style_box(_panel_style(), map_rect)
    draw_rect(map_rect.grow(-8), Color(0.012, 0.017, 0.025, 1.0), true)

    for cell in MapSystem.explored_cells():
        var world_center := MapSystem.cell_to_world_center(cell)
        var world_min := world_center - Vector2(MapSystem.CELL_SIZE * 0.5, MapSystem.CELL_SIZE * 0.5)
        var p1 := _world_to_screen(world_min, map_rect.grow(-8))
        var p2 := _world_to_screen(world_min + Vector2(MapSystem.CELL_SIZE, MapSystem.CELL_SIZE), map_rect.grow(-8))
        var cell_rect := Rect2(p1, p2 - p1)
        var fill := _terrain_color(world_center)
        draw_rect(cell_rect.grow(0.5), fill, true)

    _draw_discovered_city_geometry(map_rect.grow(-8))

    for poi in POIS:
        var pos: Vector2 = poi["pos"]
        if MapSystem.is_world_explored(pos):
            _draw_poi(map_rect.grow(-8), pos, String(poi["name"]), String(poi["kind"]))

    if player != null and is_instance_valid(player):
        var world := Vector2(player.global_position.x, player.global_position.z)
        var p := _world_to_screen(world, map_rect.grow(-8))
        draw_circle(p, 7.0, Color(0.25, 0.86, 1.0, 1.0))
        draw_circle(p, 3.0, Color.WHITE)

    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(14, size.y - 14), "Исследовано: %.1f%%   •   голубой маркер — вы   •   тёмные области ещё не открыты" % MapSystem.explored_percent(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.72, 0.79, 0.88))

func _terrain_color(world: Vector2) -> Color:
    if _inside_city(world):
        if absf(world.x) < 5.0 or (absf(world.x) < 17.0 and world.y < -25.0 and world.y > -47.0):
            return Color(0.26, 0.245, 0.22, 1.0)
        return Color(0.18, 0.27, 0.19, 1.0)
    if world.y < -62.0:
        return Color(0.16, 0.20, 0.17, 1.0)
    return Color(0.12, 0.22, 0.14, 1.0)

func _draw_discovered_city_geometry(rect: Rect2) -> void:
    var city_center := (CITY_MIN + CITY_MAX) * 0.5
    if not MapSystem.is_world_explored(city_center):
        return
    var a := _world_to_screen(CITY_MIN, rect)
    var b := _world_to_screen(CITY_MAX, rect)
    var city_rect := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y)))
    draw_rect(city_rect, Color(0.52, 0.58, 0.60, 0.75), false, 2.0)

    var road_a := _world_to_screen(Vector2(-4, -60), rect)
    var road_b := _world_to_screen(Vector2(4, -14), rect)
    var road_rect := Rect2(Vector2(minf(road_a.x, road_b.x), minf(road_a.y, road_b.y)), Vector2(absf(road_b.x - road_a.x), absf(road_b.y - road_a.y)))
    draw_rect(road_rect, Color(0.42, 0.36, 0.29, 0.75), true)

func _draw_poi(rect: Rect2, world: Vector2, name: String, kind: String) -> void:
    var p := _world_to_screen(world, rect)
    var color := Color(0.86, 0.86, 0.80)
    match kind:
        "quest": color = Color(0.95, 0.72, 0.18)
        "shop": color = Color(0.32, 0.82, 0.55)
        "inn": color = Color(0.44, 0.64, 0.98)
        "guard": color = Color(0.48, 0.70, 0.92)
        "danger": color = Color(0.90, 0.28, 0.25)
        "gate": color = Color(0.78, 0.82, 0.88)
    draw_circle(p, 5.0, color)
    draw_circle(p, 2.0, Color(0.03, 0.04, 0.06))
    draw_string(ThemeDB.fallback_font, p + Vector2(8, 4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.91, 0.95))

func _world_to_screen(world: Vector2, rect: Rect2) -> Vector2:
    var nx := inverse_lerp(MapSystem.WORLD_MIN.x, MapSystem.WORLD_MAX.x, world.x)
    var ny := inverse_lerp(MapSystem.WORLD_MIN.y, MapSystem.WORLD_MAX.y, world.y)
    return Vector2(rect.position.x + nx * rect.size.x, rect.end.y - ny * rect.size.y)

func _inside_city(world: Vector2) -> bool:
    return world.x >= CITY_MIN.x and world.x <= CITY_MAX.x and world.y >= CITY_MIN.y and world.y <= CITY_MAX.y

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.038, 0.98)
    style.border_color = Color(0.18, 0.42, 0.58, 0.8)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    return style
