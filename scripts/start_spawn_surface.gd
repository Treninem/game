extends StaticBody3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const SURFACE_SIZE := Vector3(38.0, 0.20, 38.0)

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
