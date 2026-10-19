extends Node3D

const STREAMED_RESOURCE := preload("res://scripts/streamed_resource.gd")
const ENEMY := preload("res://scripts/enemy.gd")
const CAPITAL := preload("res://scripts/capital_data.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const NATURE := preload("res://scripts/production_nature.gd")
const ROCK_SCENE := preload("res://assets/production/nature/kenney_nature_kit/Models/GLTF format/rock_largeA.glb")
const GRASS_SCENE := preload("res://assets/production/nature/woodland/Grass_Wispy_Tall.glb")
const FERN_SCENE := preload("res://assets/production/nature/woodland/Fern_1.glb")

# The continent remains 64x64 km in WorldData, but only a small local window is
# materialized around the player. This keeps traversal smooth and memory bounded.
const CHUNK_SIZE := 192.0
const GRID_RESOLUTION := 48
const VISUAL_RADIUS := 2
const PHYSICS_RADIUS := 1
const UNLOAD_RADIUS := 3
const CITY_NO_WILD_RADIUS := 2250.0
const MAX_CHUNKS_PER_FRAME := 1
const CHUNK_SENTINEL := Vector2i(999999, 999999)

var player: Node3D
var loaded_chunks: Dictionary = {}
var collision_chunks: Dictionary = {}
var generation_queue: Array[Vector2i] = []
var collision_queue: Array[Vector2i] = []
var current_center := CHUNK_SENTINEL
var streaming_suspended := false
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
    if not _mainland_streaming_allowed():
        _suspend_streaming()
        return
    streaming_suspended = false
    current_center = _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
    _generate_chunk(current_center)
    _ensure_collision(current_center)
    _refresh_streaming(current_center)

func _process(delta: float) -> void:
    if not _mainland_streaming_allowed():
        _suspend_streaming()
        return

    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
        if player == null:
            return

    if streaming_suspended:
        streaming_suspended = false
        current_center = CHUNK_SENTINEL

    var center := _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
    if current_center == CHUNK_SENTINEL:
        current_center = center
        if not loaded_chunks.has(current_center):
            _generate_chunk(current_center)
        _ensure_collision(current_center)
        _refresh_streaming(current_center)

    if center != current_center:
        current_center = center
        _refresh_streaming(center)

    location_elapsed += delta
    if location_elapsed >= 1.0:
        location_elapsed = 0.0
        _update_wilderness_location()
        preload("res://scripts/production_nature.gd").sync_wind()

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

func _mainland_streaming_allowed() -> bool:
    if ProgressionSystem.is_in_dungeon():
        return false
    return String(GameState.get_world_value("current_realm", "main")) == "main"

func _suspend_streaming() -> void:
    generation_queue.clear()
    collision_queue.clear()
    if loaded_chunks.is_empty() and collision_chunks.is_empty() and streaming_suspended:
        return
    for node in loaded_chunks.values():
        if is_instance_valid(node):
            if node is Node3D:
                (node as Node3D).visible = false
            node.queue_free()
    loaded_chunks.clear()
    collision_chunks.clear()
    current_center = CHUNK_SENTINEL
    location_elapsed = 0.0
    streaming_suspended = true

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
    # One halo sample on each side gives identical central-difference normals
    # at shared chunk edges; physics is built from this same rendered mesh.
    var spacing := CHUNK_SIZE / float(GRID_RESOLUTION)
    var stride := GRID_RESOLUTION + 3
    var heights := PackedFloat32Array()
    heights.resize(stride * stride)
    for z in range(-1, GRID_RESOLUTION + 2):
        for x in range(-1, GRID_RESOLUTION + 2):
            heights[(z + 1) * stride + x + 1] = WorldData.elevation_at(origin + Vector2(x, z) * spacing)
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    for z in range(GRID_RESOLUTION + 1):
        for x in range(GRID_RESOLUTION + 1):
            var offset := (z + 1) * stride + x + 1
            var dx := (heights[offset + 1] - heights[offset - 1]) / (2.0 * spacing)
            var dz := (heights[offset + stride] - heights[offset - stride]) / (2.0 * spacing)
            var normal := Vector3(-dx, 1.0, -dz).normalized()
            normals.append(normal)
            vertices.append(Vector3(x * spacing, heights[offset], z * spacing))
            st.set_normal(normal)
            st.set_uv(Vector2(x, z) / float(GRID_RESOLUTION))
            st.add_vertex(Vector3(x * spacing, heights[offset], z * spacing))

    var row := GRID_RESOLUTION + 1
    var shore_edges := {"next": vertices.size()}
    var river_level := GEOGRAPHY.START_RIVER_WATER_LEVEL
    for z in range(GRID_RESOLUTION):
        for x in range(GRID_RESOLUTION):
            var i0 := z * row + x
            var i1 := i0 + 1
            var i2 := i0 + row
            var i3 := i2 + 1
            var minimum := minf(minf(vertices[i0].y,vertices[i1].y),minf(vertices[i2].y,vertices[i3].y))
            var maximum := maxf(maxf(vertices[i0].y,vertices[i1].y),maxf(vertices[i2].y,vertices[i3].y))
            if minimum >= river_level or maximum <= river_level:
                st.add_index(i0)
                st.add_index(i1)
                st.add_index(i2)
                st.add_index(i1)
                st.add_index(i3)
                st.add_index(i2)
            else:
                for triangle in [PackedInt32Array([i0,i1,i2]), PackedInt32Array([i1,i3,i2])]:
                    _append_shore_triangle(st, origin, triangle, vertices, normals, shore_edges)
    return st.commit()

func _append_shore_triangle(st: SurfaceTool, origin: Vector2, triangle: PackedInt32Array, vertices: PackedVector3Array, normals: PackedVector3Array, cache: Dictionary) -> void:
    var level := GEOGRAPHY.START_RIVER_WATER_LEVEL
    var a := vertices[triangle[0]]
    var b := vertices[triangle[1]]
    var c := vertices[triangle[2]]
    var center := origin + Vector2((a.x+b.x+c.x)/3.0, (a.z+b.z+c.z)/3.0)
    if minf(a.y,minf(b.y,c.y)) >= level or maxf(a.y,maxf(b.y,c.y)) <= level or not GEOGRAPHY.in_start_region(center) or GEOGRAPHY.distance_to_start_river(center) > GEOGRAPHY.START_RIVER_BANK_WIDTH:
        for index in triangle:
            st.add_index(index)
        return
    # Split crossed faces at the actual height-field contour. Both sides share
    # cached edge vertices; physics is built from this same rendered mesh.
    for above in [true,false]:
        var polygon := PackedInt32Array()
        for edge in range(3):
            var current := triangle[edge]
            var next := triangle[(edge+1)%3]
            var inside: bool = (vertices[current].y >= level) == above
            var next_inside: bool = (vertices[next].y >= level) == above
            if inside:
                polygon.append(current)
            if inside != next_inside:
                polygon.append(_shore_edge_index(st, origin, current, next, vertices, normals, cache))
        for corner in range(1,polygon.size()-1):
            if polygon[0] != polygon[corner] and polygon[corner] != polygon[corner+1] and polygon[0] != polygon[corner+1]:
                st.add_index(polygon[0])
                st.add_index(polygon[corner])
                st.add_index(polygon[corner+1])

func _shore_edge_index(st: SurfaceTool, origin: Vector2, first: int, second: int, vertices: PackedVector3Array, normals: PackedVector3Array, cache: Dictionary) -> int:
    var key := Vector2i(mini(first,second),maxi(first,second))
    if cache.has(key):
        return int(cache[key])
    var a := vertices[key.x]
    var b := vertices[key.y]
    var level := GEOGRAPHY.START_RIVER_WATER_LEVEL
    if absf(a.y-level) < 0.000001:
        return key.x
    if absf(b.y-level) < 0.000001:
        return key.y
    var low := 0.0
    var high := 1.0
    for iteration in range(12):
        var middle := (low+high)*0.5
        var sample := a.lerp(b,middle)
        var height := WorldData.elevation_at(origin+Vector2(sample.x,sample.z))
        if (height >= level) == (a.y >= level):
            low = middle
        else:
            high = middle
    var fraction := (low+high)*0.5
    var point := a.lerp(b,fraction)
    point.y = level
    st.set_normal(normals[key.x].lerp(normals[key.y],fraction).normalized())
    st.set_uv(Vector2(point.x,point.z)/CHUNK_SIZE)
    st.add_vertex(point)
    var index := int(cache["next"])
    cache["next"] = index+1
    cache[key] = index
    return index

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
        "tropical": tree_count = 28
        "snow": tree_count = 2
        "underwater": tree_count = 0

    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("vegetation:%d:%d:%d" % [coord.x, coord.y, WorldData.WORLD_SEED]))
    var transforms: Array[Transform3D] = []
    for _i in range(tree_count):
        var lx := rng.randf_range(6.0, CHUNK_SIZE - 6.0)
        var lz := rng.randf_range(6.0, CHUNK_SIZE - 6.0)
        var world := origin + Vector2(lx, lz)
        if GEOGRAPHY.distance_to_primary_road(world) < GEOGRAPHY.PRIMARY_ROAD_SHOULDER_WIDTH + 1.0:
            continue
        if GEOGRAPHY.in_start_region(world) and GEOGRAPHY.distance_to_start_river(world) < GEOGRAPHY.START_RIVER_BANK_WIDTH + 5.0:
            continue
        var h := WorldData.elevation_at(world)
        if h < WorldData.SEA_LEVEL + 0.5:
            continue
        var scale := rng.randf_range(0.80, 1.35)
        transforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3.ONE * scale), Vector3(lx, h, lz)))

    if transforms.is_empty():
        return
    if biome in ["forest", "taiga", "marsh", "plains", "tropical"]:
        _spawn_tree_multimeshes(chunk, transforms, biome)
    else:
        _spawn_rock_multimesh(chunk, transforms)
    if not GEOGRAPHY.in_start_region(center_world) and biome in ["forest", "taiga", "marsh", "plains"]:
        var grass: Array[Transform3D] = []
        var ferns: Array[Transform3D] = []
        for index in range(48):
            var local := Vector2(rng.randf_range(4, CHUNK_SIZE - 4), rng.randf_range(4, CHUNK_SIZE - 4))
            var world := origin + local
            if GEOGRAPHY.distance_to_primary_road(world) < GEOGRAPHY.PRIMARY_ROAD_SHOULDER_WIDTH:
                continue
            var height := WorldData.elevation_at(world)
            if not WorldData.water_kind_at(world).is_empty():
                continue
            var scale := rng.randf_range(0.7, 1.3)
            var transform := Transform3D(Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3.ONE * scale), Vector3(local.x, height, local.y))
            grass.append(transform)
            if index % 8 == 0 and biome != "plains":
                ferns.append(transform)
        if not grass.is_empty():
            NATURE.add_model_batches(chunk, grass, GRASS_SCENE, 85.0)
        if not ferns.is_empty():
            NATURE.add_model_batches(chunk, ferns, FERN_SCENE, 85.0)

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
        if GEOGRAPHY.distance_to_primary_road(world) < GEOGRAPHY.PRIMARY_ROAD_SHOULDER_WIDTH + 2.0:
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

func _spawn_tree_multimeshes(chunk: Node3D, transforms: Array[Transform3D], _biome: String) -> void:
    var center := Vector2(chunk.position.x, chunk.position.z) + Vector2.ONE * CHUNK_SIZE * 0.5
    NATURE.add_batches(chunk, transforms, not GEOGRAPHY.in_start_region(center), _biome == "taiga")

func _spawn_rock_multimesh(chunk: Node3D, transforms: Array[Transform3D]) -> void:
    chunk.add_to_group("map_rock_batch")
    var positions: Array[Vector3] = []
    for transform in transforms:
        positions.append(transform.origin)
    chunk.set_meta("map_rock_positions", positions)
    NATURE.add_model_batches(chunk, transforms, ROCK_SCENE, 360.0, false, rock_material)
    NATURE.add_model_collisions(chunk, transforms, ROCK_SCENE)

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
        if kind == "danger":
            for index in range(2):
                var enemy_id := "encounter:%s:%d" % [String(poi.get("id", "danger")), index]
                if bool(GameState.get_world_value("enemy:" + enemy_id, false)):
                    continue
                var enemy := ENEMY.new()
                enemy.name = "Bandit_%d" % index
                enemy.enemy_id = enemy_id
                var position := p + Vector2(-4 if index == 0 else 4, 3)
                var local := position - origin
                enemy.position = Vector3(local.x, WorldData.elevation_at(position) + 0.08, local.y)
                chunk.add_child(enemy)
            continue
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
    if CAPITAL.inside_capital(pos):
        var district := CAPITAL.district_at(pos)
        GameState.set_location("Люменград • " + String(district.get("name", "Городские улицы")))
        return
    if pos.distance_to(CAPITAL.CENTER) < CITY_NO_WILD_RADIUS:
        GameState.set_location("Окраины Люменграда")
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
    for biome in ["plains", "forest", "taiga", "tundra", "drylands", "marsh", "mountains", "ocean", "freshwater", "underwater", "tropical", "snow", "steppe"]:
        var material := _material(Color.WHITE, 0.96)
        var noise := FastNoiseLite.new()
        noise.seed = 470219
        noise.frequency = 0.045
        noise.fractal_octaves = 4
        var texture := NoiseTexture2D.new()
        texture.width = 256
        texture.height = 256
        texture.seamless = true
        texture.noise = noise
        var ramp := Gradient.new()
        var color := WorldData.biome_color(biome)
        ramp.colors = PackedColorArray([color.darkened(0.28), color.lightened(0.18)])
        texture.color_ramp = ramp
        material.albedo_texture = texture
        material.uv1_triplanar = true
        material.uv1_world_triplanar = true
        material.uv1_scale = Vector3.ONE * 0.055
        if biome in ["plains", "forest", "taiga", "marsh"]:
            var ground := ShaderMaterial.new()
            ground.shader = preload("res://assets/shaders/environment/terrain_ground.gdshader")
            ground.set_shader_parameter("grass_texture", preload("res://assets/production/materials/ground/grass_meadow.jpg"))
            ground.set_shader_parameter("rock_texture", preload("res://assets/production/materials/ground/lichen_rock.jpg"))
            terrain_materials[biome] = ground
            continue
        elif biome == "mountains":
            material.albedo_texture = preload("res://assets/production/materials/ground/lichen_rock.jpg")
            material.uv1_scale = Vector3.ONE * 0.25
        terrain_materials[biome] = material
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
