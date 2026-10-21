extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const HYDROLOGY := preload("res://scripts/world_hydrology.gd")
const PATHS := preload("res://scripts/terrain_paths.gd")
const CHUNK_SIZE := 192.0
const BRIDGE_DECK_THICKNESS := 0.34
const BRIDGE_RAIL_HEIGHT := 0.16
const BRIDGE_RAIL_THICKNESS := 0.18
const BRIDGE_RAIL_OFFSET_Y := 0.72
const BRIDGE_APPROACH_LENGTH := 14.0

var road_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var bridge_rail_material: StandardMaterial3D
var materialized_road_chunks := 0
var materialized_patches := 0
var materialized_bridge_chunks := 0

func _ready() -> void:
    road_material = PATHS.material("gravel")
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
    var footprints: Array[PackedVector2Array] = []
    for road in WorldData.road_catalog():
        var points: Array = road.get("points", [])
        for i in range(points.size() - 1):
            footprints.append(PATHS.strip(points[i], points[i+1], GEOGRAPHY.PRIMARY_ROAD_HALF_WIDTH*2.0))
    var mesh := PATHS.build(footprints, chunk.global_transform, Rect2(origin, Vector2.ONE*CHUNK_SIZE), true)
    if mesh == null:
        return
    var surface := MeshInstance3D.new()
    surface.name = "RoadSurface"
    surface.mesh = mesh
    surface.material_override = road_material
    surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    surface.visibility_range_end = CHUNK_SIZE * 3.5
    chunk.add_child(surface)
    materialized_road_chunks += 1
    materialized_patches += mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3

func _materialize_bridge_if_owned(chunk: Node3D, origin: Vector2) -> void:
    if chunk.get_node_or_null("RoadBridge") != null:
        return
    var center := HYDROLOGY.ROAD_BRIDGE_CENTER
    if center.x < origin.x or center.x >= origin.x + CHUNK_SIZE or center.y < origin.y or center.y >= origin.y + CHUNK_SIZE:
        return
    var direction := HYDROLOGY.ROAD_BRIDGE_DIRECTION.normalized()
    var half_length := HYDROLOGY.ROAD_BRIDGE_HALF_LENGTH
    var a2 := center - direction * half_length
    var b2 := center + direction * half_length
    var water_level := WorldData.water_level_at(center)
    var deck_y := maxf(maxf(WorldData.elevation_at(a2), WorldData.elevation_at(b2)) + 0.12, water_level + HYDROLOGY.ROAD_BRIDGE_CLEARANCE)
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
    deck.transform = Transform3D(bridge_basis, Vector3(local_center.x, deck_y, local_center.y))
    deck.visibility_range_end = CHUNK_SIZE * 3.5
    bridge.add_child(deck)
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
    _add_bridge_rail(bridge, body, local_center, deck_y, bridge_basis, -1.0)
    _add_bridge_rail(bridge, body, local_center, deck_y, bridge_basis, 1.0)
    _add_bridge_support(bridge, origin, center - direction * 18.0, deck_y, bridge_basis)
    _add_bridge_support(bridge, origin, center + direction * 18.0, deck_y, bridge_basis)
    _add_bridge_approach(bridge, origin, center, direction, deck_y, bridge_basis, -1.0)
    _add_bridge_approach(bridge, origin, center, direction, deck_y, bridge_basis, 1.0)
    materialized_bridge_chunks += 1

func _add_bridge_rail(bridge: Node3D, body: StaticBody3D, local_center: Vector2, deck_y: float, bridge_basis: Basis, side_sign: float) -> void:
    var rail_size := Vector3(HYDROLOGY.ROAD_BRIDGE_HALF_LENGTH * 2.0, BRIDGE_RAIL_HEIGHT, BRIDGE_RAIL_THICKNESS)
    var rail_mesh := BoxMesh.new()
    rail_mesh.size = rail_size
    rail_mesh.material = bridge_rail_material
    var rail := MeshInstance3D.new()
    var side_name := "Left" if side_sign < 0.0 else "Right"
    rail.name = "Rail%s" % side_name
    var side_offset := HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH - 0.22
    var local_offset := bridge_basis * Vector3(0.0, BRIDGE_RAIL_OFFSET_Y, side_offset * side_sign)
    rail.transform = Transform3D(bridge_basis, Vector3(local_center.x, deck_y, local_center.y) + local_offset)
    bridge.add_child(rail)
    var guard_shape := BoxShape3D.new()
    guard_shape.size = rail_size
    var guard := CollisionShape3D.new()
    guard.name = "Rail%sShape" % side_name
    guard.position = Vector3(0.0, BRIDGE_RAIL_OFFSET_Y, side_offset * side_sign)
    guard.shape = guard_shape
    body.add_child(guard)

func _add_bridge_support(bridge: Node3D, origin: Vector2, world_pos: Vector2, deck_y: float, bridge_basis: Basis) -> void:
    var bed_y := WorldData.elevation_at(world_pos)
    var support_height := maxf(0.4, deck_y - bed_y)
    var support_mesh := BoxMesh.new()
    support_mesh.size = Vector3(0.9, support_height, HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH * 1.72)
    support_mesh.material = bridge_rail_material
    var support := MeshInstance3D.new()
    support.name = "Pier"
    var local := world_pos - origin
    support.transform = Transform3D(bridge_basis, Vector3(local.x, bed_y + support_height * 0.5, local.y))
    bridge.add_child(support)

func _add_bridge_approach(bridge: Node3D, origin: Vector2, center: Vector2, direction: Vector2, deck_y: float, bridge_basis: Basis, end_sign: float) -> void:
    var end_world := center + direction * HYDROLOGY.ROAD_BRIDGE_HALF_LENGTH * end_sign
    var outer_world := end_world + direction * BRIDGE_APPROACH_LENGTH * end_sign
    var terrain_y := WorldData.elevation_at(outer_world) + 0.08
    var rise := deck_y - terrain_y
    var length := sqrt(BRIDGE_APPROACH_LENGTH * BRIDGE_APPROACH_LENGTH + rise * rise)
    var pitch := atan2(-rise * end_sign, BRIDGE_APPROACH_LENGTH)
    var approach_basis := bridge_basis * Basis(Vector3(0.0, 0.0, 1.0), pitch)
    var midpoint := (end_world + outer_world) * 0.5 - origin
    var midpoint_y := (deck_y + terrain_y) * 0.5
    var mesh := BoxMesh.new()
    mesh.size = Vector3(length, BRIDGE_DECK_THICKNESS, HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH * 2.0)
    mesh.material = bridge_material
    var approach := MeshInstance3D.new()
    approach.name = "ApproachNear" if end_sign < 0.0 else "ApproachFar"
    approach.mesh = mesh
    approach.transform = Transform3D(approach_basis, Vector3(midpoint.x, midpoint_y, midpoint.y))
    bridge.add_child(approach)
    var body := StaticBody3D.new()
    body.name = "%sCollision" % approach.name
    body.transform = approach.transform
    bridge.add_child(body)
    var shape := BoxShape3D.new()
    shape.size = mesh.size
    var collision := CollisionShape3D.new()
    collision.name = "Shape"
    collision.shape = shape
    body.add_child(collision)

func road_chunk_count() -> int:
    return materialized_road_chunks
func road_patch_count() -> int:
    return materialized_patches
func bridge_chunk_count() -> int:
    return materialized_bridge_chunks
