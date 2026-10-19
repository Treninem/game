extends StaticBody3D

const NATURE := preload("res://scripts/production_nature.gd")
const TREE := preload("res://assets/production/nature/temperate/TemperateTree.glb")
const BUSH := preload("res://assets/production/nature/woodland/Bush_Common.glb")
const ROCK := preload("res://assets/production/nature/kenney_nature_kit/Models/GLTF format/rock_largeA.glb")
const ROCK_TEXTURE := preload("res://assets/production/materials/ground/lichen_rock.jpg")
const STUMP := preload("res://assets/production/nature/kenney_nature_kit/Models/GLTF format/stump_roundDetailed.glb")
const LOG := preload("res://assets/production/nature/kenney_nature_kit/Models/GLTF format/log_large.glb")
static var rock_material: StandardMaterial3D

var persistent_id := ""
var resource_id := "wood"
var display_name := "ресурс"
var amount_per_use := 1
var uses := 4
var visual_root: Node3D
var cuts := 0
var falling := false
var fallen := false
var stump: Node3D
var fallen_log: Node3D
var tree_scene: PackedScene = TREE
var tree_scale := 0.75
var contact_pending := false

func receive_melee_hit(player: Node3D) -> void:
    if resource_id != "wood":
        # Stones and soft plants still receive their ordinary surface effect;
        # adding the tree-contact handler must not swallow other melee impacts.
        var ray := player.get("interaction_ray") as RayCast3D
        if ray != null and ray.get_collider() == self:
            WorldVFX.spawn_impact("stone" if resource_id == "stone" else "grass", ray.get_collision_point(), ray.get_collision_normal(), -player.global_basis.z, 0.8)
        return
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != "starter_axe":
        GameState.notify("Для рубки нужен топор: экипируйте его в инвентаре (I).")
        return
    if uses <= 0 or falling or fallen or contact_pending:
        return
    # Resolve contact during the work stroke, never at button-down. Re-check
    # range, line of sight and equipment after the wind-up.
    contact_pending = true
    await get_tree().create_timer(0.24, false).timeout
    contact_pending = false
    if not is_instance_valid(player) or not is_inside_tree() or falling or fallen or uses <= 0 or GameState.is_dead:
        return
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != "starter_axe":
        return
    var point := global_position + Vector3.UP * 1.1
    if not player.call("_reachable_hit", self, point, 2.3):
        return
    var origin := player.global_position + Vector3.UP * 1.1
    var direction := (point - origin).normalized()
    var query := PhysicsRayQueryParameters3D.create(origin, point + direction * 0.1, 3, [(player as CollisionObject3D).get_rid()])
    var contact := get_world_3d().direct_space_state.intersect_ray(query)
    if contact.get("collider") != self:
        return
    var contact_point: Vector3 = contact["position"]
    # A third-person camera can see much farther than this short axe reaches.
    # Keep the stroke within arm + normalized 65 cm tool reach at the bark,
    # rather than granting a cut merely because the camera selects the trunk.
    if origin.distance_to(contact_point) > 1.35:
        GameState.notify("Подойдите ближе к стволу: топор не достаёт.")
        return
    cuts += 1
    GameState.set_world_value("tree_cuts:" + persistent_id, cuts)
    WorldVFX.spawn_impact("wood", contact_point, contact["normal"], direction, 0.5)
    var audio := get_tree().get_first_node_in_group("world_audio")
    if audio != null:
        audio.call("play_wood_hit", contact_point)
    if cuts >= 3:
        _fell(player.global_position)
    else:
        GameState.notify("Ствол надрублен: %d/3" % cuts)
        var sway := create_tween()
        sway.tween_property(visual_root, "rotation:x", 0.018, 0.08)
        sway.tween_property(visual_root, "rotation:x", 0.0, 0.18)

func _fell(source_position: Vector3) -> void:
    falling = true
    fallen = true
    GameState.set_world_value("tree_fallen:" + persistent_id, true)
    # The falling crown is visual; it must not become a rotating platform or
    # launch the player. A stable stump remains the collection target.
    for child in get_children():
        if child is CollisionShape3D:
            child.shape = child.shape.duplicate()
            (child.shape as CylinderShape3D).height = 0.45
            child.position.y = 0.225
    var away := global_position - source_position
    away.y = 0
    if away.length_squared() < 0.01:
        away = Vector3.FORWARD
    var local_away := global_basis.inverse() * away.normalized()
    var axis := Vector3.UP.cross(local_away).normalized()
    var fall := create_tween()
    fall.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    fall.tween_method(func(angle: float): visual_root.quaternion = Quaternion(axis, angle), 0.0, PI * 0.48, 1.35)
    fall.tween_callback(func():
        falling = false
        _apply_state()
        GameState.notify("Дерево срублено. Подойдите к пню и нажмите E, чтобы собрать древесину.")
    )

func configure(id_value: String, type_value: String, uses_value: int) -> void:
    persistent_id = id_value
    resource_id = type_value
    uses = uses_value
    match resource_id:
        "wood": display_name = "древесина"
        "stone": display_name = "камень"
        "berries": display_name = "ягоды"
        _: display_name = resource_id

func _ready() -> void:
    add_to_group("map_resource")
    if persistent_id.is_empty():
        persistent_id = String(name)
    uses = maxi(0, int(GameState.get_world_value("resource:" + persistent_id, uses)))
    cuts = maxi(0, int(GameState.get_world_value("tree_cuts:" + persistent_id, 0)))
    fallen = bool(GameState.get_world_value("tree_fallen:" + persistent_id, false))
    _build_visual()
    _apply_state()

func interact(_player: Node) -> void:
    if resource_id == "wood" and (not fallen or falling):
        GameState.notify("Рубка: экипируйте топор (I), подойдите к стволу и бейте ЛКМ.")
        return
    if uses <= 0:
        GameState.notify("Здесь больше нечего добывать.")
        return
    var received := uses * amount_per_use if resource_id == "wood" else amount_per_use
    GameState.add_item(resource_id, received)
    uses = 0 if resource_id == "wood" else uses - 1
    GameState.set_world_value("resource:" + persistent_id, uses)
    GameState.notify("Получено: %s +%d" % [display_name, received])
    _apply_state()

func _build_visual() -> void:
    visual_root = Node3D.new()
    visual_root.name = "Visual"
    add_child(visual_root)
    match resource_id:
        "stone": _build_stone()
        "berries": _build_bush()
        _: _build_tree()

func _build_tree() -> void:
    var model := tree_scene.instantiate() as Node3D
    model.name = "AuthoredResource"
    model.scale = Vector3.ONE * tree_scale
    visual_root.add_child(model)
    NATURE.prepare(model)

    var shape := CylinderShape3D.new()
    shape.radius = NATURE.trunk_radius(tree_scene) * tree_scale
    shape.height = 4.8
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 2.4
    add_child(collision)
    stump = STUMP.instantiate() as Node3D
    stump.name = "AuthoredStump"
    stump.scale = Vector3.ONE * 0.75
    add_child(stump)
    fallen_log = LOG.instantiate() as Node3D
    fallen_log.name = "AuthoredFallenLog"
    fallen_log.position.x = 0.65
    fallen_log.scale = Vector3.ONE * 0.9
    add_child(fallen_log)

func _build_stone() -> void:
    var stone := ROCK.instantiate() as Node3D
    stone.name = "AuthoredResource"
    stone.scale = Vector3.ONE * 1.4
    visual_root.add_child(stone)
    if rock_material == null:
        rock_material = _mat(Color.WHITE, 0.96)
        rock_material.albedo_texture = ROCK_TEXTURE
        rock_material.uv1_triplanar = true
        rock_material.uv1_world_triplanar = true
        rock_material.uv1_scale = Vector3.ONE * 0.65
    NATURE.apply_material(stone, rock_material)
    NATURE.add_model_collisions(self, [Transform3D(Basis.from_scale(Vector3.ONE * 1.4), Vector3.ZERO)], ROCK)

func _build_bush() -> void:
    var bush := BUSH.instantiate() as Node3D
    bush.name = "AuthoredResource"
    visual_root.add_child(bush)
    NATURE.prepare(bush)
    for offset in [Vector3(-0.35, 0.82, 0.35), Vector3(0.30, 0.75, 0.15), Vector3(0.05, 0.92, -0.38)]:
        var berry := MeshInstance3D.new()
        var berry_mesh := SphereMesh.new()
        berry_mesh.radius = 0.10
        berry_mesh.height = 0.20
        berry_mesh.radial_segments = 6
        berry_mesh.rings = 4
        berry_mesh.material = _mat(Color(0.58, 0.06, 0.14), 0.72)
        berry.mesh = berry_mesh
        berry.position = offset
        visual_root.add_child(berry)

    var shape := SphereShape3D.new()
    shape.radius = 0.95
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.65
    add_child(collision)

func _apply_state() -> void:
    var active := uses > 0
    if is_instance_valid(visual_root):
        visual_root.visible = active and not fallen
    if is_instance_valid(stump):
        stump.visible = fallen
        fallen_log.visible = fallen and active
        if fallen:
            for child in get_children():
                if child is CollisionShape3D:
                    child.shape = child.shape.duplicate()
                    (child.shape as CylinderShape3D).height = 0.45
                    child.position.y = 0.225
    # Soft foliage remains interactable without becoming an invisible platform.
    collision_layer = (2 if resource_id == "berries" or fallen else 1) if active or fallen else 0
    collision_mask = 1 if active or fallen else 0

func _mat(color: Color, roughness_value: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness_value
    return mat
