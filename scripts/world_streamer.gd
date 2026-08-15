extends Node3D

const STREAMED_RESOURCE := preload("res://scripts/streamed_resource.gd")
const CAPITAL := preload("res://scripts/capital_data.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")

# The continent remains 64x64 km in WorldData, but only a small local window is
# materialized around the player. This keeps traversal smooth and memory bounded.
const CHUNK_SIZE := 192.0
const GRID_RESOLUTION := 10
const VISUAL_RADIUS := 2
const PHYSICS_RADIUS := 1
const UNLOAD_RADIUS := 3
const CITY_NO_WILD_RADIUS := 2250.0
const MAX_CHUNKS_PER_FRAME := 1

var player: Node3D
var loaded_chunks: Dictionary = {}
var collision_chunks: Dictionary = {}
var generation_queue: Array[Vector2i] = []
var collision_queue: Array[Vector2i] = []
var current_center := Vector2i(999999, 999999)
var terrain_materials: Dictionary = {}
var trunk_material: StandardMaterial3D
var foliage_materials: Dictionary = {}
var rock_material: StandardMaterial3D
var water_material: StandardMaterial3D
var location_elapsed := 0.0

func _ready() -> void:
    process_priority = 50
    _prepare_materials()
    call_deferred("_bootstrap_streaming")

func _bootstrap_streaming() -> void:
    player = get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    current_center = _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
    _generate_chunk(current_center)
    _ensure_collision(current_center)
    _refresh_streaming(current_center)

func _process(delta: float) -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
        if player == null:
            return
        current_center = _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
        if not loaded_chunks.has(current_center):
            _generate_chunk(current_center)
        _ensure_collision(current_center)
        _refresh_streaming(current_center)

    var center := _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
    if center != current_center:
        current_center = center
        _refresh_streaming(center)

    location_elapsed += delta
    if location_elapsed >= 1.0:
        location_elapsed = 0.0
        _update_wilderness_location()

    # Physics for the walking area is prioritized over scenery. Both are
    # deliberately budgeted so crossing a chunk boundary does not freeze a frame.
    if not collision_queue.is_empty():
        var physics_coord: Vector2i = collision_queue.pop_front()
        _ensure_collision(physics_coord)

    var generated := 0
    while generated < MAX_CHUNKS_PER_FRAME and not generation_queue.is_empty():
        var coord: Vector2i = generation_queue.pop_front()
        if not loaded_chunks.has(coord):
            _generate_chunk(coord)
            generated += 1

func _refresh_streaming(center: Vector2i) -> void:
    generation_queue.clear()
    collision_queue.clear()

    for ring in range(0, VISUAL_RADIUS + 1):
        for x in range(center.x - ring, center.x + ring + 1):
            for z in range(center.y - ring, center.y + ring + 1):
                var coord := Vector2i(x, z)
                if maxi(absi(coord.x - center.x), absi(coord.y - center.y)) != ring:
                    continue
                if not _chunk_inside_world(coord):
                    continue
                if not loaded_chunks.has(coord):
                    generation_queue.append(coord)
                if ring <= PHYSICS_RADIUS and not collision_chunks.has(coord):
                    collision_queue.append(coord)

    var collisions_to_remove: Array[Vector2i] = []
    for key in collision_chunks.keys():
        var coord: Vector2i = key
        if _distance_chunks(coord, center) > PHYSICS_RADIUS:
            collisions_to_remove.append(coord)
    for coord in collisions_to_remove:
        var body = collision_chunks.get(coord)
        if is_instance_valid(body):
            body.queue_free()
        collision_chunks.erase(coord)

    var chunks_to_remove: Array[Vector2i] = []
    for key in loaded_chunks.keys():
        var coord: Vector2i = key
        if _distance_chunks(coord, center) > UNLOAD_RADIUS:
            chunks_to_remove.append(coord)
    for coord in chunks_to_remove:
        if collision_chunks.has(coord):
            var body = collision_chunks.get(coord)
            if is_instance_valid(body):
                body.queue_free()
            collision_chunks.erase(coord)
        var chunk = loaded_chunks.get(coord)
        if is_instance_valid(chunk):
            chunk.queue_free()
        loaded_chunks.erase(coord)

func _generate_chunk(coord: Vector2i) -> void:
    if loaded_chunks.has(coord) or not _chunk_inside_world(coord):
        return

    var chunk := Node3D.new()
    chunk.name = "WorldChunk_%d_%d" % [coord.x, coord.y]
    var origin := _chunk_origin(coord)
    chunk.position = Vector3(origin.x, 0.0, origin.y)
    add_child(chunk)
    loaded_chunks[coord] = chunk

    var mesh := _build_terrain_mesh(coord)
    var terrain := MeshInstance3D.new()
    terrain.name = "Terrain"
    terrain.mesh = mesh
    terrain.visibility_range_end = CHUNK_SIZE * float(VISUAL_RADIUS + 2)
    var center_world := origin + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    var biome := WorldData.biome_at(center_world)
    terrain.material_override = terrain_materials.get(biome, terrain_materials["plains"])
    chunk.add_child(terrain)

    if _distance_chunks(coord, current_center) <= PHYSICS_RADIUS:
        _ensure_collision(coord)

    # Sea/ocean water remains chunk based. The opening river is a dedicated
    # curved local water body and must never turn its entire terrain chunk into sea.
    if not GEOGRAPHY.in_start_region(center_world) and _chunk_needs_water(coord):
        _add_water(chunk)
    _add_vegetation(chunk, coord, biome)
    _add_gatherables(chunk, coord, biome)
    _add_landmark_if_needed(chunk, coord)

func _ensure_collision(coord: Vector2i) -> void:
    if collision_chunks.has(coord):
        return
    var chunk = loaded_chunks.get(coord)
    if not is_instance_valid(chunk):
        return
    var terrain := chunk.get_node_or_null("Terrain") as MeshInstance3D
    if terrain == null or terrain.mesh == null:
        return
    var body := StaticBody3D.new()
    body.name = "TerrainCollision"
    var shape := CollisionShape3D.new()
    shape.shape = terrain.mesh.create_trimesh_shape()
    body.add_child(shape)
    chunk.add_child(body)
    collision_chunks[coord] = body

func _build_terrain_mesh(coord: Vector2i) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var origin := _chunk_origin(coord)
    for z in range(GRID_RESOLUTION + 1):
        for x in range(GRID_RESOLUTION + 1):
            var fx := float(x) / float(GRID_RESOLUTION)
            var fz := float(z) / float(GRID_RESOLUTION)
            var local_x := fx * CHUNK_SIZE
            var local_z := fz * CHUNK_SIZE
            var world := origin + Vector2(local_x, local_z)
            st.set_uv(Vector2(fx, fz))
            st.add_vertex(Vector3(local_x, WorldData.elevation_at(world), local_z))

    var row := GRID_RESOLUTION + 1
    for z in range(GRID_RESOLUTION):
        for x in range(GRID_RESOLUTION):
            var i0 := z * row + x
            var i1 := i0 + 1
            var i2 := i0 + row
            var i3 := i2 + 1
            st.add_index(i0)
            st.add_index(i2)
            st.add_index(i1)
            st.add_index(i1)
            st.add_index(i2)
            st.add_index(i3)
    st.generate_normals()
    return st.commit()

func _add_water(chunk: Node3D) -> void:
    var water := MeshInstance3D.new()
    water.name = "Water"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(CHUNK_SIZE, 0.08, CHUNK_SIZE)
    water.mesh = mesh
    water.position = Vector3(CHUNK_SIZE * 0.5, WorldData.SEA_LEVEL - 0.05, CHUNK_SIZE * 0.5)
    water.material_override = water_material
    water.visibility_range_end = CHUNK_SIZE * float(VISUAL_RADIUS + 2)
    chunk.add_child(water)

func _add_vegetation(chunk: Node3D, coord: Vector2i, biome: String) -> void:
    if biome == "ocean":
        return
    var origin := _chunk_origin(coord)
    var center_world := origin + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    if center_world.distance_to(CAPITAL.CENTER) < CITY_NO_WILD_RADIUS:
        return

    var tree_count := 8
    match biome:
        "forest": tree_count = 30
        "taiga": tree_count = 24
        "marsh": tree_count = 15
        "plains": tree_count = 10
        "tundra": tree_count = 4
        "drylands": tree_count = 3
        "mountains": tree_count = 3

    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("vegetation:%d:%d:%d" % [coord.x, coord.y, WorldData.WORLD_SEED]))
    var transforms: Array[Transform3D] = []
    for _i in range(tree_count):
        var lx := rng.randf_range(6.0, CHUNK_SIZE - 6.0)
        var lz := rng.randf_range(6.0, CHUNK_SIZE - 6.0)
        var world := origin + Vector2(lx, lz)
        if GEOGRAPHY.in_start_region(world) and GEOGRAPHY.distance_to_start_river(world) < GEOGRAPHY.START_RIVER_BANK_WIDTH + 5.0:
            continue
        var h := WorldData.elevation_at(world)
        if h < WorldData.SEA_LEVEL + 0.5:
            continue
        var scale := rng.randf_range(0.80, 1.35)
        transforms.append(Transform3D(Basis().scaled(Vector3(scale, scale, scale)), Vector3(lx, h, lz)))

    if transforms.is_empty():
        return
    if biome in ["forest", "taiga", "marsh", "plains"]:
        _spawn_tree_multimeshes(chunk, transforms, biome)
    else:
        _spawn_rock_multimesh(chunk, transforms)

func _add_gatherables(chunk: Node3D, coord: Vector2i, biome: String) -> void:
    if biome == "ocean":
        return
    var origin := _chunk_origin(coord)
    var center_world := origin + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    if center_world.distance_to(CAPITAL.CENTER) < CITY_NO_WILD_RADIUS:
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("gather:%d:%d:%d" % [coord.x, coord.y, WorldData.WORLD_SEED]))
    var count := 2 if biome in ["tundra", "drylands"] else 3
    for i in range(count):
        var lx := rng.randf_range(14.0, CHUNK_SIZE - 14.0)
        var lz := rng.randf_range(14.0, CHUNK_SIZE - 14.0)
        var world := origin + Vector2(lx, lz)
        if GEOGRAPHY.in_start_region(world) and GEOGRAPHY.distance_to_start_river(world) < GEOGRAPHY.START_RIVER_HALF_WIDTH + 4.0:
            continue
        var height := WorldData.elevation_at(world)
        if height < WorldData.SEA_LEVEL + 0.4:
            continue
        var type := "wood"
        match biome:
            "mountains", "drylands", "tundra": type = "stone"
            "marsh": type = "berries" if rng.randf() < 0.58 else "wood"
            "plains": type = "berries" if rng.randf() < 0.35 else "wood"
            _: type = "wood" if rng.randf() < 0.78 else "berries"
        var resource = STREAMED_RESOURCE.new()
        resource.name = "Gatherable_%d" % i
        resource.configure("chunk_%d_%d_%d" % [coord.x, coord.y, i], type, rng.randi_range(4, 8))
        resource.position = Vector3(lx, height, lz)
        resource.rotation.y = rng.randf_range(-PI, PI)
        chunk.add_child(resource)

func _spawn_tree_multimeshes(chunk: Node3D, transforms: Array[Transform3D], biome: String) -> void:
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.20
    trunk_mesh.bottom_radius = 0.32
    trunk_mesh.height = 4.0
    trunk_mesh.radial_segments = 6
    trunk_mesh.material = trunk_material

    var foliage_mesh := CylinderMesh.new()
    foliage_mesh.top_radius = 0.0
    foliage_mesh.bottom_radius = 1.55 if biome != "marsh" else 1.20
    foliage_mesh.height = 4.5
    foliage_mesh.radial_segments = 6
    foliage_mesh.material = foliage_materials.get(biome, foliage_materials["forest"])

    var trunks := MultiMesh.new()
    trunks.transform_format = MultiMesh.TRANSFORM_3D
    trunks.mesh = trunk_mesh
    trunks.instance_count = transforms.size()
    var crowns := MultiMesh.new()
    crowns.transform_format = MultiMesh.TRANSFORM_3D
    crowns.mesh = foliage_mesh
    crowns.instance_count = transforms.size()

    for i in range(transforms.size()):
        var base := transforms[i]
        var scale_y := base.basis.get_scale().y
        var trunk_transform := base
        trunk_transform.origin.y += 2.0 * scale_y
        trunks.set_instance_transform(i, trunk_transform)
        var crown_transform := base
        crown_transform.origin.y += 5.1 * scale_y
        crowns.set_instance_transform(i, crown_transform)

    var trunk_node := MultiMeshInstance3D.new()
    trunk_node.name = "TreeTrunks"
    trunk_node.multimesh = trunks
    trunk_node.visibility_range_end = 430.0
    chunk.add_child(trunk_node)

    var crown_node := MultiMeshInstance3D.new()
    crown_node.name = "TreeCrowns"
    crown_node.multimesh = crowns
    crown_node.visibility_range_end = 430.0
    chunk.add_child(crown_node)

func _spawn_rock_multimesh(chunk: Node3D, transforms: Array[Transform3D]) -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.7, 1.2, 1.5)
    mesh.material = rock_material
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = mesh
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        var t := transforms[i]
        t.origin.y += 0.6 * t.basis.get_scale().y
        multimesh.set_instance_transform(i, t)
    var node := MultiMeshInstance3D.new()
    node.name = "Boulders"
    node.multimesh = multimesh
    node.visibility_range_end = 360.0
    chunk.add_child(node)

func _add_landmark_if_needed(chunk: Node3D, coord: Vector2i) -> void:
    # POIs are logical/map anchors. Do not draw giant placeholder boxes in the
    # finished world; dedicated streamed models will materialize them by region.
    var origin := _chunk_origin(coord)
    var max_pos := origin + Vector2(CHUNK_SIZE, CHUNK_SIZE)
    for poi in WorldData.poi_catalog():
        var p: Vector2 = poi.get("pos", Vector2.ZERO)
        if p.x < origin.x or p.x >= max_pos.x or p.y < origin.y or p.y >= max_pos.y:
            continue
        var kind := String(poi.get("kind", ""))
        if kind in ["river", "ford", "village", "fortified_town", "capital"]:
            continue
        # Natural landmarks are represented by terrain now; dedicated landmark
        # art is added only once its final model is available.
        if kind in ["mountain", "lake", "marsh", "forest", "coast", "danger", "mine"]:
            continue

func _chunk_needs_water(coord: Vector2i) -> bool:
    var origin := _chunk_origin(coord)
    for sample in [Vector2.ZERO, Vector2(CHUNK_SIZE, 0), Vector2(0, CHUNK_SIZE), Vector2(CHUNK_SIZE, CHUNK_SIZE), Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)]:
        if WorldData.elevation_at(origin + sample) < WorldData.SEA_LEVEL:
            return true
    return false

func _update_wilderness_location() -> void:
    if player == null:
        return
    var pos := Vector2(player.global_position.x, player.global_position.z)
    if pos.distance_to(CAPITAL.CENTER) < CITY_NO_WILD_RADIUS:
        GameState.set_location("Люменград • территория столицы")
        return
    if GEOGRAPHY.in_start_region(pos):
        GameState.set_location("Астэрн • пограничный лес")
        return
    var biome := WorldData.biome_at(pos)
    var region: Dictionary = WorldData.political_region_at(pos)
    var region_name := String(region.get("name", "Свободные земли"))
    GameState.set_location("%s • %s" % [region_name, WorldData.biome_display_name(biome)])

func _world_to_chunk(pos: Vector2) -> Vector2i:
    return Vector2i(floori(pos.x / CHUNK_SIZE), floori(pos.y / CHUNK_SIZE))

func _chunk_origin(coord: Vector2i) -> Vector2:
    return Vector2(float(coord.x) * CHUNK_SIZE, float(coord.y) * CHUNK_SIZE)

func _chunk_inside_world(coord: Vector2i) -> bool:
    var center := _chunk_origin(coord) + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    return WorldData.inside_world(center)

func _distance_chunks(a: Vector2i, b: Vector2i) -> int:
    return maxi(absi(a.x - b.x), absi(a.y - b.y))

func _prepare_materials() -> void:
    for biome in ["plains", "forest", "taiga", "tundra", "drylands", "marsh", "mountains", "ocean"]:
        terrain_materials[biome] = _material(WorldData.biome_color(biome), 0.94)
    trunk_material = _material(Color(0.24, 0.13, 0.065), 0.96)
    foliage_materials["forest"] = _material(Color(0.08, 0.28, 0.10), 0.96)
    foliage_materials["taiga"] = _material(Color(0.055, 0.20, 0.15), 0.98)
    foliage_materials["marsh"] = _material(Color(0.14, 0.25, 0.09), 0.97)
    foliage_materials["plains"] = _material(Color(0.13, 0.32, 0.11), 0.96)
    rock_material = _material(Color(0.30, 0.31, 0.33), 0.99)
    water_material = _material(Color(0.055, 0.24, 0.38, 0.72), 0.20)
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
