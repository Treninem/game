extends Node

const STREAMER := preload("res://scripts/world_streamer.gd")

func _ready() -> void:
    var streamer := STREAMER.new()
    # Generate without adding the streamer to the tree: test the real mesh builder
    # without asynchronous world streaming or unrelated game state.
    for coord in [Vector2i.ZERO, Vector2i(-1, -1), Vector2i(70, -37)]:
        var mesh: ArrayMesh = streamer.call("_build_terrain_mesh", coord)
        var arrays := mesh.surface_get_arrays(0)
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        for normal in normals:
            if not normal.is_finite() or normal.y <= 0.0:
                push_error("Terrain surface faces away from the player above it at %s" % coord)
                streamer.free()
                get_tree().quit(1)
                return
        if mesh.create_trimesh_shape() == null:
            push_error("Terrain collision could not be generated")
            streamer.free()
            get_tree().quit(2)
            return
    streamer.free()
    print("TERRAIN_SURFACE_SMOKE_OK upward_normals=all collision=ready")
    get_tree().quit()
