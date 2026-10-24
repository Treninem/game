extends TextureRect

const CATALOG = preload("res://scripts/weapon_model_catalog.gd")
var item_id := ""
var render_view: SubViewport

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var packed: PackedScene = CATALOG.scene_for(item_id)
    if packed == null:
        return
    render_view = SubViewport.new()
    render_view.name = "ItemModelViewport"
    render_view.size = Vector2i(256, 192)
    render_view.own_world_3d = true
    render_view.transparent_bg = true
    render_view.msaa_3d = Viewport.MSAA_2X
    # Static equipment: render once; no spinning model or perpetual GPU work.
    render_view.render_target_update_mode = SubViewport.UPDATE_ONCE
    add_child(render_view)
    var stage := Node3D.new()
    render_view.add_child(stage)
    var model := packed.instantiate() as Node3D
    stage.add_child(model)
    var points: Array[Vector3] = []
    _collect_points(model, Transform3D.IDENTITY, points)
    assert(not points.is_empty(), "Inventory model has no renderable geometry")
    var bounds := AABB(points[0], Vector3.ZERO)
    for point in points:
        bounds = bounds.expand(point)
    var center := bounds.get_center()
    var extent := maxf(bounds.size.length(), .01)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = extent * 1.12
    camera.near = .001
    camera.far = extent * 12 + 1
    stage.add_child(camera)
    camera.position = center + Vector3(.18, .12, 2.8) * extent
    camera.look_at(center, Vector3.UP)
    camera.current = true
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(1, .94, .85)
    environment.environment.ambient_light_energy = .7
    stage.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-32, -28, 0)
    light.light_energy = 1.6
    light.shadow_enabled = false
    stage.add_child(light)
    texture = render_view.get_texture()
    set_meta("production_model", packed.resource_path)

func _collect_points(node: Node3D, parent_frame: Transform3D, points: Array[Vector3]) -> void:
    var frame := parent_frame * node.transform
    if node is MeshInstance3D and node.mesh != null:
        var bounds: AABB = node.mesh.get_aabb()
        for corner in range(8):
            points.append(frame * bounds.get_endpoint(corner))
    for child in node.get_children():
        if child is Node3D:
            _collect_points(child, frame, points)
