extends StaticBody3D

@export var portal_name := "Врата подземелий"

func _ready() -> void:
    add_to_group("dungeon_portal")
    _ensure_visuals()

func interaction_text() -> String:
    return "E — %s" % portal_name

func interact(_actor: Node = null) -> void:
    var panels := get_tree().get_first_node_in_group("gameplay_panels")
    if panels != null and panels.has_method("open_panel"):
        panels.call("open_panel", "dungeons")
        return
    var result := ProgressionSystem.start_dungeon(ProgressionSystem.rank_name())
    if not bool(result.get("ok", false)):
        GameState.notify("Врата пока не открываются.")

func _ensure_visuals() -> void:
    if get_node_or_null("CollisionShape3D") == null:
        var collision := CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        var shape := CylinderShape3D.new()
        shape.radius = 1.6
        shape.height = 3.2
        collision.shape = shape
        collision.position.y = 1.6
        add_child(collision)

    if get_node_or_null("PortalVisual") == null:
        var ring := MeshInstance3D.new()
        ring.name = "PortalVisual"
        var mesh := TorusMesh.new()
        mesh.inner_radius = 1.0
        mesh.outer_radius = 1.42
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.06, 0.42, 0.64, 1.0)
        material.emission_enabled = true
        material.emission = Color(0.02, 0.30, 0.72, 1.0)
        material.emission_energy_multiplier = 2.6
        material.metallic = 0.35
        material.roughness = 0.25
        mesh.material = material
        ring.mesh = mesh
        ring.rotation_degrees.x = 90.0
        ring.position.y = 1.8
        add_child(ring)

        var core := MeshInstance3D.new()
        core.name = "PortalCore"
        var core_mesh := CylinderMesh.new()
        core_mesh.top_radius = 1.0
        core_mesh.bottom_radius = 1.0
        core_mesh.height = 0.06
        var core_material := StandardMaterial3D.new()
        core_material.albedo_color = Color(0.02, 0.16, 0.30, 0.55)
        core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        core_material.emission_enabled = true
        core_material.emission = Color(0.02, 0.28, 0.58, 1.0)
        core_material.emission_energy_multiplier = 1.8
        core_mesh.material = core_material
        core.mesh = core_mesh
        core.rotation_degrees.x = 90.0
        core.position.y = 1.8
        add_child(core)
