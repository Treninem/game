extends Node

const CHUNK_SIZE := 192.0
const SAMPLE_SPACING := 12.0
const CHUNK_MARGIN := 6.0
const PATCH_THICKNESS := 0.018

var water_material: StandardMaterial3D
var materialized_water_chunks := 0
var materialized_water_patches := 0
var materialized_by_kind := {"river": 0, "lake": 0, "sea": 0}

func _ready() -> void:
    water_material = StandardMaterial3D.new()
    water_material.albedo_color = Color(0.065, 0.31, 0.43, 0.78)
    water_material.metallic = 0.08
    water_material.roughness = 0.18
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
    if node is Node3D and node.name.begins_with("WorldChunk_"):
        call_deferred("_materialize_chunk", node)

func _materialize_chunk(chunk: Node3D) -> void:
    if not is_instance_valid(chunk) or chunk.get_node_or_null("WaterSurface") != null:
        return

    var origin := Vector2(chunk.global_position.x, chunk.global_position.z)
    var transforms: Array[Transform3D] = []
    var kind_counts := {"river": 0, "lake": 0, "sea": 0}
    var steps := int(ceil(CHUNK_SIZE / SAMPLE_SPACING))

    for z_index in range(steps):
        for x_index in range(steps):
            var local_x := (float(x_index) + 0.5) * SAMPLE_SPACING
            var local_z := (float(z_index) + 0.5) * SAMPLE_SPACING
            if local_x > CHUNK_SIZE + CHUNK_MARGIN or local_z > CHUNK_SIZE + CHUNK_MARGIN:
                continue
            var world_pos := origin + Vector2(local_x, local_z)
            var kind := WorldData.water_kind_at(world_pos)
            if kind.is_empty():
                continue
            var water_level := WorldData.water_level_at(world_pos)
            if is_inf(water_level):
                continue
            transforms.append(Transform3D(Basis.IDENTITY, Vector3(local_x, water_level, local_z)))
            kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1

    if transforms.is_empty():
        return

    var patch_mesh := BoxMesh.new()
    patch_mesh.size = Vector3(SAMPLE_SPACING + 0.2, PATCH_THICKNESS, SAMPLE_SPACING + 0.2)
    patch_mesh.material = water_material

    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = patch_mesh
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        multimesh.set_instance_transform(i, transforms[i])

    var surface := MultiMeshInstance3D.new()
    surface.name = "WaterSurface"
    surface.multimesh = multimesh
    surface.visibility_range_end = CHUNK_SIZE * 3.75
    chunk.add_child(surface)

    materialized_water_chunks += 1
    materialized_water_patches += transforms.size()
    for kind in kind_counts:
        materialized_by_kind[kind] = int(materialized_by_kind.get(kind, 0)) + int(kind_counts[kind])

func water_chunk_count() -> int:
    return materialized_water_chunks

func water_patch_count() -> int:
    return materialized_water_patches

func patch_count_for(kind: String) -> int:
    return int(materialized_by_kind.get(kind, 0))
