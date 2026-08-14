extends Node3D

const CHUNK_SIZE := 512.0
const GRID_RESOLUTION := 16
const ACTIVE_RADIUS := 2
const UNLOAD_RADIUS := 3

var player: Node3D
var loaded_chunks: Dictionary = {}
var generation_queue: Array[Vector2i] = []
var current_center := Vector2i(999999, 999999)
var terrain_materials: Dictionary = {}
var trunk_material: StandardMaterial3D
var foliage_materials: Dictionary = {}
var rock_material: StandardMaterial3D
var water_material: StandardMaterial3D

func _ready() -> void:
    _prepare_materials()

func _process(_delta: float) -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
        if player == null:
            return
        current_center = _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
        _generate_chunk(current_center)
        _refresh_streaming(current_center)

    var center := _world_to_chunk(Vector2(player.global_position.x, player.global_position.z))
    if center != current_center:
        current_center = center
        _refresh_streaming(center)
        _update_wilderness_location()

    if not generation_queue.is_empty():
        var next: Vector2i = generation_queue.pop_front()
        if not loaded_chunks.has(next):
            _generate_chunk(next)

func _refresh_streaming(center: Vector2i) -> void:
    generation_queue.clear()
    for ring in range(1, ACTIVE_RADIUS + 1):
        for x in range(center.x - ring, center.x + ring + 1):
            for z in range(center.y - ring, center.y + ring + 1):
                var coord := Vector2i(x, z)
                if maxi(abs(coord.x - center.x), abs(coord.y - center.y)) != ring:
                    continue
                if _chunk_inside_world(coord) and not loaded_chunks.has(coord):
                    generation_queue.append(coord)

    var to_remove: Array[Vector2i] = []
    for key in loaded_chunks.keys():
        var coord: Vector2i = key
        if maxi(abs(coord.x - center.x), abs(coord.y - center.y)) > UNLOAD_RADIUS:
            to_remove.append(coord)
    for coord in to_remove:
        var chunk: Node = loaded_chunks.get(coord)
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
    var center_world := origin + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    var biome := WorldData.biome_at(center_world)
    terrain.material_override = terrain_materials.get(biome, terrain_materials["plains"])
    chunk.add_child(terrain)

    var body := StaticBody3D.new()
    body.name = "TerrainCollision"
    var collision := CollisionShape3D.new()
    collision.shape = mesh.create_trimesh_shape()
    body.add_child(collision)
    chunk.add_child(body)

    if _chunk_needs_water(coord):
        _add_water(chunk)
    _add_vegetation(chunk, coord, biome)
    _add_landmark_if_needed(chunk, coord)

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
            var height := WorldData.elevation_at(world)
            st.set_uv(Vector2(fx, fz))
            st.add_vertex(Vector3(local_x, height, local_z))

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
    mesh.size = Vector3(CHUNK_SIZE, 0.12, CHUNK_SIZE)
    water.mesh = mesh
    water.position = Vector3(CHUNK_SIZE * 0.5, WorldData.SEA_LEVEL - 0.08, CHUNK_SIZE * 0.5)
    water.material_override = water_material
    chunk.add_child(water)

func _add_vegetation(chunk: Node3D, coord: Vector2i, biome: String) -> void:
    if biome == "ocean":
        return
    var tree_count := 18
    match biome:
        "forest": tree_count = 110
        "taiga": tree_count = 85
        "marsh": tree_count = 48
        "plains": tree_count = 24
        "tundra": tree_count = 7
        "drylands": tree_count = 5
        "mountains": tree_count = 4

    var rng := RandomNumberGenerator.new()
    rng.seed = abs(hash("%d:%d:%d" % [coord.x, coord.y, WorldData.WORLD_SEED]))
    var transforms: Array[Transform3D] = []
    var origin := _chunk_origin(coord)
    for _i in range(tree_count):
        var lx := rng.randf_range(8.0, CHUNK_SIZE - 8.0)
        var lz := rng.randf_range(8.0, CHUNK_SIZE - 8.0)
        var world := origin + Vector2(lx, lz)
        if world.length() < 620.0:
            continue
        var h := WorldData.elevation_at(world)
        if h < WorldData.SEA_LEVEL + 0.6:
            continue
        var scale := rng.randf_range(0.75, 1.45)
        var basis := Basis().scaled(Vector3(scale, scale, scale))
        transforms.append(Transform3D(basis, Vector3(lx, h, lz)))
    if transforms.is_empty():
        return

    if biome in ["forest", "taiga", "marsh", "plains"]:
        _spawn_tree_multimeshes(chunk, transforms, biome)
    else:
        _spawn_rock_multimesh(chunk, transforms)

func _spawn_tree_multimeshes(chunk: Node3D, transforms: Array[Transform3D], biome: String) -> void:
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22
    trunk_mesh.bottom_radius = 0.34
    trunk_mesh.height = 4.2
    trunk_mesh.radial_segments = 7
    trunk_mesh.material = trunk_material

    var foliage_mesh := CylinderMesh.new()
    foliage_mesh.top_radius = 0.0
    foliage_mesh.bottom_radius = 1.65 if biome != "marsh" else 1.25
    foliage_mesh.height = 4.8
    foliage_mesh.radial_segments = 7
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
        trunk_transform.origin.y += 2.1 * scale_y
        trunks.set_instance_transform(i, trunk_transform)
        var crown_transform := base
        crown_transform.origin.y += 5.4 * scale_y
        crowns.set_instance_transform(i, crown_transform)

    var trunk_node := MultiMeshInstance3D.new()
    trunk_node.name = "TreeTrunks"
    trunk_node.multimesh = trunks
    chunk.add_child(trunk_node)
    var crown_node := MultiMeshInstance3D.new()
    crown_node.name = "TreeCrowns"
    crown_node.multimesh = crowns
    chunk.add_child(crown_node)

func _spawn_rock_multimesh(chunk: Node3D, transforms: Array[Transform3D]) -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.8, 1.3, 1.6)
    mesh.material = rock_material
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = mesh
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        var t := transforms[i]
        t.origin.y += 0.65 * t.basis.get_scale().y
        multimesh.set_instance_transform(i, t)
    var node := MultiMeshInstance3D.new()
    node.name = "Boulders"
    node.multimesh = multimesh
    chunk.add_child(node)

func _add_landmark_if_needed(chunk: Node3D, coord: Vector2i) -> void:
    var origin := _chunk_origin(coord)
    var max_pos := origin + Vector2(CHUNK_SIZE, CHUNK_SIZE)
    for poi in WorldData.poi_catalog():
        var p: Vector2 = poi.get("pos", Vector2.ZERO)
        if p.x < origin.x or p.x >= max_pos.x or p.y < origin.y or p.y >= max_pos.y:
            continue
        if String(poi.get("id", "")) == "lumengrad":
            continue
        var h := WorldData.elevation_at(p)
        if h < WorldData.SEA_LEVEL - 1.0:
            continue
        var local := Vector3(p.x - origin.x, h, p.y - origin.y)
        var marker := Node3D.new()
        marker.name = "Landmark_%s" % String(poi.get("id", "poi"))
        marker.position = local
        chunk.add_child(marker)
        var base := MeshInstance3D.new()
        var base_mesh := CylinderMesh.new()
        base_mesh.top_radius = 3.2
        base_mesh.bottom_radius = 3.8
        base_mesh.height = 1.1
        base_mesh.radial_segments = 10
        base_mesh.material = rock_material
        base.mesh = base_mesh
        base.position.y = 0.55
        marker.add_child(base)
        var pillar := MeshInstance3D.new()
        var pillar_mesh := BoxMesh.new()
        pillar_mesh.size = Vector3(2.0, 8.0, 2.0)
        pillar_mesh.material = terrain_materials["mountains"]
        pillar.mesh = pillar_mesh
        pillar.position.y = 4.8
        marker.add_child(pillar)

func _chunk_needs_water(coord: Vector2i) -> bool:
    var origin := _chunk_origin(coord)
    for sample in [Vector2(0, 0), Vector2(CHUNK_SIZE, 0), Vector2(0, CHUNK_SIZE), Vector2(CHUNK_SIZE, CHUNK_SIZE), Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)]:
        if WorldData.elevation_at(origin + sample) < WorldData.SEA_LEVEL:
            return true
    return false

func _update_wilderness_location() -> void:
    if player == null:
        return
    var pos := Vector2(player.global_position.x, player.global_position.z)
    if pos.length() < 360.0:
        return
    var biome := WorldData.biome_at(pos)
    var sector_x := floori(pos.x / 1000.0)
    var sector_z := floori(pos.y / 1000.0)
    var location := "%s • сектор %d:%d" % [WorldData.biome_display_name(biome), sector_x, sector_z]
    GameState.set_location(location)

func _world_to_chunk(pos: Vector2) -> Vector2i:
    return Vector2i(floori(pos.x / CHUNK_SIZE), floori(pos.y / CHUNK_SIZE))

func _chunk_origin(coord: Vector2i) -> Vector2:
    return Vector2(float(coord.x) * CHUNK_SIZE, float(coord.y) * CHUNK_SIZE)

func _chunk_inside_world(coord: Vector2i) -> bool:
    var center := _chunk_origin(coord) + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    return WorldData.inside_world(center)

func _prepare_materials() -> void:
    for biome in ["plains", "forest", "taiga", "tundra", "drylands", "marsh", "mountains", "ocean"]:
        terrain_materials[biome] = _material(WorldData.biome_color(biome), 0.94)
    trunk_material = _material(Color(0.24, 0.13, 0.065), 0.96)
    foliage_materials["forest"] = _material(Color(0.08, 0.28, 0.10), 0.96)
    foliage_materials["taiga"] = _material(Color(0.055, 0.20, 0.15), 0.98)
    foliage_materials["marsh"] = _material(Color(0.14, 0.25, 0.09), 0.97)
    foliage_materials["plains"] = _material(Color(0.13, 0.33, 0.12), 0.96)
    rock_material = _material(Color(0.31, 0.32, 0.34), 0.91)
    water_material = _material(Color(0.06, 0.30, 0.48, 0.82), 0.25)
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness_value
    return mat
