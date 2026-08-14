extends Node3D

@export var skin_color := Color(0.72, 0.55, 0.42)
@export var primary_color := Color(0.11, 0.18, 0.28)
@export var secondary_color := Color(0.22, 0.34, 0.44)
@export var accent_color := Color(0.36, 0.78, 0.92)
@export var hair_color := Color(0.10, 0.07, 0.05)
@export var body_scale := 1.0
@export var has_hood := false
@export var has_apron := false
@export var has_guard_armor := false

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: MeshInstance3D
var walk_time := 0.0
var base_position := Vector3.ZERO

func _ready() -> void:
    base_position = position
    _build_character()

func _process(delta: float) -> void:
    var body := get_parent() as CharacterBody3D
    if body == null:
        return
    var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()
    var target_swing := 0.0
    if horizontal_speed > 0.15:
        walk_time += delta * clampf(horizontal_speed * 1.7, 4.0, 12.0)
        target_swing = sin(walk_time) * 0.62
        position.y = base_position.y + abs(sin(walk_time * 2.0)) * 0.025
    else:
        walk_time += delta * 1.2
        position.y = lerpf(position.y, base_position.y, minf(1.0, delta * 8.0))
    if is_instance_valid(left_arm):
        left_arm.rotation.x = lerpf(left_arm.rotation.x, target_swing, minf(1.0, delta * 10.0))
    if is_instance_valid(right_arm):
        right_arm.rotation.x = lerpf(right_arm.rotation.x, -target_swing, minf(1.0, delta * 10.0))
    if is_instance_valid(left_leg):
        left_leg.rotation.x = lerpf(left_leg.rotation.x, -target_swing * 0.72, minf(1.0, delta * 10.0))
    if is_instance_valid(right_leg):
        right_leg.rotation.x = lerpf(right_leg.rotation.x, target_swing * 0.72, minf(1.0, delta * 10.0))

func _build_character() -> void:
    scale = Vector3.ONE * body_scale

    torso = _box("Torso", Vector3(0.72, 0.82, 0.36), Vector3(0, 1.25, 0), primary_color, self)
    _box("Belt", Vector3(0.75, 0.12, 0.39), Vector3(0, 0.88, 0), accent_color.darkened(0.35), self)
    _box("Hips", Vector3(0.62, 0.28, 0.34), Vector3(0, 0.72, 0), secondary_color.darkened(0.12), self)

    var neck := _cylinder("Neck", 0.12, 0.18, Vector3(0, 1.73, 0), skin_color, self)
    neck.rotation_degrees.x = 90.0
    _sphere("Head", 0.29, Vector3(0, 1.98, 0), skin_color, self)
    _box("Hair", Vector3(0.54, 0.16, 0.55), Vector3(0, 2.19, -0.01), hair_color, self)
    _box("Nose", Vector3(0.08, 0.10, 0.08), Vector3(0, 1.97, -0.285), skin_color.lightened(0.04), self)

    if has_hood:
        var hood := _sphere("Hood", 0.37, Vector3(0, 2.02, 0.04), primary_color.darkened(0.12), self)
        hood.scale = Vector3(1.0, 1.05, 0.92)
    if has_apron:
        _box("Apron", Vector3(0.60, 0.70, 0.07), Vector3(0, 1.15, -0.225), Color(0.30, 0.20, 0.12), self)
    if has_guard_armor:
        _box("ChestPlate", Vector3(0.78, 0.68, 0.10), Vector3(0, 1.33, -0.235), Color(0.31, 0.36, 0.40), self)
        _box("ShoulderL", Vector3(0.30, 0.16, 0.42), Vector3(-0.47, 1.55, 0), Color(0.31, 0.36, 0.40), self)
        _box("ShoulderR", Vector3(0.30, 0.16, 0.42), Vector3(0.47, 1.55, 0), Color(0.31, 0.36, 0.40), self)

    left_arm = Node3D.new()
    left_arm.name = "LeftArmPivot"
    left_arm.position = Vector3(-0.47, 1.58, 0)
    add_child(left_arm)
    _box("LeftArm", Vector3(0.22, 0.72, 0.24), Vector3(0, -0.34, 0), secondary_color, left_arm)
    _sphere("LeftHand", 0.12, Vector3(0, -0.73, 0), skin_color, left_arm)

    right_arm = Node3D.new()
    right_arm.name = "RightArmPivot"
    right_arm.position = Vector3(0.47, 1.58, 0)
    add_child(right_arm)
    _box("RightArm", Vector3(0.22, 0.72, 0.24), Vector3(0, -0.34, 0), secondary_color, right_arm)
    _sphere("RightHand", 0.12, Vector3(0, -0.73, 0), skin_color, right_arm)

    left_leg = Node3D.new()
    left_leg.name = "LeftLegPivot"
    left_leg.position = Vector3(-0.18, 0.69, 0)
    add_child(left_leg)
    _box("LeftLeg", Vector3(0.25, 0.72, 0.28), Vector3(0, -0.34, 0), primary_color.darkened(0.2), left_leg)
    _box("LeftBoot", Vector3(0.28, 0.18, 0.42), Vector3(0, -0.72, -0.05), Color(0.10, 0.07, 0.05), left_leg)

    right_leg = Node3D.new()
    right_leg.name = "RightLegPivot"
    right_leg.position = Vector3(0.18, 0.69, 0)
    add_child(right_leg)
    _box("RightLeg", Vector3(0.25, 0.72, 0.28), Vector3(0, -0.34, 0), primary_color.darkened(0.2), right_leg)
    _box("RightBoot", Vector3(0.28, 0.18, 0.42), Vector3(0, -0.72, -0.05), Color(0.10, 0.07, 0.05), right_leg)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    return mat

func _box(node_name: String, size: Vector3, pos: Vector3, color: Color, parent: Node3D) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color)
    parent.add_child(node)
    return node

func _sphere(node_name: String, radius: float, pos: Vector3, color: Color, parent: Node3D) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 16
    mesh.rings = 8
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color)
    parent.add_child(node)
    return node

func _cylinder(node_name: String, radius: float, height: float, pos: Vector3, color: Color, parent: Node3D) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color)
    parent.add_child(node)
    return node
