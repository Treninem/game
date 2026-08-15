extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const HYDROLOGY := preload("res://scripts/world_hydrology.gd")
const CHUNK_SIZE := 192.0
const PATCH_SPACING := 9.0
const CHUNK_MARGIN := 8.0
const BRIDGE_DECK_THICKNESS := 0.34
const BRIDGE_RAIL_HEIGHT := 0.16
const BRIDGE_RAIL_THICKNESS := 0.18
const BRIDGE_RAIL_OFFSET_Y := 0.72

var road_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var bridge_rail_material: StandardMaterial3D
var materialized_road_chunks := 0
var materialized_patches := 0
var materialized_bridge_chunks := 0

func _ready() -> void:
    road_material = StandardMaterial3D.new()
    road_material.albedo_color = Color(0.29, 0.20, 0.105, 1.0)
    road_material.roughness = 0.98

    bridge_material = StandardMaterial3D.new()
    bridge_material.albedo_color = Color(0.30, 0.19, 0.09, 1.0)
    bridge_material.roughness = 0.91

    bridge_rail_material = StandardMaterial3D.new()
    bridge_rail_material.albedo_color = Color(0.20, 0.115, 0.055, 1.0)
    bridge_rail_material.roughness = 0.94
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name.begins_with("WorldChunk_"):
        call_deferred("_materialize_chunk", node)

func _materialize_chunk(chunk: Node3D) -> void:
    if not is_instance_valid(chunk) or chunk.get_node_or_null("RoadSurface") != null:
        return

    var origin := Vector2(chunk.global_position.x, chunk.global_position.z)
    _materialize_bridge_if_owned(chunk, origin)

    var transforms: Array[Transform3D] = []
    for road in WorldData.road_catalog():
        var points: Array = road.get("points", [])
        for i in range(points.size() - 1):
            _append_segment_patches(transforms, origin, points[i], points[i + 1])

    if transforms.is_empty():
        return

    var patch_mesh := BoxMesh.new()
    patch_mesh.size = Vector3(PATCH_SPACING + 0.8, 0.055, GEOGRAPHY.PRIMARY_ROAD_HALF_WIDTH * 2.0)
    patch_mesh.material = road_material

    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = patch_mesh
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        multimesh.set_instance_transform(i, transforms[i])

    var surface := MultiMeshInstance3D.new()
    surface.name = "RoadSurface"
    surface.multimesh = multimesh
    surface.visibility_range_end = CHUNK_SIZE * 3.5
    chunk.add_child(surface)
    materialized_road_chunks += 1
    materialized_patches += transforms.size()

func _materialize_bridge_if_owned(chunk: Node3D, origin: Vector2) -> void:
    if chunk.get_node_or_null("RoadBridge") != null:
        return

    var center := HYDROLOGY.ROAD_BRIDGE_CENTER
    if center.x < origin.x or center.x >= origin.x + CHUNK_SIZE \
    or center.y < origin.y or center.y >= origin.y + CHUNK_SIZE:
        return

    var direction := HYDROLOGY.ROAD_BRIDGE_DIRECTION.normalized()
    var half_length := HYDROLOGY.ROAD_BRIDGE_HALF_LENGTH
    var a2 := center - direction * half_length
    var b2 := center + direction * half_length
    var water_level := WorldData.water_level_at(center)
    var deck_y := maxf(
        maxf(WorldData.elevation_at(a2), WorldData.elevation_at(b2)) + 0.12,
        water_level + HYDROLOGY.ROAD_BRIDGE_CLEARANCE
    )
    var local_center := center - origin
    var angle := atan2(direction.y, direction.x)
    var bridge_basis := Basis(Vector3.UP, -angle)

    var bridge := Node3D.new()
    bridge.name = "RoadBridge"
    chunk.add_child(bridge)

    var deck_mesh := BoxMesh.new()
    deck_mesh.size = Vector3(half_length * 2.0, BRIDGE_DECK_THICKNESS, HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH * 2.0)
    deck_mesh.material = bridge_material

    var deck := MeshInstance3D.new()
    deck.name = "Deck"
    deck.mesh = deck_mesh
    deck.transform = Transform3D(
        bridge_basis,
        Vector3(local_center.x, deck_y, local_center.y)
    )
    deck.visibility_range_end = CHUNK_SIZE * 3.5
    bridge.add_child(deck)

    # The bridge is a real load-bearing world object. Terrain collision remains
    # below the river; this static deck collision is what the player, NPCs and
    # later carts physically stand on while crossing.
    var body := StaticBody3D.new()
    body.name = "BridgeCollision"
    body.transform = deck.transform
    bridge.add_child(body)

    var deck_shape := BoxShape3D.new()
    deck_shape.size = deck_mesh.size
    var collision := CollisionShape3D.new()
    collision.name = "DeckShape"
    collision.shape = deck_shape
    body.add_child(collision)

    # Visible rails alone are not enough for a physical world: their collision
    # prevents characters, animals and future carts from simply clipping through
    # the sides and falling into the river.
    _add_bridge_rail(bridge, body, local_center, deck_y, bridge_basis, -1.0)
    _add_bridge_rail(bridge, body, local_center, deck_y, bridge_basis, 1.0)
    _add_bridge_support(bridge, origin, center - direction * 18.0, deck_y, bridge_basis)
    _add_bridge_support(bridge, origin, center + direction * 18.0, deck_y, bridge_basis)
    materialized_bridge_chunks += 1

func _add_bridge_rail(
    bridge: Node3D,
    body: StaticBody3D,
    local_center: Vector2,
    deck_y: float,
    bridge_basis: Basis,
    side_sign: float
) -> void:
    var rail_size := Vector3(
        HYDROLOGY.ROAD_BRIDGE_HALF_LENGTH * 2.0,
        BRIDGE_RAIL_HEIGHT,
        BRIDGE_RAIL_THICKNESS
    )
    var rail_mesh := BoxMesh.new()
    rail_mesh.size = rail_size
    rail_mesh.material = bridge_rail_material
    var rail := MeshInstance3D.new()
    var side_name := "Left" if side_sign < 0.0 else "Right"
    rail.name = "Rail%s" % side_name
    var side_offset := HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH - 0.22
    var local_offset := bridge_basis * Vector3(0.0, BRIDGE_RAIL_OFFSET_Y, side_offset * side_sign)
    rail.transform = Transform3D(
        bridge_basis,
        Vector3(local_center.x, deck_y, local_center.y) + local_offset
    )
    bridge.add_child(rail)

    # BridgeCollision already owns the same basis and origin as the deck, so the
    # rail guard shape is expressed directly in deck-local coordinates.
    var guard_shape := BoxShape3D.new()
    guard_shape.size = rail_size
    var guard := CollisionShape3D.new()
    guard.name = "Rail%sShape" % side_name
    guard.position = Vector3(0.0, BRIDGE_RAIL_OFFSET_Y, side_offset * side_sign)
    guard.shape = guard_shape
    body.add_child(guard)

func _add_bridge_support(
    bridge: Node3D,
    origin: Vector2,
    world_pos: Vector2,
    deck_y: float,
    bridge_basis: Basis
) -> void:
    var bed_y := WorldData.elevation_at(world_pos)
    var support_height := maxf(0.4, deck_y - bed_y)
    var support_mesh := BoxMesh.new()
    support_mesh.size = Vector3(0.9, support_height, HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH * 1.72)
    support_mesh.material = bridge_rail_material
    var support := MeshInstance3D.new()
    support.name = "Pier"
    var local := world_pos - origin
    support.transform = Transform3D(
        bridge_basis,
        Vector3(local.x, bed_y + support_height * 0.5, local.y)
    )
    bridge.add_child(support)

func _append_segment_patches(transforms: Array[Transform3D], origin: Vector2, a: Vector2, b: Vector2) -> void:
    var segment := b - a
    var length := segment.length()
    if length < 0.01:
        return

    var chunk_center := origin + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
    var closest_t := clampf((chunk_center - a).dot(segment) / (length * length), 0.0, 1.0)
    var closest := a + segment * closest_t
    if closest.distance_to(chunk_center) > CHUNK_SIZE * 0.78 + CHUNK_MARGIN:
        return

    var half_window := (CHUNK_SIZE * 0.82 + CHUNK_MARGIN) / length
    var t0 := maxf(0.0, closest_t - half_window)
    var t1 := minf(1.0, closest_t + half_window)
    var first_distance := floorf(t0 * length / PATCH_SPACING) * PATCH_SPACING
    var last_distance := t1 * length
    var direction := segment / length
    var angle := atan2(direction.y, direction.x)
    var distance := first_distance

    while distance <= last_distance + PATCH_SPACING:
        var t := clampf(distance / length, 0.0, 1.0)
        var world_pos := a.lerp(b, t)
        if world_pos.x >= origin.x - CHUNK_MARGIN and world_pos.x < origin.x + CHUNK_SIZE + CHUNK_MARGIN \
        and world_pos.y >= origin.y - CHUNK_MARGIN and world_pos.y < origin.y + CHUNK_SIZE + CHUNK_MARGIN:
            # Do not paint a dirt road underneath water. The bridge above owns
            # this crossing; fords remain terrain features rather than submerged
            # road boxes.
            if not WorldData.water_kind_at(world_pos).is_empty():
                distance += PATCH_SPACING
                continue
            var local := world_pos - origin
            var height := WorldData.elevation_at(world_pos) + 0.035
            var basis := Basis(Vector3.UP, -angle)
            transforms.append(Transform3D(basis, Vector3(local.x, height, local.y)))
        distance += PATCH_SPACING

func road_chunk_count() -> int:
    return materialized_road_chunks

func road_patch_count() -> int:
    return materialized_patches

func bridge_chunk_count() -> int:
    return materialized_bridge_chunks
