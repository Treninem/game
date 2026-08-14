extends Control

const CITY_MIN := Vector2(-47.0, -60.0)
const CITY_MAX := Vector2(47.0, -14.0)
const LOCAL_RADIUS := 1200.0

const LOCAL_POIS := [
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
    if redraw_elapsed >= 0.25:
        redraw_elapsed = 0.0
        if player == null or not is_instance_valid(player):
            player = get_tree().get_first_node_in_group("player") as Node3D
        queue_redraw()

func _draw() -> void:
    var map_rect := Rect2(Vector2(8, 8), size - Vector2(16, 46))
    draw_style_box(_panel_style(), map_rect)
    var inner := map_rect.grow(-8)
    draw_rect(inner, Color(0.006, 0.010, 0.016, 1.0), true)

    _draw_continent_frame(inner)
    for cell in MapSystem.explored_cells():
        var world_center := MapSystem.cell_to_world_center(cell)
        var world_min := world_center - Vector2(MapSystem.CELL_SIZE * 0.5, MapSystem.CELL_SIZE * 0.5)
        var p1 := _world_to_screen(world_min, inner)
        var p2 := _world_to_screen(world_min + Vector2(MapSystem.CELL_SIZE, MapSystem.CELL_SIZE), inner)
        var cell_rect := Rect2(Vector2(minf(p1.x, p2.x), minf(p1.y, p2.y)), Vector2(absf(p2.x - p1.x), absf(p2.y - p1.y)))
        draw_rect(cell_rect.grow(0.35), WorldData.biome_color(WorldData.biome_at(world_center)), true)

    for poi in WorldData.poi_catalog():
        var pos: Vector2 = poi.get("pos", Vector2.ZERO)
        if MapSystem.is_world_explored(pos):
            _draw_poi(inner, pos, String(poi.get("name", "")), String(poi.get("kind", "city")), true)

    if player != null and is_instance_valid(player):
        var world := Vector2(player.global_position.x, player.global_position.z)
        var p := _world_to_screen(world, inner)
        draw_circle(p, 6.0, Color(0.20, 0.88, 1.0, 1.0))
        draw_circle(p, 2.5, Color.WHITE)
        _draw_local_inset(inner, world)

    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(14, size.y - 14), "Континент 64 × 64 км   •   исследовано %.2f км² (%.2f%%)   •   тёмные области не открыты" % [MapSystem.explored_area_km2(), MapSystem.explored_percent()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.72, 0.79, 0.88))

func _draw_continent_frame(rect: Rect2) -> void:
    draw_rect(rect, Color(0.16, 0.24, 0.30, 0.9), false, 1.5)
    var center_x := _world_to_screen(Vector2(0, 0), rect).x
    var center_y := _world_to_screen(Vector2(0, 0), rect).y
    draw_line(Vector2(center_x, rect.position.y), Vector2(center_x, rect.end.y), Color(0.18, 0.23, 0.28, 0.35), 1.0)
    draw_line(Vector2(rect.position.x, center_y), Vector2(rect.end.x, center_y), Color(0.18, 0.23, 0.28, 0.35), 1.0)

func _draw_local_inset(rect: Rect2, player_world: Vector2) -> void:
    var inset_size := Vector2(250, 165)
    var inset := Rect2(rect.end - inset_size - Vector2(10, 10), inset_size)
    draw_style_box(_inset_style(), inset)
    var inner := inset.grow(-7)
    draw_rect(inner, Color(0.012, 0.017, 0.025, 0.98), true)

    var local_min := player_world - Vector2(LOCAL_RADIUS, LOCAL_RADIUS)
    var local_max := player_world + Vector2(LOCAL_RADIUS, LOCAL_RADIUS)
    for cell in MapSystem.explored_cells():
        var center := MapSystem.cell_to_world_center(cell)
        if center.x < local_min.x or center.x > local_max.x or center.y < local_min.y or center.y > local_max.y:
            continue
        var half := MapSystem.CELL_SIZE * 0.5
        var p1 := _local_to_screen(center - Vector2(half, half), inner, player_world)
        var p2 := _local_to_screen(center + Vector2(half, half), inner, player_world)
        var r := Rect2(Vector2(minf(p1.x, p2.x), minf(p1.y, p2.y)), Vector2(absf(p2.x - p1.x), absf(p2.y - p1.y)))
        draw_rect(r.grow(0.4), WorldData.biome_color(WorldData.biome_at(center)).lightened(0.06), true)

    if player_world.distance_to(Vector2.ZERO) < LOCAL_RADIUS + 600.0:
        _draw_discovered_city_geometry_local(inner, player_world)
        for poi in LOCAL_POIS:
            var pos: Vector2 = poi.get("pos", Vector2.ZERO)
            if pos.distance_to(player_world) <= LOCAL_RADIUS and MapSystem.is_world_explored(pos):
                _draw_local_poi(inner, player_world, pos, String(poi.get("name", "")), String(poi.get("kind", "city")))

    var pp := _local_to_screen(player_world, inner, player_world)
    draw_circle(pp, 5.0, Color(0.20, 0.88, 1.0, 1.0))
    draw_circle(pp, 2.0, Color.WHITE)
    draw_string(ThemeDB.fallback_font, inset.position + Vector2(10, 17), "Рядом • 2.4 км", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.82, 0.92))

func _draw_discovered_city_geometry_local(rect: Rect2, player_world: Vector2) -> void:
    var city_center := (CITY_MIN + CITY_MAX) * 0.5
    if not MapSystem.is_world_explored(city_center):
        return
    var a := _local_to_screen(CITY_MIN, rect, player_world)
    var b := _local_to_screen(CITY_MAX, rect, player_world)
    var city_rect := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y)))
    draw_rect(city_rect, Color(0.62, 0.66, 0.68, 0.8), false, 1.4)

func _draw_poi(rect: Rect2, world: Vector2, name: String, kind: String, show_name: bool) -> void:
    var p := _world_to_screen(world, rect)
    var color := _poi_color(kind)
    draw_circle(p, 4.5, color)
    draw_circle(p, 1.8, Color(0.03, 0.04, 0.06))
    if show_name:
        draw_string(ThemeDB.fallback_font, p + Vector2(7, 3), name, HORIZONTAL_ALIGNMENT_LEFT, 130, 10, Color(0.88, 0.91, 0.95))

func _draw_local_poi(rect: Rect2, center: Vector2, world: Vector2, name: String, kind: String) -> void:
    var p := _local_to_screen(world, rect, center)
    draw_circle(p, 3.5, _poi_color(kind))
    draw_string(ThemeDB.fallback_font, p + Vector2(5, 3), name, HORIZONTAL_ALIGNMENT_LEFT, 95, 9, Color(0.90, 0.92, 0.95))

func _poi_color(kind: String) -> Color:
    match kind:
        "quest": return Color(0.95, 0.72, 0.18)
        "shop": return Color(0.32, 0.82, 0.55)
        "inn": return Color(0.44, 0.64, 0.98)
        "guard": return Color(0.48, 0.70, 0.92)
        "danger": return Color(0.92, 0.28, 0.24)
        "gate": return Color(0.78, 0.82, 0.88)
        "capital": return Color(0.30, 0.80, 1.0)
        "settlement": return Color(0.72, 0.82, 0.65)
        "lake", "coast": return Color(0.25, 0.65, 0.92)
        "mine", "ruin": return Color(0.80, 0.56, 0.28)
        "forest", "marsh": return Color(0.25, 0.72, 0.34)
        "mountain": return Color(0.72, 0.74, 0.76)
        _: return Color(0.86, 0.86, 0.80)

func _world_to_screen(world: Vector2, rect: Rect2) -> Vector2:
    var nx := inverse_lerp(WorldData.WORLD_MIN.x, WorldData.WORLD_MAX.x, world.x)
    var ny := inverse_lerp(WorldData.WORLD_MIN.y, WorldData.WORLD_MAX.y, world.y)
    return Vector2(rect.position.x + nx * rect.size.x, rect.end.y - ny * rect.size.y)

func _local_to_screen(world: Vector2, rect: Rect2, center: Vector2) -> Vector2:
    var local_min := center - Vector2(LOCAL_RADIUS, LOCAL_RADIUS)
    var local_max := center + Vector2(LOCAL_RADIUS, LOCAL_RADIUS)
    var nx := inverse_lerp(local_min.x, local_max.x, world.x)
    var ny := inverse_lerp(local_min.y, local_max.y, world.y)
    return Vector2(rect.position.x + nx * rect.size.x, rect.end.y - ny * rect.size.y)

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.038, 0.98)
    style.border_color = Color(0.18, 0.42, 0.58, 0.8)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    return style

func _inset_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.018, 0.028, 0.98)
    style.border_color = Color(0.26, 0.60, 0.78, 0.9)
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    return style
