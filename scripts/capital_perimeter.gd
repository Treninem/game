extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")

var gate_runtime: Array[Dictionary] = []
var wall_material: StandardMaterial3D
var tower_material: StandardMaterial3D
var wood_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var state_elapsed := 0.0
var last_open_state := true

func _ready() -> void:
    _prepare_materials()
    _build_perimeter()
    last_open_state = CAPITAL.gates_are_open(GameState.world_minutes)
    _apply_gate_state(last_open_state, true)

func _process(delta: float) -> void:
    state_elapsed += delta
    if state_elapsed >= 0.5:
        state_elapsed = 0.0
        var should_open := CAPITAL.gates_are_open(GameState.world_minutes)
        if should_open != last_open_state:
            last_open_state = should_open
            _apply_gate_state(should_open, false)

    var target_angle := deg_to_rad(92.0) if last_open_state else 0.0
    for runtime in gate_runtime:
        var left: Node3D = runtime.get("left")
        var right: Node3D = runtime.get("right")
        if is_instance_valid(left):
            left.rotation.y = move_toward(left.rotation.y, -target_angle, delta * 1.45)
        if is_instance_valid(right):
            right.rotation.y = move_toward(right.rotation.y, target_angle, delta * 1.45)

func _build_perimeter() -> void:
    _build_side_walls("north")
    _build_side_walls("east")
    _build_side_walls("south")
    _build_side_walls("west")

    var definitions := CAPITAL.gates()
    assert(definitions.size() == CAPITAL.TOTAL_GATES)
    for gate in definitions:
        _build_gate(gate)

func _build_side_walls(side: String) -> void:
    var cursor := -CAPITAL.HALF_EXTENT
    var half_gap := CAPITAL.GATE_OPENING * 0.5
    for offset_value in CAPITAL.GATE_OFFSETS:
        var offset := float(offset_value)
        var segment_end := offset - half_gap
        if segment_end > cursor:
            _add_wall_segment(side, (cursor + segment_end) * 0.5, segment_end - cursor)
        cursor = offset + half_gap
    if cursor < CAPITAL.HALF_EXTENT:
        _add_wall_segment(side, (cursor + CAPITAL.HALF_EXTENT) * 0.5, CAPITAL.HALF_EXTENT - cursor)

func _add_wall_segment(side: String, center_offset: float, length: float) -> void:
    var size := Vector3.ZERO
    var pos := Vector3.ZERO
    match side:
        "north":
            size = Vector3(length, CAPITAL.WALL_HEIGHT, CAPITAL.WALL_THICKNESS)
            pos = Vector3(center_offset, CAPITAL.WALL_HEIGHT * 0.5, -CAPITAL.HALF_EXTENT)
        "south":
            size = Vector3(length, CAPITAL.WALL_HEIGHT, CAPITAL.WALL_THICKNESS)
            pos = Vector3(center_offset, CAPITAL.WALL_HEIGHT * 0.5, CAPITAL.HALF_EXTENT)
        "east":
            size = Vector3(CAPITAL.WALL_THICKNESS, CAPITAL.WALL_HEIGHT, length)
            pos = Vector3(CAPITAL.HALF_EXTENT, CAPITAL.WALL_HEIGHT * 0.5, center_offset)
        "west":
            size = Vector3(CAPITAL.WALL_THICKNESS, CAPITAL.WALL_HEIGHT, length)
            pos = Vector3(-CAPITAL.HALF_EXTENT, CAPITAL.WALL_HEIGHT * 0.5, center_offset)
    _add_static_box("Wall_%s_%d" % [side, roundi(center_offset)], size, pos, wall_material, self)

func _build_gate(gate: Dictionary) -> void:
    var root := Node3D.new()
    root.name = "Gate_%s" % String(gate.get("id", "unknown"))
    var p: Vector2 = gate.get("position", Vector2.ZERO)
    root.position = Vector3(p.x, 0.0, p.y)
    match String(gate.get("side", "south")):
        "north": root.rotation.y = PI
        "east": root.rotation.y = PI * 0.5
        "west": root.rotation.y = -PI * 0.5
        _: root.rotation.y = 0.0
    add_child(root)

    var tower_x := CAPITAL.GATE_OPENING * 0.5 + CAPITAL.GATE_TOWER_SIZE * 0.5
    _add_static_box("TowerL", Vector3(CAPITAL.GATE_TOWER_SIZE, 28.0, CAPITAL.GATE_TOWER_SIZE), Vector3(-tower_x, 14.0, 0), tower_material, root)
    _add_static_box("TowerR", Vector3(CAPITAL.GATE_TOWER_SIZE, 28.0, CAPITAL.GATE_TOWER_SIZE), Vector3(tower_x, 14.0, 0), tower_material, root)
    _add_static_box("GateLintel", Vector3(CAPITAL.GATE_OPENING + 3.0, 7.0, 8.0), Vector3(0, 24.5, 0), wall_material, root)
    _add_static_box("Guardroom", Vector3(CAPITAL.GATE_OPENING + 12.0, 7.0, 14.0), Vector3(0, 3.5, -16.0), tower_material, root)

    var left_pivot := Node3D.new()
    left_pivot.name = "DoorPivotL"
    left_pivot.position = Vector3(-CAPITAL.GATE_OPENING * 0.5, 0, 0)
    root.add_child(left_pivot)
    _add_gate_door("DoorL", Vector3(CAPITAL.GATE_OPENING * 0.5, 8.0, 0.7), Vector3(CAPITAL.GATE_OPENING * 0.25, 4.0, 0), left_pivot)

    var right_pivot := Node3D.new()
    right_pivot.name = "DoorPivotR"
    right_pivot.position = Vector3(CAPITAL.GATE_OPENING * 0.5, 0, 0)
    root.add_child(right_pivot)
    _add_gate_door("DoorR", Vector3(CAPITAL.GATE_OPENING * 0.5, 8.0, 0.7), Vector3(-CAPITAL.GATE_OPENING * 0.25, 4.0, 0), right_pivot)

    var sign := Label3D.new()
    sign.name = "GateName"
    sign.text = String(gate.get("name", "Ворота"))
    sign.position = Vector3(0, 30.0, 0)
    sign.font_size = 28
    sign.outline_size = 7
    sign.no_depth_test = false
    root.add_child(sign)

    gate_runtime.append({
        "id": String(gate.get("id", "")),
        "left": left_pivot,
        "right": right_pivot,
        "root": root
    })

func _add_gate_door(node_name: String, size: Vector3, local_pos: Vector3, parent: Node3D) -> void:
    var body := AnimatableBody3D.new()
    body.name = node_name
    body.position = local_pos
    body.sync_to_physics = true
    parent.add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = wood_material
    mesh_instance.mesh = mesh
    body.add_child(mesh_instance)

    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)

    var band := MeshInstance3D.new()
    var band_mesh := BoxMesh.new()
    band_mesh.size = Vector3(size.x + 0.1, 0.35, size.z + 0.08)
    band_mesh.material = metal_material
    band.mesh = band_mesh
    body.add_child(band)

func _add_static_box(node_name: String, size: Vector3, pos: Vector3, material: Material, parent: Node3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    parent.add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_instance.mesh = mesh
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _apply_gate_state(opened: bool, immediate: bool) -> void:
    var angle := deg_to_rad(92.0) if opened else 0.0
    if immediate:
        for runtime in gate_runtime:
            var left: Node3D = runtime.get("left")
            var right: Node3D = runtime.get("right")
            if is_instance_valid(left):
                left.rotation.y = -angle
            if is_instance_valid(right):
                right.rotation.y = angle
    GameState.set_world_value("capital_gates_open", opened)

func is_gate_open(gate_id: String) -> bool:
    if CAPITAL.gate_by_id(gate_id).is_empty():
        return false
    return last_open_state

func can_build_at(world_pos: Vector3) -> bool:
    return CAPITAL.can_build_at(Vector2(world_pos.x, world_pos.z))

func _prepare_materials() -> void:
    wall_material = _material(Color(0.31, 0.34, 0.38), 0.91)
    tower_material = _material(Color(0.24, 0.27, 0.31), 0.93)
    wood_material = _material(Color(0.20, 0.105, 0.045), 0.92)
    metal_material = _material(Color(0.24, 0.28, 0.32), 0.52, 0.55)

func _material(color: Color, roughness_value: float, metallic_value: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    material.metallic = metallic_value
    return material
