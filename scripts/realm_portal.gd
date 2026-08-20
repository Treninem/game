extends StaticBody3D

@export var realm_id := "ash_abyss"
@export var portal_name := "Разлом миров"

func _ready() -> void:
    add_to_group("realm_portal")
    var xz := Vector2(global_position.x, global_position.z)
    if realm_id != "main" and WorldData.inside_world(xz):
        global_position.y = WorldData.elevation_at(xz) + 0.05
    _ensure_visuals()

func configure(target_realm: String, title: String) -> void:
    realm_id = target_realm
    portal_name = title

func interaction_text() -> String:
    return "E — %s" % portal_name

func interact(actor: Node = null) -> void:
    var runtime := get_tree().get_first_node_in_group("realm_runtime")
    if runtime == null or not runtime.has_method("enter_realm"):
        GameState.notify("Разлом пока нестабилен.")
        return
    runtime.call("enter_realm", realm_id, actor)

func _ensure_visuals() -> void:
    if get_node_or_null("CollisionShape3D") == null:
        var collision := CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        var shape := CylinderShape3D.new()
        shape.radius = 1.35
        shape.height = 3.0
        collision.shape = shape
        collision.position.y = 1.5
        add_child(collision)
    if get_node_or_null("Visual") != null:
        return
    var visual := MeshInstance3D.new()
    visual.name = "Visual"
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.28
    var material := StandardMaterial3D.new()
    if realm_id == "echo_edge":
        material.albedo_color = Color(0.34, 0.10, 0.54)
        material.emission = Color(0.30, 0.04, 0.70)
    elif realm_id == "main":
        material.albedo_color = Color(0.08, 0.52, 0.68)
        material.emission = Color(0.03, 0.34, 0.74)
    else:
        material.albedo_color = Color(0.62, 0.12, 0.035)
        material.emission = Color(0.82, 0.06, 0.015)
    material.emission_enabled = true
    material.emission_energy_multiplier = 2.4
    material.roughness = 0.24
    mesh.material = material
    visual.mesh = mesh
    visual.rotation_degrees.x = 90.0
    visual.position.y = 1.65
    add_child(visual)
