extends Control

const CAPITAL := preload("res://scripts/capital_data.gd")
const VIEW_RADIUS := 260.0
const SAMPLE_GRID := 13

var player: Node3D
var redraw_elapsed := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(250, 250)
    if not MapSystem.explored_changed.is_connected(queue_redraw):
        MapSystem.explored_changed.connect(queue_redraw)
    queue_redraw()

func _process(delta: float) -> void:
    redraw_elapsed += delta
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
    if redraw_elapsed >= 0.15:
        redraw_elapsed = 0.0
        queue_redraw()

func _draw() -> void:
    var rect := Rect2(Vector2.ZERO, size)
    draw_style_box(_panel_style(), rect)
    var map_rect := rect.grow(-9.0)
    draw_rect(map_rect, Color(0.008, 0.012, 0.018, 0.96), true)
    if player == null or not is_instance_valid(player):
        return

    var center := Vector2(player.global_position.x, player.global_position.z)
    _draw_terrain(map_rect, center)
    _draw_capital_features(map_rect, center)
    _draw_world_pois(map_rect, center)
    _draw_player(map_rect)

    draw_string(ThemeDB.fallback_font, Vector2(14, 21), "МИНИ-КАРТА", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.62, 0.78, 0.92))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 24, 21), "N", HORIZONTAL_ALIGNMENT_CENTER, 16, 13, Color(0.90, 0.93, 0.97))
    draw_string(ThemeDB.fallback_font, Vector2(14, size.y - 13), "M — карта мира", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.62, 0.68, 0.76))

func _draw_terrain(rect: Rect2, center: Vector2) -> void:
    var cell_w := rect.size.x / float(SAMPLE_GRID)
    var cell_h := rect.size.y / float(SAMPLE_GRID)
    for gy in range(SAMPLE_GRID):
        for gx in range(SAMPLE_GRID):
            var nx := (float(gx) + 0.5) / float(SAMPLE_GRID)
            var ny := (float(gy) + 0.5) / float(SAMPLE_GRID)
            var world := center + Vector2((nx - 0.5) * VIEW_RADIUS * 2.0, (0.5 - ny) * VIEW_RADIUS * 2.0)
            var cell_rect := Rect2(rect.position + Vector2(gx * cell_w, gy * cell_h), Vector2(cell_w + 1.0, cell_h + 1.0))
            if not MapSystem.is_world_explored(world):
                draw_rect(cell_rect, Color(0.004, 0.006, 0.010, 1.0), true)
                continue
            var biome := WorldData.biome_at(world)
            var color := WorldData.biome_color(biome).darkened(0.12)
            draw_rect(cell_rect, color, true)

func _draw_capital_features(rect: Rect2, center: Vector2) -> void:
    # District anchors and the exact 32 perimeter gates are only shown after discovery.
    for district in CAPITAL.DISTRICTS:
        var pos: Vector2 = district.get("center", Vector2.ZERO)
        if pos.distance_to(center) <= VIEW_RADIUS and MapSystem.is_world_explored(pos):
            _draw_marker(rect, center, pos, "district")

    for gate in CAPITAL.gates():
        var pos: Vector2 = gate.get("position", Vector2.ZERO)
        if pos.distance_to(center) <= VIEW_RADIUS and MapSystem.is_world_explored(pos):
            _draw_marker(rect, center, pos, "gate")

func _draw_world_pois(rect: Rect2, center: Vector2) -> void:
    for poi in WorldData.poi_catalog():
        var pos: Vector2 = poi.get("pos", Vector2.ZERO)
        if pos.distance_to(center) <= VIEW_RADIUS and MapSystem.is_world_explored(pos):
            _draw_marker(rect, center, pos, String(poi.get("kind", "poi")))

func _draw_marker(rect: Rect2, center: Vector2, pos: Vector2, kind: String) -> void:
    var p := _world_to_screen(rect, center, pos)
    var color := Color(0.82, 0.86, 0.90)
    match kind:
        "gate": color = Color(0.58, 0.78, 0.96)
        "district": color = Color(0.64, 0.74, 0.86)
        "danger", "ruin": color = Color(0.92, 0.30, 0.26)
        "capital", "city", "settlement": color = Color(0.72, 0.84, 0.96)
        "lake", "coast": color = Color(0.25, 0.65, 0.92)
        "mine": color = Color(0.80, 0.56, 0.28)
        "forest", "marsh": color = Color(0.25, 0.72, 0.34)
        "mountain": color = Color(0.72, 0.74, 0.76)
    draw_circle(p, 4.0, color)
    draw_circle(p, 1.7, Color(0.02, 0.03, 0.05))

func _draw_player(rect: Rect2) -> void:
    var center := rect.get_center()
    var angle := -player.global_rotation.y
    var forward := Vector2(sin(angle), -cos(angle))
    var right := Vector2(forward.y, -forward.x)
    var tip := center + forward * 10.0
    var left := center - forward * 6.0 + right * 6.0
    var right_point := center - forward * 6.0 - right * 6.0
    draw_colored_polygon(PackedVector2Array([tip, left, right_point]), Color(0.28, 0.88, 1.0))
    draw_polyline(PackedVector2Array([tip, left, right_point, tip]), Color.WHITE, 1.2)

func _world_to_screen(rect: Rect2, center: Vector2, world: Vector2) -> Vector2:
    var offset := world - center
    var nx := offset.x / (VIEW_RADIUS * 2.0) + 0.5
    var ny := 0.5 - offset.y / (VIEW_RADIUS * 2.0)
    return rect.position + Vector2(nx * rect.size.x, ny * rect.size.y)

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.038, 0.90)
    style.border_color = Color(0.20, 0.55, 0.76, 0.72)
    style.set_border_width_all(1)
    style.set_corner_radius_all(11)
    style.shadow_color = Color(0, 0, 0, 0.40)
    style.shadow_size = 7
    return style
