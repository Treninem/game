extends RefCounted

var texture: ImageTexture
var tile_center := Vector2(INF, INF)
var tile_radius := 0.0
var dirty := true

func invalidate() -> void:
    dirty = true

static func project(rect: Rect2, center: Vector2, radius: float, world: Vector2) -> Vector2:
    return rect.position + ((world - center) / (radius * 2.0) + Vector2.ONE * 0.5) * rect.size

func draw_terrain(control: Control, rect: Rect2, center: Vector2, radius: float) -> void:
    var stride := radius / 8.0
    var snapped := (center / stride).floor() * stride
    if texture == null or dirty or tile_radius != radius or snapped != tile_center:
        tile_center = snapped
        tile_radius = radius
        dirty = false
        var resolution := 48
        var extent := radius * 1.2
        var image := Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
        for y in range(resolution):
            for x in range(resolution):
                var world := tile_center + (Vector2(x + 0.5, y + 0.5) / float(resolution) - Vector2.ONE * 0.5) * extent * 2.0
                image.set_pixel(x, y, MapSystem.terrain_color(world, extent * 2.0 / resolution))
        texture = ImageTexture.create_from_image(image)
    var extent := radius * 1.2
    var source_origin := (center - Vector2.ONE * radius - (tile_center - Vector2.ONE * extent)) / (extent * 2.0) * 48.0
    control.draw_texture_rect_region(texture, rect, Rect2(source_origin, Vector2.ONE * (radius / extent * 48.0)))

func draw_features(control: Control, rect: Rect2, center: Vector2, radius: float) -> void:
    var features := MapSystem.features_near(center, radius)
    # Static terrain details first; living actors remain readable on top.
    for feature: Dictionary in features:
        if feature.kind in ["tree", "building", "fixture"]:
            _draw_feature(control, rect, center, radius, feature)
    for feature: Dictionary in features:
        if feature.kind not in ["tree", "building", "fixture"]:
            _draw_feature(control, rect, center, radius, feature)

func _draw_feature(control: Control, rect: Rect2, center: Vector2, radius: float, feature: Dictionary) -> void:
    var world := Vector2(float(feature.pos[0]), float(feature.pos[1]))
    var position := project(rect, center, radius, world)
    if not rect.has_point(position):
        return
    match String(feature.kind):
        "rock":
            control.draw_circle(position, clampf(2.0 / (radius * 2.0) * rect.size.x, 0.8, 2.2), Color(0.52, 0.54, 0.52))
        "stump":
            control.draw_circle(position, 1.1, Color(0.48, 0.30, 0.16))
        "tree":
            control.draw_circle(position, clampf(3.5 / (radius * 2.0) * rect.size.x, 0.7, 3.0), Color(0.10, 0.26, 0.12, 0.90))
        "building", "fixture":
            var footprint := Vector2(float(feature.size[0]), float(feature.size[1])) * 0.5
            var polygon := PackedVector2Array()
            for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
                var point := project(rect, center, radius, world + (corner * footprint).rotated(-float(feature.yaw)))
                polygon.append(point.clamp(rect.position, rect.end))
            control.draw_colored_polygon(polygon, Color(0.48, 0.64, 0.69) if feature.kind == "fixture" else Color(0.68, 0.53, 0.36))
            polygon.append(polygon[0])
            control.draw_polyline(polygon, Color(0.22, 0.17, 0.12), 1.0)
        "hostile":
            control.draw_colored_polygon(PackedVector2Array([position + Vector2(0, -4), position + Vector2(4, 0), position + Vector2(0, 4), position + Vector2(-4, 0)]), Color(0.95, 0.20, 0.16))
        "ally":
            control.draw_circle(position, 3.0, Color(0.30, 0.95, 0.53))
        "npc":
            control.draw_circle(position, 2.5, Color(0.95, 0.78, 0.30))
        "resource":
            control.draw_circle(position, 2.6, Color(0.80, 0.68, 0.34), false, 1.1)
