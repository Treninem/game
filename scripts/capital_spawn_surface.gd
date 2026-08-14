extends StaticBody3D

const SPAWN_XZ := Vector2(0.0, 8.0)
const SURFACE_SIZE := Vector3(176.0, 0.24, 176.0)

func _ready() -> void:
    name = "CapitalSpawnSurface"
    collision_layer = 1
    collision_mask = 1
    var terrain_y := WorldData.elevation_at(SPAWN_XZ)
    position = Vector3(SPAWN_XZ.x, terrain_y - SURFACE_SIZE.y * 0.5, SPAWN_XZ.y)

    var collision := CollisionShape3D.new()
    collision.name = "SpawnSurfaceCollision"
    var shape := BoxShape3D.new()
    shape.size = SURFACE_SIZE
    collision.shape = shape
    add_child(collision)
