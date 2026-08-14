extends StaticBody3D

var persistent_id := ""
var resource_id := "wood"
var display_name := "ресурс"
var amount_per_use := 1
var uses := 4
var visual_root: Node3D

func configure(id_value: String, type_value: String, uses_value: int) -> void:
    persistent_id = id_value
    resource_id = type_value
    uses = uses_value
    match resource_id:
        "wood": display_name = "древесина"
        "stone": display_name = "камень"
        "berries": display_name = "ягоды"
        _: display_name = resource_id

func _ready() -> void:
    if persistent_id.is_empty():
        persistent_id = String(name)
    uses = maxi(0, int(GameState.get_world_value("resource:" + persistent_id, uses)))
    _build_visual()
    _apply_state()

func interact(_player: Node) -> void:
    if uses <= 0:
        GameState.notify("Здесь больше нечего добывать.")
        return
    GameState.add_item(resource_id, amount_per_use)
    uses -= 1
    GameState.set_world_value("resource:" + persistent_id, uses)
    GameState.notify("Получено: %s +%d" % [display_name, amount_per_use])
    _apply_state()

func _build_visual() -> void:
    visual_root = Node3D.new()
    visual_root.name = "Visual"
    add_child(visual_root)
    match resource_id:
        "stone": _build_stone()
        "berries": _build_bush()
        _: _build_tree()

func _build_tree() -> void:
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.28
    trunk_mesh.bottom_radius = 0.40
    trunk_mesh.height = 4.8
    trunk_mesh.radial_segments = 8
    trunk_mesh.material = _mat(Color(0.25, 0.13, 0.06), 0.96)
    trunk.mesh = trunk_mesh
    trunk.position.y = 2.4
    visual_root.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := CylinderMesh.new()
    crown_mesh.top_radius = 0.0
    crown_mesh.bottom_radius = 1.9
    crown_mesh.height = 5.0
    crown_mesh.radial_segments = 8
    crown_mesh.material = _mat(Color(0.09, 0.30, 0.11), 0.96)
    crown.mesh = crown_mesh
    crown.position.y = 5.6
    visual_root.add_child(crown)

    var shape := CylinderShape3D.new()
    shape.radius = 0.46
    shape.height = 4.8
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 2.4
    add_child(collision)

func _build_stone() -> void:
    var stone := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.9
    mesh.height = 1.5
    mesh.radial_segments = 10
    mesh.rings = 6
    mesh.material = _mat(Color(0.34, 0.35, 0.36), 0.92)
    stone.mesh = mesh
    stone.position.y = 0.72
    stone.scale = Vector3(1.25, 0.85, 1.0)
    visual_root.add_child(stone)

    var shape := SphereShape3D.new()
    shape.radius = 0.9
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.72
    add_child(collision)

func _build_bush() -> void:
    var bush := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.9
    mesh.height = 1.3
    mesh.radial_segments = 9
    mesh.rings = 5
    mesh.material = _mat(Color(0.12, 0.34, 0.12), 0.97)
    bush.mesh = mesh
    bush.position.y = 0.62
    bush.scale = Vector3(1.35, 0.75, 1.1)
    visual_root.add_child(bush)
    for offset in [Vector3(-0.35, 0.82, 0.35), Vector3(0.30, 0.75, 0.15), Vector3(0.05, 0.92, -0.38)]:
        var berry := MeshInstance3D.new()
        var berry_mesh := SphereMesh.new()
        berry_mesh.radius = 0.10
        berry_mesh.height = 0.20
        berry_mesh.radial_segments = 6
        berry_mesh.rings = 4
        berry_mesh.material = _mat(Color(0.58, 0.06, 0.14), 0.72)
        berry.mesh = berry_mesh
        berry.position = offset
        visual_root.add_child(berry)

    var shape := SphereShape3D.new()
    shape.radius = 0.95
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.65
    add_child(collision)

func _apply_state() -> void:
    var active := uses > 0
    if is_instance_valid(visual_root):
        visual_root.visible = active
    collision_layer = 1 if active else 0
    collision_mask = 1 if active else 0

func _mat(color: Color, roughness_value: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness_value
    return mat
