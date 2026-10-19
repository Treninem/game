extends Node3D

const CAPITAL := preload("res://scripts/capital_data.gd")

const LOAD_DISTANCE := 560.0
const UNLOAD_DISTANCE := 720.0
const CHECK_INTERVAL := 0.25
const MODULE_WIDTH := 2.0
const STORY_HEIGHT := 3.12

const ASSET_ROOT := "res://assets/production/medieval/quaternius_city_core/"
const ASSET_PATHS := {
    "wall_plaster": ASSET_ROOT + "Wall_Plaster_Straight.gltf",
    "door_plaster": ASSET_ROOT + "Wall_Plaster_Door_Round.gltf",
    "window_plaster": ASSET_ROOT + "Wall_Plaster_Window_Wide_Round.gltf",
    "wall_brick": ASSET_ROOT + "Wall_UnevenBrick_Straight.gltf",
    "door_brick": ASSET_ROOT + "Wall_UnevenBrick_Door_Round.gltf",
    "window_brick": ASSET_ROOT + "Wall_UnevenBrick_Window_Wide_Round.gltf",
    "roof": ASSET_ROOT + "Roof_RoundTiles_8x8.gltf",
    "wagon": ASSET_ROOT + "Prop_Wagon.gltf",
    "crate": ASSET_ROOT + "Prop_Crate.gltf"
}

var player: Node3D
var assets: Dictionary = {}
var loaded_landmarks: Dictionary = {}
var stone_material: StandardMaterial3D
var plaza_material: StandardMaterial3D
var gable_material: StandardMaterial3D
var elapsed := 0.0

func _ready() -> void:
    stone_material = _material(Color(0.33, 0.35, 0.37), 0.93)
    plaza_material = _material(Color(0.42, 0.41, 0.39), 0.94)
    gable_material = _material(Color.WHITE, 0.93)
    gable_material.albedo_texture = preload("res://assets/production/medieval/quaternius_city_core/T_Plaster_BaseColor.png")
    gable_material.uv1_triplanar = true
    gable_material.uv1_scale = Vector3.ONE * 0.35
    player = get_tree().get_first_node_in_group("player") as Node3D
    call_deferred("_refresh_landmarks")

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed < CHECK_INTERVAL:
        return
    elapsed = 0.0
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
    if player != null:
        _refresh_landmarks()

func _refresh_landmarks() -> void:
    if player == null:
        return
    var player_2d := Vector2(player.global_position.x, player.global_position.z)
    for anchor in CAPITAL.PROTECTED_ANCHORS:
        var landmark_id := String(anchor.get("id", ""))
        var anchor_pos: Vector2 = anchor.get("pos", Vector2.ZERO)
        var distance := player_2d.distance_to(CAPITAL.to_world(anchor_pos))
        if distance <= LOAD_DISTANCE and not loaded_landmarks.has(landmark_id):
            loaded_landmarks[landmark_id] = _build_landmark(anchor)
        elif distance > UNLOAD_DISTANCE and loaded_landmarks.has(landmark_id):
            var old_root: Node = loaded_landmarks.get(landmark_id)
            if is_instance_valid(old_root):
                old_root.queue_free()
            loaded_landmarks.erase(landmark_id)

func _build_landmark(anchor: Dictionary) -> Node3D:
    if assets.is_empty():
        _load_assets()
    var root := Node3D.new()
    var landmark_id := String(anchor.get("id", "landmark"))
    var anchor_pos: Vector2 = anchor.get("pos", Vector2.ZERO)
    root.name = "Landmark_%s" % landmark_id
    var world_pos := CAPITAL.to_world(anchor_pos)
    root.position = Vector3(world_pos.x, WorldData.elevation_at(world_pos), world_pos.y)
    add_child(root)

    match landmark_id:
        "town_hall":
            _build_town_hall(root)
        "treasury":
            _build_treasury(root)
        "guild_hall":
            _build_guild_hall(root)
        "gate_hall":
            _build_gate_hall(root)
        "guard_hq":
            _build_guard_hq(root)
        "royal_estate":
            _build_royal_estate(root)
        _:
            _build_house(root, Vector3.ZERO, 0.0, 2, false)
    _batch_repeated_modules(root)
    return root

func _batch_repeated_modules(root: Node3D) -> void:
    var groups: Dictionary = {}
    for visual: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
        if visual.mesh == null or visual.material_override != null:
            continue
        var has_override := false
        for surface in range(visual.mesh.get_surface_count()):
            has_override = has_override or visual.get_surface_override_material(surface) != null
        if has_override:
            continue
        var key := visual.mesh.get_instance_id()
        if not groups.has(key):
            groups[key] = []
        groups[key].append(visual)
    var inverse := root.global_transform.affine_inverse()
    for group: Array in groups.values():
        if group.size() < 2:
            continue
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.mesh = group[0].mesh
        instances.instance_count = group.size()
        for index in range(group.size()):
            var visual := group[index] as MeshInstance3D
            instances.set_instance_transform(index, inverse * visual.global_transform)
            visual.hide()
            visual.queue_free()
        var batch := MultiMeshInstance3D.new()
        batch.name = "FacadeBatch_%d" % root.get_child_count()
        batch.multimesh = instances
        root.add_child(batch)

func _build_town_hall(root: Node3D) -> void:
    _add_static_box("TownHallPlaza", Vector3(38, 0.18, 30), Vector3(0, 0.09, 0), plaza_material, root)
    _build_house(root, Vector3(0, 0.18, 0), 0.0, 3, false)
    _build_house(root, Vector3(-11, 0.18, 2), 0.0, 2, false)
    _build_house(root, Vector3(11, 0.18, 2), 0.0, 2, false)

func _build_treasury(root: Node3D) -> void:
    _add_static_box("TreasuryBase", Vector3(28, 0.28, 24), Vector3(0, 0.14, 0), stone_material, root)
    _build_house(root, Vector3(0, 0.28, 0), PI * 0.5, 3, true)
    for i in range(4):
        _instance_asset("crate", root, Vector3(-7.0 + i * 2.0, 0.36, 8.0), Vector3.ZERO)

func _build_guild_hall(root: Node3D) -> void:
    _add_static_box("GuildCourt", Vector3(34, 0.16, 28), Vector3(0, 0.08, 0), plaza_material, root)
    _build_house(root, Vector3(-6, 0.16, 0), 0.0, 3, false)
    _build_house(root, Vector3(7, 0.16, 2), 0.0, 2, false)
    _instance_asset("wagon", root, Vector3(10, 0.24, 10), Vector3(0, -0.45, 0))

func _build_gate_hall(root: Node3D) -> void:
    _add_static_box("GateHallCourt", Vector3(34, 0.16, 30), Vector3(0, 0.08, 0), stone_material, root)
    _build_house(root, Vector3(-9, 0.16, 0), 0.0, 3, true)
    _build_house(root, Vector3(9, 0.16, 0), 0.0, 3, true)
    _add_static_box("GateHallPath", Vector3(8, 0.10, 32), Vector3(0, 0.21, 0), plaza_material, root)

func _build_guard_hq(root: Node3D) -> void:
    _add_static_box("GuardYard", Vector3(44, 0.16, 38), Vector3(0, 0.08, 0), stone_material, root)
    _build_house(root, Vector3(0, 0.16, -8), 0.0, 2, true)
    _build_house(root, Vector3(-13, 0.16, 7), PI * 0.5, 2, true)
    _build_house(root, Vector3(13, 0.16, 7), -PI * 0.5, 2, true)
    for i in range(3):
        _instance_asset("crate", root, Vector3(-5 + i * 2.0, 0.24, 13), Vector3.ZERO)

func _build_royal_estate(root: Node3D) -> void:
    _add_static_box("RoyalCourt", Vector3(58, 0.20, 48), Vector3(0, 0.10, 0), plaza_material, root)
    _build_house(root, Vector3(0, 0.20, -4), 0.0, 3, false)
    _build_house(root, Vector3(-16, 0.20, 5), 0.0, 3, false)
    _build_house(root, Vector3(16, 0.20, 5), 0.0, 3, false)
    _add_static_box("RoyalWalk", Vector3(10, 0.12, 48), Vector3(0, 0.26, 20), stone_material, root)

func _build_house(parent: Node3D, pos: Vector3, yaw: float, stories: int, brick_style: bool) -> void:
    var building := Node3D.new()
    building.add_to_group("map_building")
    building.set_meta("map_footprint", Vector2(8, 8))
    building.position = pos
    building.rotation.y = yaw
    parent.add_child(building)

    var wall_key := "wall_brick" if brick_style else "wall_plaster"
    var door_key := "door_brick" if brick_style else "door_plaster"
    var window_key := "window_brick" if brick_style else "window_plaster"

    for story in range(stories):
        var y := float(story) * STORY_HEIGHT
        for i in range(4):
            var offset := -3.0 + float(i) * MODULE_WIDTH
            var front_key := wall_key
            if story == 0 and i == 1:
                front_key = door_key
            elif i == 0 or i == 3:
                front_key = window_key
            _instance_asset(front_key, building, Vector3(offset, y, 4.0), Vector3.ZERO)
            _instance_asset(window_key if (i == 1 or i == 2) else wall_key, building, Vector3(offset, y, -4.0), Vector3(0, PI, 0))
            _instance_asset(window_key if i % 2 == 0 else wall_key, building, Vector3(4.0, y, offset), Vector3(0, PI * 0.5, 0))
            _instance_asset(window_key if i % 2 == 1 else wall_key, building, Vector3(-4.0, y, offset), Vector3(0, -PI * 0.5, 0))

    _instance_asset("roof", building, Vector3(0, float(stories) * STORY_HEIGHT, 0), Vector3.ZERO)
    _add_gables(building, float(stories) * STORY_HEIGHT)
    _add_collision_box(
        Vector3(8.0, float(stories) * STORY_HEIGHT, 8.0),
        Vector3(0, float(stories) * STORY_HEIGHT * 0.5, 0),
        building
    )

func _add_gables(building: Node3D, height: float) -> void:
    # The authored roof contains tiles only; close both open attic ends.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_material(gable_material)
    for z: float in [-4.0, 4.0]:
        var corners := [Vector3(-4, height - 0.05, z), Vector3(0, height + 5.5, z), Vector3(4, height - 0.05, z)]
        if z < 0.0:
            corners.reverse()
        for corner: Vector3 in corners:
            surface.add_vertex(corner)
    surface.generate_normals()
    var gables := MeshInstance3D.new()
    gables.name = "AtticGables"
    gables.mesh = surface.commit()
    building.add_child(gables)

func _load_assets() -> void:
    for key in ASSET_PATHS.keys():
        var path := String(ASSET_PATHS[key])
        if not ResourceLoader.exists(path):
            continue
        var resource := load(path)
        if resource is PackedScene:
            assets[key] = resource

func _instance_asset(key: String, parent: Node3D, pos: Vector3, rotation: Vector3) -> Node3D:
    var packed: PackedScene = assets.get(key) as PackedScene
    if packed == null:
        return Node3D.new()
    var node := packed.instantiate() as Node3D
    if node == null:
        return Node3D.new()
    node.position = pos
    node.rotation = rotation
    parent.add_child(node)
    return node

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material

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

func _add_collision_box(size: Vector3, pos: Vector3, parent: Node3D) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = pos
    parent.add_child(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body
