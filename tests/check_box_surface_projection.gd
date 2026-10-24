extends SceneTree

func _initialize() -> void:
    create_timer(8).timeout.connect(func():
        push_error("Box surface projection unit watchdog expired")
        quit(1)
    )
    call_deferred("_run")

func _run() -> void:
    var projector: GDScript = load("res://scripts/box_surface_projection.gd")
    var cases := 0
    var vertices := 0
    for size: Vector3 in [Vector3(12, .18, 10), Vector3(.3, 3, .28), Vector3(4.2, 2.4, .28)]:
        for yaw: float in [0, PI * .5, PI, PI * 1.5]:
            for stretch: Vector3 in [Vector3.ONE, Vector3(1.5, .8, 2)]:
                var frame := Transform3D(Basis(Vector3.UP, yaw).scaled(stretch), Vector3(13455, -.125, -7030))
                var mesh: ArrayMesh = projector.build(size, frame, Vector3.ONE * .5, Vector3(.1, .2, .3))
                assert(mesh != null)
                var reference := BoxMesh.new()
                reference.size = size
                var expected := reference.get_mesh_arrays()
                var roundtrip := ArrayMesh.new()
                roundtrip.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, expected)
                var control := roundtrip.surface_get_arrays(0)
                var control_normals: PackedVector3Array = control[Mesh.ARRAY_NORMAL]
                var control_tangents: PackedFloat32Array = control[Mesh.ARRAY_TANGENT]
                var control_error := 0.0
                for index in range(control_normals.size()):
                    var tangent := Vector3(control_tangents[index * 4], control_tangents[index * 4 + 1], control_tangents[index * 4 + 2])
                    control_error = maxf(control_error, maxf(absf(tangent.length() - 1), absf(tangent.dot(control_normals[index]))))
                var actual := mesh.surface_get_arrays(0)
                assert(actual[Mesh.ARRAY_VERTEX] == expected[Mesh.ARRAY_VERTEX], "Projection changed physical surface vertices")
                assert(actual[Mesh.ARRAY_NORMAL] == expected[Mesh.ARRAY_NORMAL], "Projection changed face normals")
                assert(actual[Mesh.ARRAY_INDEX] == expected[Mesh.ARRAY_INDEX], "Projection changed triangle winding")
                var points: PackedVector3Array = actual[Mesh.ARRAY_VERTEX]
                var normals: PackedVector3Array = actual[Mesh.ARRAY_NORMAL]
                var uv: PackedVector2Array = actual[Mesh.ARRAY_TEX_UV]
                var tangents: PackedFloat32Array = actual[Mesh.ARRAY_TANGENT]
                for index in range(points.size()):
                    var tangent := Vector3(tangents[index * 4], tangents[index * 4 + 1], tangents[index * 4 + 2])
                    # The untouched BoxMesh roundtrip itself has3.05e-5 error
                    # in the engine's16bit tangent packing. Compare against
                    # that independent control plus two quantization units.
                    var error := maxf(absf(tangent.length() - 1), absf(tangent.dot(normals[index])))
                    if error > control_error + 2.0 / 65535.0:
                        print("TANGENT_CONTROL_FAILURE case=", cases, " vertex=", index, " normal=", normals[index], " tangent=", tangent, " error=", error, " untouched_control_error=", control_error)
                    assert(error <= control_error + 2.0 / 65535.0, "Projection degrades tangent precision beyond the untouched mesh control")
                    assert(absf(tangents[index * 4 + 3]) == 1)
                    # Independently check world metre distances along every
                    # same-face edge, including translated and scaled houses.
                    for other in range(index):
                        if normals[other] != normals[index]: continue
                        var world_distance := (frame * points[other]).distance_to(frame * points[index])
                        assert(absf(uv[other].distance_to(uv[index]) - world_distance * .5) < .0025,
                            "Texture density stretches with wall size or world transform")
                    vertices += 1
                cases += 1
    assert(projector.build(Vector3.ONE, Transform3D(Basis(Vector3.UP, .3), Vector3.ZERO), Vector3.ONE, Vector3.ZERO) == null,
        "A blended rotated face must retain the old triplanar path")
    var original := StandardMaterial3D.new()
    var texture := GradientTexture2D.new()
    original.albedo_texture = texture
    original.normal_texture = texture
    original.roughness_texture = texture
    original.normal_enabled = true
    original.ao_enabled = true
    original.uv1_scale = Vector3.ONE * .5
    original.uv1_triplanar = true
    original.uv1_world_triplanar = true
    var mapped: StandardMaterial3D = projector.material(original)
    assert(mapped.albedo_texture == texture and mapped.normal_texture == texture and mapped.roughness_texture == texture)
    assert(mapped.normal_enabled and mapped.ao_enabled and mapped.uv1_scale == Vector3.ONE)
    assert(original.uv1_triplanar and not mapped.uv1_triplanar)
    print("BOX_SURFACE_PROJECTION_OK cases=", cases, " vertices=", vertices, " existing_maps_retained=true rotated_fallback=true")
    quit(0)
