extends Node

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const CHUNK_SIZE := 192.0
const PATCH_SPACING := 9.0
const CHUNK_MARGIN := 8.0

var road_material: StandardMaterial3D
var materialized_road_chunks := 0
var materialized_patches := 0

func _ready() -> void:
    road_material = StandardMaterial3D.new()
    road_material.albedo_color = Color(0.29, 0.20, 0.105, 1.0)
    road_material.roughness = 0.98
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name.begins_with("WorldChunk_"):
        call_deferred("_materialize_chunk", node)

func _materialize_chunk(chunk: Node3D) -> void:
    if not is_instance_valid(chunk) or chunk.get_node_or_null("RoadSurface") != null:
        return

    var origin := Vector2(chunk.global_position.x, chunk.global_position.z)
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
            var local := world_pos - origin
            var height := WorldData.elevation_at(world_pos) + 0.035
            var basis := Basis(Vector3.UP, -angle)
            transforms.append(Transform3D(basis, Vector3(local.x, height, local.y)))
        distance += PATCH_SPACING

func road_chunk_count() -> int:
    return materialized_road_chunks

func road_patch_count() -> int:
    return materialized_patches
