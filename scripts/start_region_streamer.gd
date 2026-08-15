extends Node3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const NATURE_ROOT := "res://assets/staging/nature/kenney_nature_kit/Models/GLTF format/"
const TREE_OAK: PackedScene = preload(NATURE_ROOT + "tree_oak.glb")
const TREE_DETAILED: PackedScene = preload(NATURE_ROOT + "tree_detailed.glb")
const TREE_PINE: PackedScene = preload(NATURE_ROOT + "tree_pineDefaultA.glb")
const BUSH_DETAILED: PackedScene = preload(NATURE_ROOT + "plant_bushDetailed.glb")
const GRASS_LARGE: PackedScene = preload(NATURE_ROOT + "grass_large.glb")
const ROCK_LARGE: PackedScene = preload(NATURE_ROOT + "rock_largeA.glb")
const LOG_LARGE: PackedScene = preload(NATURE_ROOT + "log_large.glb")
const STUMP_DETAIL: PackedScene = preload(NATURE_ROOT + "stump_roundDetailed.glb")
const MUSHROOMS: PackedScene = preload(NATURE_ROOT + "mushroom_tanGroup.glb")

const RIVER_Z_MIN := -1700.0
const RIVER_Z_MAX := 1700.0
const RIVER_SEGMENT_LENGTH := 100.0
const RIVER_WIDTH := GEOGRAPHY.START_RIVER_HALF_WIDTH * 2.0
const FORD_Z := -760.0
const FORD_STONE_COUNT := 11
const NATURE_SEED := 150826
const DETAIL_RADIUS_MIN := 32.0
const DETAIL_RADIUS_MAX := 250.0

var river_segment_count: int = 0
var ford_stone_count: int = 0
var real_tree_count: int = 0
var real_nature_detail_count: int = 0
var water_material: StandardMaterial3D
var stone_material: StandardMaterial3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED
    water_material = _make_water_material()
    stone_material = _make_material(Color(0.30, 0.31, 0.30), 0.96)
    _build_river()
    _build_old_ford()
    _build_real_nature_detail()

func _build_river() -> void:
    var river_root := Node3D.new()
    river_root.name = "StartRiver"
    add_child(river_root)

    var z := RIVER_Z_MIN
    var index := 0
    while z < RIVER_Z_MAX:
        var next_z := minf(z + RIVER_SEGMENT_LENGTH, RIVER_Z_MAX)
        var p0 := Vector2(GEOGRAPHY.start_river_x(z), z)
        var p1 := Vector2(GEOGRAPHY.start_river_x(next_z), next_z)
        var delta := p1 - p0
        var center := (p0 + p1) * 0.5

        var water := MeshInstance3D.new()
        water.name = "RiverWater_%02d" % index
        var mesh := BoxMesh.new()
        mesh.size = Vector3(RIVER_WIDTH, 0.06, delta.length() + 5.0)
        mesh.material = water_material
        water.mesh = mesh
        water.position = Vector3(center.x, GEOGRAPHY.START_RIVER_WATER_LEVEL, center.y)
        water.rotation.y = atan2(delta.x, delta.y)
        water.visibility_range_end = 980.0
        river_root.add_child(water)

        river_segment_count += 1
        index += 1
        z = next_z

func _build_old_ford() -> void:
    var ford_root := Node3D.new()
    ford_root.name = "OldFord"
    add_child(ford_root)

    var river_x := GEOGRAPHY.start_river_x(FORD_Z)
    var width := RIVER_WIDTH + 10.0
    for i in range(FORD_STONE_COUNT):
        var t := float(i) / float(FORD_STONE_COUNT - 1)
        var x := river_x - width * 0.5 + width * t
        var z_offset := sin(float(i) * 1.37) * 1.8
        var size := Vector3(4.6 + float(i % 3) * 0.7, 0.65, 4.1 + float((i + 1) % 3) * 0.6)
        var body := StaticBody3D.new()
        body.name = "FordStone_%02d" % i
        body.position = Vector3(x, GEOGRAPHY.START_RIVER_WATER_LEVEL + 0.15, FORD_Z + z_offset)
        body.rotation.y = float(i) * 0.31
        ford_root.add_child(body)

        var mesh_node := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = size
        mesh.material = stone_material
        mesh_node.mesh = mesh
        body.add_child(mesh_node)

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        ford_stone_count += 1

func _build_real_nature_detail() -> void:
    var detail_root := Node3D.new()
    detail_root.name = "RealNatureDetails"
    add_child(detail_root)

    var rng := RandomNumberGenerator.new()
    rng.seed = NATURE_SEED
    var tree_scenes: Array[PackedScene] = [TREE_OAK, TREE_DETAILED, TREE_PINE]

    # A small number of actual licensed models form the near-camera layer. The
    # chunk streamer keeps MultiMesh forest in the middle/far distance.
    for i in range(24):
        var world := _sample_detail_position(rng, 55.0, DETAIL_RADIUS_MAX, 18.0)
        if world == Vector2.INF:
            continue
        var scene := tree_scenes[i % tree_scenes.size()]
        var scale_value := rng.randf_range(1.35, 2.15)
        _spawn_physical_tree(detail_root, scene, world, scale_value, rng.randf_range(-PI, PI), i)

    for i in range(12):
        var world := _sample_detail_position(rng, DETAIL_RADIUS_MIN, 180.0, 7.0)
        if world != Vector2.INF:
            _spawn_visual(detail_root, BUSH_DETAILED, world, rng.randf_range(0.85, 1.45), rng.randf_range(-PI, PI), "Bush", i)

    for i in range(18):
        var world := _sample_detail_position(rng, DETAIL_RADIUS_MIN, 150.0, 5.0)
        if world != Vector2.INF:
            _spawn_visual(detail_root, GRASS_LARGE, world, rng.randf_range(0.70, 1.20), rng.randf_range(-PI, PI), "Grass", i)

    for i in range(8):
        var world := _sample_detail_position(rng, 45.0, 210.0, 5.0)
        if world != Vector2.INF:
            _spawn_visual(detail_root, ROCK_LARGE, world, rng.randf_range(0.75, 1.25), rng.randf_range(-PI, PI), "Rock", i)

    for i in range(4):
        var world := _sample_detail_position(rng, 52.0, 190.0, 6.0)
        if world != Vector2.INF:
            _spawn_visual(detail_root, LOG_LARGE if i % 2 == 0 else STUMP_DETAIL, world, rng.randf_range(0.9, 1.3), rng.randf_range(-PI, PI), "Deadwood", i)

    for i in range(9):
        var world := _sample_detail_position(rng, 36.0, 135.0, 3.0)
        if world != Vector2.INF:
            _spawn_visual(detail_root, MUSHROOMS, world, rng.randf_range(0.8, 1.15), rng.randf_range(-PI, PI), "Mushroom", i)

func _sample_detail_position(rng: RandomNumberGenerator, min_radius: float, max_radius: float, river_clearance: float) -> Vector2:
    for _attempt in range(24):
        var angle := rng.randf_range(-PI, PI)
        var radius := sqrt(rng.randf_range(min_radius * min_radius, max_radius * max_radius))
        var world := GEOGRAPHY.START_SPAWN + Vector2(cos(angle), sin(angle)) * radius
        if GEOGRAPHY.distance_to_start_river(world) < GEOGRAPHY.START_RIVER_BANK_WIDTH + river_clearance:
            continue
        return world
    return Vector2.INF

func _spawn_physical_tree(parent: Node3D, scene: PackedScene, world: Vector2, scale_value: float, yaw: float, index: int) -> void:
    var body := StaticBody3D.new()
    body.name = "RealTree_%02d" % index
    body.position = Vector3(world.x, WorldData.elevation_at(world), world.y)
    body.rotation.y = yaw
    parent.add_child(body)

    var visual := scene.instantiate() as Node3D
    if visual != null:
        visual.name = "Model"
        visual.scale = Vector3.ONE * scale_value
        body.add_child(visual)

    var collision := CollisionShape3D.new()
    collision.name = "TrunkCollision"
    var trunk := CylinderShape3D.new()
    trunk.radius = 0.30 * scale_value
    trunk.height = 2.5 * scale_value
    collision.shape = trunk
    collision.position.y = trunk.height * 0.5
    body.add_child(collision)
    real_tree_count += 1
    real_nature_detail_count += 1

func _spawn_visual(parent: Node3D, scene: PackedScene, world: Vector2, scale_value: float, yaw: float, prefix: String, index: int) -> void:
    var visual := scene.instantiate() as Node3D
    if visual == null:
        return
    visual.name = "%s_%02d" % [prefix, index]
    visual.position = Vector3(world.x, WorldData.elevation_at(world), world.y)
    visual.rotation.y = yaw
    visual.scale = Vector3.ONE * scale_value
    parent.add_child(visual)
    real_nature_detail_count += 1

func _make_water_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.045, 0.24, 0.34, 0.74)
    material.roughness = 0.16
    material.metallic = 0.02
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _make_material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
