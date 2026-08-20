extends Node3D

const BEACON_SCRIPT := preload("res://scripts/plot_beacon.gd")
const SYNC_INTERVAL := 1.0
const NORMAL_BUILD_COST := 80

var roots: Dictionary = {}
var elapsed := 0.0

func _ready() -> void:
    add_to_group("plot_runtime")
    ProgressionSystem.progression_changed.connect(_sync_plots)
    call_deferred("_sync_plots")

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed >= SYNC_INTERVAL:
        elapsed = 0.0
        _sync_plots()

func _sync_plots() -> void:
    var available: Dictionary = {}
    for plot in ProgressionSystem.plots():
        if plot is not Dictionary:
            continue
        var plot_data: Dictionary = plot
        var plot_id := String(plot_data.get("id", ""))
        if plot_id.is_empty():
            continue
        available[plot_id] = true
        if not roots.has(plot_id) or not is_instance_valid(roots[plot_id]):
            roots[plot_id] = _build_plot_root(plot_data)
        _sync_structure(plot_data, roots[plot_id])

    for plot_id in roots.keys():
        if available.has(plot_id):
            continue
        var node: Node = roots[plot_id]
        if is_instance_valid(node):
            node.queue_free()
        roots.erase(plot_id)

func build_owned_structure(plot_id: String) -> bool:
    var plot := _plot_by_id(plot_id)
    if plot.is_empty():
        return false
    var creative := bool(ProgressionSystem.vip_status().get("creative", false))
    if not ProgressionSystem.plot_build_allowed(plot_id, "house", creative):
        GameState.notify("Строительство здесь запрещено правилами участка.")
        return false
    var key := "plot_structure:" + plot_id
    if bool(GameState.get_world_value(key, false)):
        GameState.notify("На этом участке уже стоит основное строение.")
        return false
    if not creative:
        if GameState.coins < NORMAL_BUILD_COST:
            GameState.notify("Для строительства требуется %d монет." % NORMAL_BUILD_COST)
            return false
        GameState.coins -= NORMAL_BUILD_COST
    GameState.set_world_value(key, true)
    ProgressionSystem.touch_plot(plot_id)
    _sync_plots()
    GameState.notify("Основное строение участка возведено.")
    return true

func _plot_by_id(plot_id: String) -> Dictionary:
    for plot in ProgressionSystem.plots():
        if plot is Dictionary and String(plot.get("id", "")) == plot_id:
            return plot
    return {}

func _build_plot_root(plot: Dictionary) -> Node3D:
    var root := Node3D.new()
    var plot_id := String(plot.get("id", "plot"))
    root.name = "OwnedPlot_" + plot_id.replace("-", "_")
    var pos_data: Array = plot.get("position", [0.0, 0.0])
    var x := float(pos_data[0]) if pos_data.size() > 0 else 0.0
    var z := float(pos_data[1]) if pos_data.size() > 1 else 0.0
    root.global_position = Vector3(x, WorldData.elevation_at(Vector2(x, z)) + 0.04, z)
    add_child(root)

    var size := float(plot.get("size", ProgressionSystem.NORMAL_PLOT_SIZE))
    var material := StandardMaterial3D.new()
    match String(plot.get("type", "normal")):
        "vip": material.albedo_color = Color(0.20, 0.52, 0.76, 0.34)
        "guild": material.albedo_color = Color(0.56, 0.28, 0.70, 0.34)
        _: material.albedo_color = Color(0.22, 0.68, 0.40, 0.30)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.roughness = 0.78

    var border_width := 0.22
    _add_visual_box("NorthBorder", Vector3(size, 0.14, border_width), Vector3(0, 0.07, -size * 0.5), material, root)
    _add_visual_box("SouthBorder", Vector3(size, 0.14, border_width), Vector3(0, 0.07, size * 0.5), material, root)
    _add_visual_box("WestBorder", Vector3(border_width, 0.14, size), Vector3(-size * 0.5, 0.07, 0), material, root)
    _add_visual_box("EastBorder", Vector3(border_width, 0.14, size), Vector3(size * 0.5, 0.07, 0), material, root)

    var beacon := StaticBody3D.new()
    beacon.name = "PlotBeacon"
    beacon.position = Vector3(0, 0.0, minf(size * 0.36, 8.0))
    beacon.set_script(BEACON_SCRIPT)
    beacon.call("configure", plot_id, String(plot.get("type", "normal")))
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 0.65
    shape.height = 1.7
    collision.shape = shape
    collision.position.y = 0.85
    beacon.add_child(collision)
    var beacon_mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.32
    cylinder.bottom_radius = 0.48
    cylinder.height = 1.7
    cylinder.material = material
    beacon_mesh.mesh = cylinder
    beacon_mesh.position.y = 0.85
    beacon.add_child(beacon_mesh)
    root.add_child(beacon)
    return root

func _sync_structure(plot: Dictionary, root: Node3D) -> void:
    var plot_id := String(plot.get("id", ""))
    var wants_structure := bool(GameState.get_world_value("plot_structure:" + plot_id, false))
    var existing := root.get_node_or_null("OwnedStructure")
    if wants_structure and existing == null:
        _build_structure(root, float(plot.get("size", 32)))
    elif not wants_structure and existing != null:
        existing.queue_free()

func _build_structure(root: Node3D, plot_size: float) -> void:
    var body := StaticBody3D.new()
    body.name = "OwnedStructure"
    body.position = Vector3(0, 2.6, -minf(plot_size * 0.18, 7.0))
    root.add_child(body)
    var size := Vector3(minf(10.0, plot_size * 0.42), 5.2, minf(8.0, plot_size * 0.34))
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.34, 0.24, 0.16)
    material.roughness = 0.88
    mesh.material = material
    mesh_instance.mesh = mesh
    body.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(size.x + 0.8, 2.2, size.z + 0.8)
    var roof_material := StandardMaterial3D.new()
    roof_material.albedo_color = Color(0.20, 0.055, 0.035)
    roof_material.roughness = 0.92
    roof_mesh.material = roof_material
    roof.mesh = roof_mesh
    roof.position.y = size.y * 0.5 + 1.0
    body.add_child(roof)

func _add_visual_box(node_name: String, size: Vector3, pos: Vector3, material: Material, parent: Node3D) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    parent.add_child(mesh_instance)
