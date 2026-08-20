extends StaticBody3D

func _ready() -> void:
    add_to_group("dungeon_manager")
    var xz := Vector2(global_position.x, global_position.z)
    if WorldData.inside_world(xz):
        global_position.y = WorldData.elevation_at(xz)
    _build_visual()

func interaction_text() -> String:
    return "E — управляющий подземельями"

func interact(_actor: Node = null) -> void:
    var panels := get_tree().get_first_node_in_group("gameplay_panels")
    if panels != null and panels.has_method("open_panel"):
        panels.call("open_panel", "dungeons")
        return
    GameState.notify(ProgressionSystem.dungeon_warning(ProgressionSystem.rank_name()))

func _build_visual() -> void:
    if get_node_or_null("CollisionShape3D") == null:
        var collision := CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        var shape := CapsuleShape3D.new()
        shape.radius = 0.48
        shape.height = 1.8
        collision.shape = shape
        collision.position.y = 0.9
        add_child(collision)

    var body := MeshInstance3D.new()
    body.name = "ManagerBody"
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.8
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.10, 0.16, 0.28)
    material.roughness = 0.72
    capsule.material = material
    body.mesh = capsule
    body.position.y = 0.9
    add_child(body)

    var head := MeshInstance3D.new()
    head.name = "Head"
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    sphere.height = 0.68
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.61, 0.45, 0.34)
    sphere.material = skin
    head.mesh = sphere
    head.position.y = 2.02
    add_child(head)

    var label := Label3D.new()
    label.name = "Nameplate"
    label.text = "Управляющий Вратами"
    label.position = Vector3(0, 2.75, 0)
    label.font_size = 26
    label.outline_size = 6
    label.modulate = Color(0.72, 0.90, 1.0)
    add_child(label)
