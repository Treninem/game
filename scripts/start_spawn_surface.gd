extends StaticBody3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const SURFACE_SIZE := Vector3(38.0, 0.20, 38.0)
const FALLBACK_VISUAL_SIZE := Vector3(38.0, 0.08, 38.0)
const FALLBACK_VISUAL_LOCAL_Y := -0.04

func _ready() -> void:
    name = "StoryStartSurface"
    collision_layer = 1
    collision_mask = 1
    var spawn := GEOGRAPHY.START_SPAWN
    var terrain_y := WorldData.elevation_at(spawn)
    position = Vector3(spawn.x, terrain_y - SURFACE_SIZE.y * 0.5, spawn.y)

    var collision := CollisionShape3D.new()
    collision.name = "StoryStartSurfaceCollision"
    var shape := BoxShape3D.new()
    shape.size = SURFACE_SIZE
    collision.shape = shape
    add_child(collision)

    # Keep a simple primitive just below the generated terrain. In normal play it
    # stays hidden by the streamed terrain. If a renderer/import regression makes
    # the first terrain mesh disappear while physics still exists, the player sees
    # an earthy surface instead of a grey void while the loading gate can report
    # the visual failure.
    var fallback_visual := MeshInstance3D.new()
    fallback_visual.name = "StoryStartVisualFallback"
    var fallback_mesh := BoxMesh.new()
    fallback_mesh.size = FALLBACK_VISUAL_SIZE
    fallback_visual.mesh = fallback_mesh
    fallback_visual.position.y = FALLBACK_VISUAL_LOCAL_Y
    fallback_visual.visibility_range_end = 96.0
    var fallback_material := StandardMaterial3D.new()
    fallback_material.albedo_color = Color(0.16, 0.24, 0.12, 1.0)
    fallback_material.roughness = 1.0
    fallback_visual.material_override = fallback_material
    add_child(fallback_visual)
