extends Control

const CAPITAL := preload("res://scripts/capital_data.gd")
const LOCAL_RADIUS := 2400.0

var player: Node3D
var redraw_elapsed := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(640, 430)
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
    if size.x < 40.0 or size.y < 40.0:
        return
    var footer_height := 34.0
    var map_rect := Rect2(Vector2(8, 8), Vector2(maxf(20.0, size.x - 16.0), maxf(20.0, size.y - footer_height - 8.0)))
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

    _draw_capital_outline(inner)
    for poi in WorldData.poi_catalog():
        var pos: Vector2 = poi.get("pos", Vector2.ZERO)
        if MapSystem.is_world_explored(pos):
            _draw_poi(inner, pos, String(poi.get("name", "")), String(poi.get("kind", "city")), true)

    for gate in CAPITAL.gates():
        var pos: Vector2 = gate.get("position", Vector2.ZERO)
        if MapSystem.is_world_explored(pos):
            _draw_poi(inner, pos, "", "gate", false)

    if player != null and is_instance_valid(player):
        var world := Vector2(player.global_position.x, player.global_position.z)
        var p := _world_to_screen(world, inner)
        draw_circle(p, 6.0, Color(0.20, 0.88, 1.0, 1.0))
        draw_circle(p, 2.5, Color.WHITE)
        _draw_local_inset(inner, world)

    var footer := "64 × 64 км   •   открыто %.2f км² / %.2f%%   •   тёмное = не исследовано" % [MapSystem.explored_area_km2(), MapSystem.explored_percent()]
    draw_string(ThemeDB.fallback_font, Vector2(14, size.y - 10), footer, HORIZONTAL_ALIGNMENT_LEFT, maxf(120.0, size.x - 28.0), 13, Color(0.68, 0.77, 0.86))

func _draw_continent_frame(rect: Rect2) -> void:
    draw_rect(rect, Color(0.16, 0.24, 0.30, 0.9), false, 1.5)
    var center := _world_to_screen(Vector2.ZERO, rect)
    draw_line(Vector2(center.x, rect.position.y), Vector2(center.x, rect.end.y), Color(0.18, 0.23, 0.28, 0.35), 1.0)
    draw_line(Vector2(rect.position.x, center.y), Vector2(rect.end.x, center.y), Color(0.18, 0.23, 0.28, 0.35), 1.0)

func _draw_capital_outline(rect: Rect2) -> void:
    if not MapSystem.is_world_explored(Vector2.ZERO):
        return
    var corners := PackedVector2Array([
        _world_to_screen(Vector2(-CAPITAL.HALF_EXTENT, -CAPITAL.HALF_EXTENT), rect),
        _world_to_screen(Vector2(CAPITAL.HALF_EXTENT, -CAPITAL.HALF_EXTENT), rect),
        _world_to_screen(Vector2(CAPITAL.HALF_EXTENT, CAPITAL.HALF_EXTENT), rect),
        _world_to_screen(Vector2(-CAPITAL.HALF_EXTENT, CAPITAL.HALF_EXTENT), rect),
        _world_to_screen(Vector2(-CAPITAL.HALF_EXTENT, -CAPITAL.HALF_EXTENT), rect)
    ])
    draw_polyline(corners, Color(0.55, 0.76, 0.90, 0.9), 1.5)

func _draw_local_inset(rect: Rect2, player_world: Vector2) -> void:
    var inset_size := Vector2(
        minf(320.0, maxf(210.0, rect.size.x * 0.40)),
        minf(220.0, maxf(155.0, rect.size.y * 0.44))
    )
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

    _draw_capital_local(inner, player_world)
    var pp := _local_to_screen(player_world, inner, player_world)
    draw_circle(pp, 5.0, Color(0.20, 0.88, 1.0, 1.0))
    draw_circle(pp, 2.0, Color.WHITE)
    draw_string(ThemeDB.fallback_font, inset.position + Vector2(10, 17), "Рядом • 4.8 км", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.82, 0.92))

func _draw_capital_local(rect: Rect2, player_world: Vector2) -> void:
    if player_world.distance_to(Vector2.ZERO) > LOCAL_RADIUS + CAPITAL.HALF_EXTENT:
        return
    var a := _local_to_screen(Vector2(-CAPITAL.HALF_EXTENT, -CAPITAL.HALF_EXTENT), rect, player_world)
    var b := _local_to_screen(Vector2(CAPITAL.HALF_EXTENT, CAPITAL.HALF_EXTENT), rect, player_world)
    var capital_rect := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y)))
    draw_rect(capital_rect, Color(0.60, 0.70, 0.78, 0.78), false, 1.3)

    var district_labels := 0
    for district in CAPITAL.DISTRICTS:
        var pos: Vector2 = district.get("center", Vector2.ZERO)
        if pos.distance_to(player_world) > LOCAL_RADIUS or not MapSystem.is_world_explored(pos):
            continue
        var show_name := pos.distance_to(player_world) <= 650.0 and district_labels < 4
        _draw_local_poi(rect, player_world, pos, String(district.get("name", "")), "district", show_name)
        if show_name:
            district_labels += 1

    var gate_labels := 0
    for gate in CAPITAL.gates():
        var pos: Vector2 = gate.get("position", Vector2.ZERO)
        if pos.distance_to(player_world) > LOCAL_RADIUS or not MapSystem.is_world_explored(pos):
            continue
        var show_name := pos.distance_to(player_world) <= 360.0 and gate_labels < 2
        _draw_local_poi(rect, player_world, pos, String(gate.get("name", "")), "gate", show_name)
        if show_name:
            gate_labels += 1

func _draw_poi(rect: Rect2, world: Vector2, name: String, kind: String, show_name: bool) -> void:
    var p := _world_to_screen(world, rect)
    var color := _poi_color(kind)
    draw_circle(p, 4.5, color)
    draw_circle(p, 1.8, Color(0.03, 0.04, 0.06))
    if show_name and not name.is_empty():
        draw_string(ThemeDB.fallback_font, p + Vector2(7, 3), name, HORIZONTAL_ALIGNMENT_LEFT, 130, 10, Color(0.88, 0.91, 0.95))

func _draw_local_poi(rect: Rect2, center: Vector2, world: Vector2, name: String, kind: String, show_name: bool) -> void:
    var p := _local_to_screen(world, rect, center)
    draw_circle(p, 3.5, _poi_color(kind))
    if show_name and not name.is_empty():
        draw_string(ThemeDB.fallback_font, p + Vector2(5, 3), name, HORIZONTAL_ALIGNMENT_LEFT, minf(150.0, rect.size.x * 0.5), 8, Color(0.90, 0.92, 0.95))

func _poi_color(kind: String) -> Color:
    match kind:
        "gate": return Color(0.58, 0.78, 0.96)
        "district": return Color(0.70, 0.75, 0.82)
        "danger": return Color(0.92, 0.28, 0.24)
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
