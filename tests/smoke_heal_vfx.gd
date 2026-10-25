extends Node3D

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var failures: Array[String] = []
    var effect := VFXLibrary.spawn("magic_heal", Vector3.ZERO, self)
    var reference: WeakRef = weakref(effect)
    var count := 0
    for node in effect.get_children():
        if node is MeshInstance3D and node.mesh is SphereMesh:
            failures.append("Healing contains an opaque glowing sphere")
        if not node is GPUParticles3D:
            continue
        count += node.amount
        var mesh: Mesh = node.draw_pass_1
        if not mesh is QuadMesh:
            failures.append("Healing motes use solid geometry instead of soft sprites")
            continue
        var material := mesh.material as StandardMaterial3D
        if material == null or material.albedo_texture == null or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or not material.vertex_color_use_as_albedo:
            failures.append("Healing sprite cannot apply texture/particle alpha")
        var process := node.process_material as ParticleProcessMaterial
        if process == null or process.color_ramp == null:
            failures.append("Healing has no lifetime fade")
        else:
            var gradient := (process.color_ramp as GradientTexture1D).gradient
            if gradient.sample(0).a > 0.01 or gradient.sample(1).a > 0.01 or gradient.sample(0.2).a < 0.5:
                failures.append("Healing fade does not start/end transparent")
        if not node.one_shot or node.lifetime > 1.5:
            failures.append("Healing emitters outlive the bounded one-shot budget")
    if count < 1 or count > 40:
        failures.append("Healing particle budget is invalid")
    effect.queue_free()
    await get_tree().process_frame
    await get_tree().create_timer(VFXLibrary.FX_LIFETIME_MAX + 0.15).timeout
    if reference.get_ref() != null:
        failures.append("Healing effect did not release after owner removal")
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("HEAL_VFX_OK soft_sprites=true fade=both_ends bounded_particles=", count, " owner_cleanup=safe")
    get_tree().quit(0 if failures.is_empty() else 1)
