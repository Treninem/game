extends Node3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const PRODUCTION_NATURE := preload("res://scripts/production_nature.gd")
const NATURE_ROOT := "res://assets/production/nature/kenney_nature_kit/Models/GLTF format/"
const TREE_OAK: PackedScene = preload("res://assets/production/nature/temperate/TemperateTree.glb")
const TREE_BROAD: PackedScene = preload("res://assets/production/nature/temperate/TemperateTree_Broad.glb")
const TREE_PALETTE := [TREE_OAK, TREE_BROAD]
const TREE_TRUNK_CLEARANCE := 5.5
const EXTRA_TREE_CANDIDATES := 24
const GROUND_COVER_GRID := 40
const MAX_DETAIL_OBJECTS := 164 + EXTRA_TREE_CANDIDATES + 8 + 24 + GROUND_COVER_GRID * GROUND_COVER_GRID
const GROUND_GRASS: PackedScene = preload("res://assets/production/nature/meadow/MeadowGrass.glb")
const BUSH_DETAILED: PackedScene = preload("res://assets/production/nature/temperate/TemperateBush.glb")
const GRASS_LARGE: PackedScene = preload("res://assets/production/nature/woodland/Grass_Wispy_Tall.glb")
const ROCK_LARGE: PackedScene = preload(NATURE_ROOT + "rock_largeA.glb")
const LOG_LARGE: PackedScene = preload(NATURE_ROOT + "log_large.glb")
const STUMP_DETAIL: PackedScene = preload(NATURE_ROOT + "stump_roundDetailed.glb")
const MUSHROOMS: PackedScene = preload(NATURE_ROOT + "mushroom_tanGroup.glb")
const FERN: PackedScene = preload("res://assets/production/nature/woodland/Fern_1.glb")

const RIVER_Z_MIN := -1700.0
const RIVER_Z_MAX := 1700.0
const RIVER_SEGMENT_LENGTH := 100.0
const RIVER_WIDTH := GEOGRAPHY.START_RIVER_HALF_WIDTH * 2.0
const FORD_Z := -760.0
const FORD_STONE_COUNT := 11

# Production models are the near-camera layer only. The global WorldStreamer
# keeps lightweight MultiMesh vegetation in the middle/far distance.
const NATURE_SEED := 150826
const DETAIL_CELL_SIZE := 96.0
const DETAIL_RADIUS := 2
const DETAIL_CELLS_PER_FRAME := 1
const DETAIL_TREE_VISIBILITY := 150.0
const DETAIL_SMALL_VISIBILITY := 85.0
const DETAIL_CELL_SENTINEL := Vector2i(999999, 999999)

var river_segment_count: int = 0
var ford_stone_count: int = 0
var real_tree_count: int = 0
var real_nature_detail_count: int = 0
var water_material: ShaderMaterial
var stone_material: StandardMaterial3D

var player: Node3D
var detail_root: Node3D
var current_detail_center: Vector2i = DETAIL_CELL_SENTINEL
var loaded_detail_cells: Dictionary = {}
var detail_generation_queue: Array[Vector2i] = []
var exclusion_zones: Array[Dictionary] = []

func _ready() -> void:
    process_priority = 60
    water_material = _make_water_material()
    stone_material = _make_material(Color(0.30, 0.31, 0.30), 0.96)
    _cache_exclusion_zones()
    _build_river()
    _build_old_ford()
    call_deferred("_build_real_nature_detail")

func _process(_delta: float) -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
        if player == null:
            return

    var pos := Vector2(player.global_position.x, player.global_position.z)
    if not GEOGRAPHY.in_start_region(pos):
        if not loaded_detail_cells.is_empty():
            _clear_detail_cells()
        current_detail_center = DETAIL_CELL_SENTINEL
        detail_generation_queue.clear()
        return

    var center := _world_to_detail_cell(pos)
    if center != current_detail_center:
        current_detail_center = center
        if not loaded_detail_cells.has(center):
            _generate_detail_cell(center)
        _refresh_detail_streaming(center)

    var generated := 0
    while generated < DETAIL_CELLS_PER_FRAME and not detail_generation_queue.is_empty():
        var coord: Vector2i = detail_generation_queue.pop_front()
        if not loaded_detail_cells.has(coord) and _detail_cell_intersects_start_region(coord):
            _generate_detail_cell(coord)
            generated += 1

func _build_river() -> void:
    var river_root := Node3D.new()
    river_root.name = "StartRiver"
    add_child(river_root)

    var z := RIVER_Z_MIN
    var index := 0
    while z < RIVER_Z_MAX:
        var next_z := minf(z + RIVER_SEGMENT_LENGTH, RIVER_Z_MAX)
        var water := MeshInstance3D.new()
        water.name = "RiverWater_%02d" % index
        var surface := SurfaceTool.new()
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        var slices := 25
        for step in range(slices + 1):
            var sample_z := lerpf(z, next_z, float(step) / float(slices))
            for side in [-1.0, 1.0]:
                surface.set_uv(Vector2(side, sample_z * 0.05))
                surface.add_vertex(Vector3(GEOGRAPHY.start_river_x(sample_z) + side * RIVER_WIDTH * 0.5, GEOGRAPHY.START_RIVER_WATER_LEVEL, sample_z))
        for step in range(slices):
            var index0 := step * 2
            for vertex_index in [index0, index0 + 1, index0 + 2, index0 + 1, index0 + 3, index0 + 2]:
                surface.add_index(vertex_index)
        surface.generate_normals()
        water.mesh = surface.commit()
        water.material_override = water_material
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

# Kept under the original method name because loading/readiness tests and older
# development fixtures may call it directly. It now bootstraps a bounded player-
# following detail streamer instead of building one permanent spawn-only patch.
func _build_real_nature_detail() -> void:
    if detail_root == null or not is_instance_valid(detail_root):
        detail_root = Node3D.new()
        detail_root.name = "RealNatureDetails"
        add_child(detail_root)

    player = get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    var pos := Vector2(player.global_position.x, player.global_position.z)
    if not GEOGRAPHY.in_start_region(pos):
        return

    current_detail_center = _world_to_detail_cell(pos)
    _generate_detail_cell(current_detail_center)
    _refresh_detail_streaming(current_detail_center)

func _refresh_detail_streaming(center: Vector2i) -> void:
    detail_generation_queue.clear()

    # Ring order gives the player the closest production models first while the
    # one-cell-per-frame budget prevents traversal spikes.
    for ring in range(0, DETAIL_RADIUS + 1):
        for x in range(center.x - ring, center.x + ring + 1):
            for z in range(center.y - ring, center.y + ring + 1):
                var coord := Vector2i(x, z)
                if maxi(absi(coord.x - center.x), absi(coord.y - center.y)) != ring:
                    continue
                if not _detail_cell_intersects_start_region(coord):
                    continue
                if not loaded_detail_cells.has(coord):
                    detail_generation_queue.append(coord)

    var to_remove: Array[Vector2i] = []
    for key: Variant in loaded_detail_cells.keys():
        var coord: Vector2i = key as Vector2i
        if _distance_cells(coord, center) > DETAIL_RADIUS or not _detail_cell_intersects_start_region(coord):
            to_remove.append(coord)
    for coord: Vector2i in to_remove:
        _unload_detail_cell(coord)

func _generate_detail_cell(coord: Vector2i) -> void:
    if loaded_detail_cells.has(coord) or not _detail_cell_intersects_start_region(coord):
        return
    if detail_root == null or not is_instance_valid(detail_root):
        detail_root = Node3D.new()
        detail_root.name = "RealNatureDetails"
        add_child(detail_root)

    var cell := Node3D.new()
    cell.name = "DetailCell_%d_%d" % [coord.x, coord.y]
    detail_root.add_child(cell)

    cell.set_meta("visual_batches", {})
    var counts := _populate_detail_cell(cell, coord)
    _materialize_visual_batches(cell)
    cell.set_meta("tree_count", int(counts.get("trees", 0)))
    cell.set_meta("detail_count", int(counts.get("details", 0)))
    loaded_detail_cells[coord] = cell
    real_tree_count += int(counts.get("trees", 0))
    real_nature_detail_count += int(counts.get("details", 0))

func _populate_detail_cell(cell: Node3D, coord: Vector2i) -> Dictionary:
    var center := _detail_cell_center(coord)
    if not GEOGRAPHY.in_start_region(center) and not _detail_cell_intersects_start_region(coord):
        return {"trees":0, "details":0}

    var biome := WorldData.biome_at(center)
    if biome == "ocean":
        return {"trees":0, "details":0}

    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("start_detail:%d:%d:%d" % [coord.x, coord.y, NATURE_SEED]))
    var tree_scenes: Array[PackedScene] = []
    tree_scenes.assign(TREE_PALETTE)
    var tree_target := 14
    match biome:
        "forest": tree_target = 18
        "taiga": tree_target = 18
        "marsh": tree_target = 18
        "plains": tree_target = 14
        "tundra", "drylands", "mountains": tree_target = 5

    var trees := 0
    var details := 0
    var accepted_roots: Array[Vector2] = []
    for i in range(tree_target):
        var world := _sample_cell_position(rng, coord, 17.0, 6.0)
        if world == Vector2.INF:
            continue
        var scene := tree_scenes[rng.randi_range(0, tree_scenes.size() - 1)]
        var tree_scale := rng.randf_range(0.80, 1.18)
        var yaw := rng.randf_range(-PI, PI)
        var crowded := false
        for root_pos in accepted_roots:
            if root_pos.distance_squared_to(world) < TREE_TRUNK_CLEARANCE * TREE_TRUNK_CLEARANCE:
                crowded = true
                break
        # Consume the existing candidate's random values before skipping it.
        # Later roots/IDs stay stable; do not relocate a saved tree elsewhere.
        if crowded:
            continue
        if _spawn_physical_tree(cell, scene, world, tree_scale, yaw, i):
            accepted_roots.append(world)
            trees += 1
            details += 1

    for i in range(4):
        var bush_world := _sample_cell_position(rng, coord, 7.0, 3.5)
        if bush_world != Vector2.INF and _spawn_visual(cell, BUSH_DETAILED, bush_world, rng.randf_range(0.70, 1.15), rng.randf_range(-PI, PI), "Bush", i, DETAIL_SMALL_VISIBILITY):
            details += 1

    for i in range(120):
        var grass_world := _sample_cell_position(rng, coord, 4.0, 2.0, 2.0)
        if grass_world != Vector2.INF and _spawn_visual(cell, GRASS_LARGE, grass_world, rng.randf_range(0.65, 1.15), rng.randf_range(-PI, PI), "Grass", i, DETAIL_SMALL_VISIBILITY):
            details += 1

    if biome in ["forest", "taiga", "marsh"]:
        for i in range(16):
            var fern_world := _sample_cell_position(rng, coord, 5.0, 2.0)
            if fern_world != Vector2.INF and _spawn_visual(cell, FERN, fern_world, rng.randf_range(0.75, 1.25), rng.randf_range(-PI, PI), "Fern", i, 150.0):
                details += 1

    if rng.randf() < 0.55:
        var rock_world := _sample_cell_position(rng, coord, 5.0, 2.5)
        if rock_world != Vector2.INF and _spawn_visual(cell, ROCK_LARGE, rock_world, rng.randf_range(0.70, 1.20), rng.randf_range(-PI, PI), "Rock", 0, DETAIL_SMALL_VISIBILITY):
            details += 1

    if rng.randf() < 0.30:
        var deadwood_world := _sample_cell_position(rng, coord, 6.0, 3.0)
        var deadwood_scene: PackedScene = LOG_LARGE if rng.randf() < 0.5 else STUMP_DETAIL
        if deadwood_world != Vector2.INF and _spawn_visual(cell, deadwood_scene, deadwood_world, rng.randf_range(0.85, 1.25), rng.randf_range(-PI, PI), "Deadwood", 0, DETAIL_SMALL_VISIBILITY):
            details += 1

    if biome in ["forest", "taiga", "marsh"] and rng.randf() < 0.55:
        var mushroom_world := _sample_cell_position(rng, coord, 3.0, 1.5)
        if mushroom_world != Vector2.INF and _spawn_visual(cell, MUSHROOMS, mushroom_world, rng.randf_range(0.75, 1.10), rng.randf_range(-PI, PI), "Mushroom", 0, 190.0):
            details += 1

    # A separate stream appends vegetation without relocating the legacy trees,
    # changing their persistent IDs or consuming their decoration RNG sequence.
    var extra_rng := RandomNumberGenerator.new()
    extra_rng.seed = absi(hash("understory:%d:%d:%d" % [coord.x,coord.y,NATURE_SEED]))
    var extra_trees := 0
    if biome in ["forest","taiga","marsh","plains"]:
        for i in range(EXTRA_TREE_CANDIDATES):
            var world := _sample_cell_position(extra_rng,coord,10.0,4.0)
            if world == Vector2.INF:
                continue
            var crowded := false
            var grove_distance := INF
            for root_pos in accepted_roots:
                var distance := root_pos.distance_squared_to(world)
                grove_distance = minf(grove_distance,distance)
                if distance < TREE_TRUNK_CLEARANCE * TREE_TRUNK_CLEARANCE:
                    crowded = true
                    break
            if crowded or (not accepted_roots.is_empty() and grove_distance > 22.0*22.0):
                continue
            var scene := TREE_BROAD if i % 3 != 0 else TREE_OAK
            if _spawn_physical_tree(cell,scene,world,extra_rng.randf_range(0.85,1.25),extra_rng.randf_range(-PI,PI),64+i):
                accepted_roots.append(world)
                extra_trees += 1
                details += 1
        for i in range(8):
            var world := _sample_cell_position(extra_rng,coord,2.0,1.0,2.0)
            if world != Vector2.INF and _spawn_visual(cell,BUSH_DETAILED,world,extra_rng.randf_range(0.45,0.85),extra_rng.randf_range(-PI,PI),"UnderBush",i,85.0):
                details += 1
        for i in range(24):
            var world := _sample_cell_position(extra_rng,coord,1.0,0.0,2.0)
            if world != Vector2.INF and _spawn_visual(cell,FERN,world,extra_rng.randf_range(0.45,0.95),extra_rng.randf_range(-PI,PI),"UnderFern",i,85.0):
                details += 1
    var cover_noise := FastNoiseLite.new()
    cover_noise.seed = NATURE_SEED
    cover_noise.frequency = 0.045
    cover_noise.fractal_octaves = 2
    var ground_cover := 0
    if biome in ["forest","taiga","marsh","plains"]:
        var origin := _detail_cell_origin(coord)
        var step := DETAIL_CELL_SIZE/float(GROUND_COVER_GRID)
        for z in range(GROUND_COVER_GRID):
            for x in range(GROUND_COVER_GRID):
                var world := origin+Vector2(x+extra_rng.randf_range(0.15,0.85),z+extra_rng.randf_range(0.15,0.85))*step
                if not GEOGRAPHY.in_start_region(world) or _inside_exclusion_zone(world):
                    continue
                if world.distance_squared_to(GEOGRAPHY.START_SPAWN)<2.25 or GEOGRAPHY.distance_to_start_river(world)<GEOGRAPHY.START_RIVER_HALF_WIDTH+0.7:
                    continue
                if GEOGRAPHY.distance_to_primary_road(world)<GEOGRAPHY.PRIMARY_ROAD_HALF_WIDTH+1.5:
                    continue
                var patch := cover_noise.get_noise_2d(world.x,world.y)
                if patch < -0.22:
                    continue
                var height := WorldData.elevation_at(world)
                if height < WorldData.water_level_at(world)+0.05:
                    continue
                var tuft_scale := extra_rng.randf_range(0.45,1.05)*(1.0+patch*0.65)
                _record_visual(cell,GROUND_GRASS,world,tuft_scale,extra_rng.randf_range(-PI,PI),55.0,height)
                ground_cover += 1
                details += 1
    cell.set_meta("ground_cover_count",ground_cover)
    cell.set_meta("extra_tree_count",extra_trees)
    return {"trees":trees+extra_trees, "details":details}

func _sample_cell_position(rng: RandomNumberGenerator, coord: Vector2i, river_clearance: float, road_clearance: float, spawn_clearance: float = 6.0) -> Vector2:
    var origin := _detail_cell_origin(coord)
    for _attempt in range(24):
        var world := origin + Vector2(
            rng.randf_range(6.0, DETAIL_CELL_SIZE - 6.0),
            rng.randf_range(6.0, DETAIL_CELL_SIZE - 6.0)
        )
        if not GEOGRAPHY.in_start_region(world):
            continue
        if world.distance_to(GEOGRAPHY.START_SPAWN) < spawn_clearance:
            continue
        if GEOGRAPHY.distance_to_start_river(world) < GEOGRAPHY.START_RIVER_HALF_WIDTH + river_clearance:
            continue
        if GEOGRAPHY.distance_to_primary_road(world) < GEOGRAPHY.PRIMARY_ROAD_SHOULDER_WIDTH + road_clearance:
            continue
        if _inside_exclusion_zone(world):
            continue
        if WorldData.elevation_at(world) < WorldData.SEA_LEVEL + 0.45:
            continue
        return world
    return Vector2.INF

func _cache_exclusion_zones() -> void:
    exclusion_zones.clear()
    for variant: Variant in GEOGRAPHY.poi_catalog():
        if not (variant is Dictionary):
            continue
        var poi: Dictionary = variant as Dictionary
        var kind := String(poi.get("kind", ""))
        var radius := 0.0
        match kind:
            "village": radius = 185.0
            "ford": radius = 48.0
            "fortified_town": radius = 260.0
            _: radius = 0.0
        if radius <= 0.0:
            continue
        var pos: Vector2 = poi.get("pos", Vector2.ZERO)
        if pos.distance_to(GEOGRAPHY.START_SPAWN) <= GEOGRAPHY.START_REGION_RADIUS + radius:
            exclusion_zones.append({"pos":pos, "radius":radius})

func _inside_exclusion_zone(world: Vector2) -> bool:
    for zone: Dictionary in exclusion_zones:
        var center: Vector2 = zone.get("pos", Vector2.ZERO)
        var radius := float(zone.get("radius", 0.0))
        if world.distance_squared_to(center) <= radius * radius:
            return true
    return false

func _spawn_physical_tree(parent: Node3D, scene: PackedScene, world: Vector2, scale_value: float, yaw: float, index: int) -> bool:
    var id_value := "forest:%d:%d" % [roundi(world.x * 1000), roundi(world.y * 1000)]
    if int(GameState.get_world_value("tree_cuts:" + id_value, 0)) > 0 or bool(GameState.get_world_value("tree_fallen:" + id_value, false)):
        var resource := preload("res://scripts/streamed_resource.gd").new()
        resource.configure(id_value, "wood", 6)
        resource.tree_scene = scene
        resource.tree_scale = scale_value
        resource.position = Vector3(world.x, WorldData.elevation_at(world), world.y)
        resource.rotation.y = yaw
        parent.add_child(resource)
        return true
    var body := preload("res://scripts/choppable_tree_proxy.gd").new()
    body.persistent_id = id_value
    body.tree_scene = scene
    body.tree_scale = scale_value
    var batches: Dictionary = parent.get_meta("visual_batches")
    body.batch_index = batches[scene.resource_path]["transforms"].size() if batches.has(scene.resource_path) else 0
    body.name = "RealTree_%02d" % index
    body.add_to_group("map_tree")
    body.position = Vector3(world.x, WorldData.elevation_at(world), world.y)
    body.rotation.y = yaw
    parent.add_child(body)

    _record_visual(parent, scene, world, scale_value, yaw, DETAIL_TREE_VISIBILITY)

    var collision := CollisionShape3D.new()
    collision.name = "TrunkCollision"
    var trunk := CylinderShape3D.new()
    trunk.radius = PRODUCTION_NATURE.trunk_radius(scene) * scale_value
    trunk.height = 2.5 * scale_value
    collision.shape = trunk
    collision.position.y = trunk.height * 0.5
    body.add_child(collision)
    return true

func _spawn_visual(parent: Node3D, scene: PackedScene, world: Vector2, scale_value: float, yaw: float, _prefix: String, _index: int, visibility_end: float) -> bool:
    if scene == ROCK_LARGE:
        parent.add_to_group("map_rock_batch")
        var positions: Array = parent.get_meta("map_rock_positions", [])
        positions.append(Vector3(world.x, WorldData.elevation_at(world), world.y))
        parent.set_meta("map_rock_positions", positions)
    _record_visual(parent, scene, world, scale_value, yaw, visibility_end)
    return true

func _record_visual(parent: Node3D, scene: PackedScene, world: Vector2, scale_value: float, yaw: float, visibility_end: float, known_height: float = INF) -> void:
    var batches: Dictionary = parent.get_meta("visual_batches")
    var key := scene.resource_path
    if not batches.has(key):
        batches[key] = {"scene": scene, "transforms": [], "visibility_end": visibility_end}
    var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_value)
    var height := known_height if is_finite(known_height) else WorldData.elevation_at(world)
    var origin := Vector3(world.x, height, world.y)
    batches[key]["transforms"].append(Transform3D(basis, origin))

func _materialize_visual_batches(cell: Node3D) -> void:
    var batches: Dictionary = cell.get_meta("visual_batches")
    for entry: Dictionary in batches.values():
        var transforms: Array[Transform3D] = []
        transforms.assign(entry["transforms"])
        var first := cell.get_child_count()
        preload("res://scripts/production_nature.gd").add_model_batches(cell, transforms, entry["scene"], float(entry["visibility_end"]))
        for index in range(first, cell.get_child_count()):
            cell.get_child(index).set_meta("tree_source", (entry["scene"] as PackedScene).resource_path)
    cell.remove_meta("visual_batches")

func _set_visibility_range(node: Node, visibility_end: float) -> void:
    if node is GeometryInstance3D:
        (node as GeometryInstance3D).visibility_range_end = visibility_end
    for child: Node in node.get_children():
        _set_visibility_range(child, visibility_end)

func _unload_detail_cell(coord: Vector2i) -> void:
    var cell := loaded_detail_cells.get(coord) as Node3D
    if cell != null and is_instance_valid(cell):
        real_tree_count = maxi(0, real_tree_count - int(cell.get_meta("tree_count", 0)))
        real_nature_detail_count = maxi(0, real_nature_detail_count - int(cell.get_meta("detail_count", 0)))
        cell.queue_free()
    loaded_detail_cells.erase(coord)

func _clear_detail_cells() -> void:
    for key: Variant in loaded_detail_cells.keys():
        var coord: Vector2i = key as Vector2i
        var cell := loaded_detail_cells.get(coord) as Node3D
        if cell != null and is_instance_valid(cell):
            cell.queue_free()
    loaded_detail_cells.clear()
    detail_generation_queue.clear()
    real_tree_count = 0
    real_nature_detail_count = 0

func loaded_detail_cell_count() -> int:
    return loaded_detail_cells.size()

func detail_center_cell() -> Vector2i:
    return current_detail_center

func _world_to_detail_cell(world: Vector2) -> Vector2i:
    return Vector2i(floori(world.x / DETAIL_CELL_SIZE), floori(world.y / DETAIL_CELL_SIZE))

func _detail_cell_origin(coord: Vector2i) -> Vector2:
    return Vector2(float(coord.x) * DETAIL_CELL_SIZE, float(coord.y) * DETAIL_CELL_SIZE)

func _detail_cell_center(coord: Vector2i) -> Vector2:
    return _detail_cell_origin(coord) + Vector2.ONE * (DETAIL_CELL_SIZE * 0.5)

func _detail_cell_intersects_start_region(coord: Vector2i) -> bool:
    var center := _detail_cell_center(coord)
    var half_diagonal := DETAIL_CELL_SIZE * 0.71
    return center.distance_to(GEOGRAPHY.START_SPAWN) <= GEOGRAPHY.START_REGION_RADIUS + half_diagonal

func _distance_cells(a: Vector2i, b: Vector2i) -> int:
    return maxi(absi(a.x - b.x), absi(a.y - b.y))

func _make_water_material() -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = preload("res://assets/shaders/environment/ice_surface.gdshader")
    material.set_shader_parameter("freeze_amount", 0.0)
    material.set_shader_parameter("water_color", Color(0.055, 0.20, 0.25, 0.88))
    material.set_shader_parameter("wave_strength", 0.012)
    return material

func _make_material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
