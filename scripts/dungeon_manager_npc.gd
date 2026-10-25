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

    var human := preload("res://scripts/humanoid_visual.gd").new()
    human.name = "ManagerHuman"
    human.palette_variant = 2
    human.has_guard_armor = true
    add_child(human)
