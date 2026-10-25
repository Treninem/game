extends RefCounted

# Keep imported meshes (and their GPU morph buffers) immutable. Each held bow
# owns only its blend weights; inventory and other actors keep their rest pose.
var model: Node3D
var flex_meshes: Array[MeshInstance3D] = []
var shape_indices: Array[int] = []
var ends: Array[Dictionary] = []
var draw_amount := 0.0

func bind_model(value: Node3D) -> void:
    model = value
    flex_meshes.clear()
    shape_indices.clear()
    ends.clear()
    draw_amount = 0.0
    var cord := model.find_child("RestCord", true, false) as MeshInstance3D
    assert(cord != null, "Authored bow must separate its rest cord")
    cord.hide()
    for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        var index := part.find_blend_shape_by_name("Draw")
        if index >= 0:
            flex_meshes.append(part)
            shape_indices.append(index)
    assert(flex_meshes.size() == 3, "Bow limbs and both horn nocks must retain Draw")
    for pair: Array in [["TopStringNock", "HornNockTop"], ["BottomStringNock", "HornNockBottom"]]:
        var anchor := model.find_child(pair[0], true, false) as Node3D
        var horn := model.find_child(pair[1], true, false) as MeshInstance3D
        assert(anchor != null and horn != null)
        # Bind once to the closest actual horn vertex. Its imported morph
        # displacement carries the cord seat with the rendered nock, including
        # future Blender edits; no per-frame surface scans or guessed arc.
        var point := horn.to_local(anchor.global_position)
        var nearest := INF
        var displacement := Vector3.ZERO
        var mesh := horn.mesh as ArrayMesh
        var index := horn.find_blend_shape_by_name("Draw")
        for surface in range(mesh.get_surface_count()):
            var base: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
            var shape: PackedVector3Array = mesh.surface_get_blend_shape_arrays(surface)[index][Mesh.ARRAY_VERTEX]
            for vertex in range(base.size()):
                var distance := base[vertex].distance_squared_to(point)
                if distance < nearest:
                    nearest = distance
                    displacement = shape[vertex]
                    if mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED:
                        displacement -= base[vertex]
        assert(nearest < 0.0001, "Cord seat is detached from its authored horn")
        ends.append({"horn": horn, "point": point, "displacement": displacement})

func apply_draw(fingers: Vector3, drawing: bool) -> void:
    var rest := (top_world_at(0.0) + bottom_world_at(0.0)) * 0.5
    draw_amount = clampf(rest.distance_to(fingers) / 0.45, 0.0, 1.0) if drawing else 0.0
    for i in range(flex_meshes.size()):
        flex_meshes[i].set_blend_shape_value(shape_indices[i], draw_amount)

func top_world_at(amount: float) -> Vector3:
    return _endpoint(0, amount)

func bottom_world_at(amount: float) -> Vector3:
    return _endpoint(1, amount)

func top_world() -> Vector3:
    return top_world_at(draw_amount)

func bottom_world() -> Vector3:
    return bottom_world_at(draw_amount)

func _endpoint(index: int, amount: float) -> Vector3:
    var end := ends[index]
    return (end.horn as Node3D).to_global((end.point as Vector3) + (end.displacement as Vector3) * amount)
