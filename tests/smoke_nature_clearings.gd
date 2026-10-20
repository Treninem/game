extends Node

func _ready() -> void:
    var streamer := preload("res://scripts/world_streamer.gd").new()
    var village := Vector2(1650,-420)
    var center: Vector2i = streamer.call("_world_to_chunk",village)
    var planted := 0
    var intrusions := 0
    for z in range(-1,2):
        for x in range(-1,2):
            var coord := center+Vector2i(x,z)
            var origin: Vector2 = streamer.call("_chunk_origin",coord)
            var chunk := Node3D.new()
            chunk.position=Vector3(origin.x,0,origin.y)
            add_child(chunk)
            streamer.call("_add_vegetation",chunk,coord,"forest")
            var positions: Array = chunk.get_meta("map_tree_positions",[])
            for local: Vector3 in positions:
                planted += 1
                if (origin+Vector2(local.x,local.z)).distance_to(village)<185.0:
                    intrusions += 1
            chunk.queue_free()
    streamer.free()
    await get_tree().process_frame
    print("NATURE_CLEARING_METRICS surrounding_trees=",planted," village_intrusions=",intrusions)
    if planted < 20 or intrusions != 0:
        push_error("Streamed forest must surround the village without growing inside its clearing")
        get_tree().quit(1)
        return
    print("NATURE_CLEARINGS_SMOKE_OK")
    get_tree().quit()
