extends Node3D

const PORTAL_SCRIPT := preload("res://scripts/realm_portal.gd")
const REALMS := {
    "ash_abyss": {
        "name": "Пепельная Бездна",
        "anchor": Vector2(-27000.0, 27000.0),
        "height": 96.0,
        "ground": Color(0.14, 0.055, 0.035),
        "accent": Color(0.78, 0.10, 0.025)
    },
    "echo_edge": {
        "name": "Край Эха",
        "anchor": Vector2(27000.0, 27000.0),
        "height": 118.0,
        "ground": Color(0.10, 0.075, 0.18),
        "accent": Color(0.46, 0.12, 0.72)
    }
}

var player: CharacterBody3D
var current_realm := "main"
var return_position := Vector3.ZERO
var return_valid := false
var realm_roots: Dictionary = {}

func _ready() -> void:
    add_to_group("realm_runtime")
    call_deferred("_recover_saved_realm")

func enter_realm(realm_id: String, actor: Node = null) -> bool:
    _resolve_player()
    var target_player: CharacterBody3D = player
    if actor is CharacterBody3D:
        target_player = actor as CharacterBody3D
    if target_player == null:
        return false
    if realm_id == "main":
        if not return_valid:
            _restore_saved_return_position()
        if not return_valid:
            return false
        target_player.global_position = return_position
        target_player.velocity = Vector3.ZERO
        current_realm = "main"
        GameState.set_world_value("current_realm", "main")
        GameState.set_location("Материк Импульса")
        if target_player.has_method("prepare_for_streamed_surface"):
            target_player.call("prepare_for_streamed_surface", false)
        return true
    if not REALMS.has(realm_id):
        return false
    if current_realm == "main":
        return_position = target_player.global_position
        return_valid = true
        GameState.set_world_value("realm_return_position", [return_position.x, return_position.y, return_position.z])
    _ensure_realm(realm_id)
    var root: Node3D = realm_roots[realm_id]
    target_player.global_position = root.global_position + Vector3(0, 2.0, 12.0)
    target_player.velocity = Vector3.ZERO
    current_realm = realm_id
    GameState.set_world_value("current_realm", realm_id)
    GameState.set_location(String(Dictionary(REALMS[realm_id]).get("name", realm_id)))
    GameState.notify("Вы вошли в изменённый мир: %s." % String(Dictionary(REALMS[realm_id]).get("name", realm_id)))
    return true

func realm_catalog() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for id in REALMS:
        var data: Dictionary = REALMS[id]
        rows.append({"id": String(id), "name": String(data.get("name", id)), "anchor": data.get("anchor", Vector2.ZERO)})
    return rows

func _recover_saved_realm() -> void:
    _resolve_player()
    _restore_saved_return_position()
    var saved := String(GameState.get_world_value("current_realm", "main"))
    if not REALMS.has(saved):
        current_realm = "main"
        return
    current_realm = saved
    _ensure_realm(saved)
    if player == null:
        return
    var root: Node3D = realm_roots[saved]
    if player.global_position.distance_to(root.global_position) > 90.0:
        player.global_position = root.global_position + Vector3(0, 2.0, 12.0)
        player.velocity = Vector3.ZERO
    GameState.set_location(String(Dictionary(REALMS[saved]).get("name", saved)))

func _restore_saved_return_position() -> void:
    var raw = GameState.get_world_value("realm_return_position", [])
    if raw is Array and raw.size() == 3:
        return_position = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
        return_valid = true

func _ensure_realm(realm_id: String) -> void:
    if realm_roots.has(realm_id) and is_instance_valid(realm_roots[realm_id]):
        return
    var data: Dictionary = REALMS[realm_id]
    var anchor: Vector2 = data.get("anchor", Vector2.ZERO)
    var base_height := float(data.get("height", 100.0))
    var root := Node3D.new()
    root.name = "Realm_" + realm_id
    root.global_position = Vector3(anchor.x, WorldData.elevation_at(anchor) + base_height, anchor.y)
    add_child(root)
    realm_roots[realm_id] = root

    var ground_color: Color = data.get("ground", Color(0.1, 0.1, 0.1))
    var accent: Color = data.get("accent", Color(0.4, 0.2, 0.7))
    _add_static_box("RealmFloor", Vector3(110, 2.0, 110), Vector3(0, -1.0, 0), ground_color, root)
    _add_static_box("IslandNorth", Vector3(34, 1.5, 28), Vector3(0, 4.0, -34), ground_color.lightened(0.08), root)
    _add_static_box("IslandWest", Vector3(28, 1.4, 24), Vector3(-34, 7.0, 4), ground_color.lightened(0.04), root)
    _add_static_box("IslandEast", Vector3(26, 1.6, 30), Vector3(35, 10.0, 5), ground_color.lightened(0.12), root)
    _add_bridge(Vector3(0, 2.0, -21), Vector3(7.0, 0.6, 24.0), accent, root)
    _add_bridge(Vector3(-21, 4.0, 2), Vector3(24.0, 0.6, 6.5), accent, root)
    _add_bridge(Vector3(22, 5.0, 3), Vector3(25.0, 0.6, 6.5), accent, root)

    for i in range(9):
        var angle := TAU * float(i) / 9.0
        var radius := 18.0 + float((i * 7) % 20)
        var pillar_pos := Vector3(cos(angle) * radius, 4.0 + float(i % 3) * 2.0, sin(angle) * radius)
        _add_static_box("RealmPillar_%02d" % i, Vector3(2.2, 8.0 + float(i % 3) * 4.0, 2.2), pillar_pos, accent.darkened(0.20), root)

    var return_portal := StaticBody3D.new()
    return_portal.name = "ReturnPortal"
    return_portal.position = Vector3(0, 0.1, 17.0)
    return_portal.set_script(PORTAL_SCRIPT)
    return_portal.call("configure", "main", "Возврат на материк")
    root.add_child(return_portal)

    var label := Label3D.new()
    label.name = "RealmName"
    label.text = String(data.get("name", realm_id))
    label.position = Vector3(0, 8.0, -8.0)
    label.font_size = 44
    label.outline_size = 8
    label.modulate = accent.lightened(0.30)
    root.add_child(label)

func _add_bridge(pos: Vector3, size: Vector3, color: Color, parent: Node3D) -> void:
    _add_static_box("RealmBridge", size, pos, color, parent)

func _add_static_box(node_name: String, size: Vector3, pos: Vector3, color: Color, parent: Node3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    parent.add_child(body)
    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.82
    if color.r > 0.4 or color.b > 0.4:
        material.emission_enabled = true
        material.emission = color.darkened(0.30)
        material.emission_energy_multiplier = 0.8
    mesh.material = material
    mesh_node.mesh = mesh
    body.add_child(mesh_node)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _resolve_player() -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
