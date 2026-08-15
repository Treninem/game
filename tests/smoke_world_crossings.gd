extends Node

const HYDROLOGY := preload("res://scripts/world_hydrology.gd")
const CHUNK_SIZE := 192.0

func _ready() -> void:
    await get_tree().process_frame
    var failures: Array[String] = []
    var bridge_center := HYDROLOGY.ROAD_BRIDGE_CENTER
    var chunk_origin := Vector2(floorf(bridge_center.x / CHUNK_SIZE) * CHUNK_SIZE, floorf(bridge_center.y / CHUNK_SIZE) * CHUNK_SIZE)
    var chunk := Node3D.new()
    chunk.name = "CrossingTestChunk"
    chunk.position = Vector3(chunk_origin.x, 0.0, chunk_origin.y)
    add_child(chunk)
    WorldRoads._materialize_chunk(chunk)
    await get_tree().process_frame
    var bridge := chunk.get_node_or_null("RoadBridge")
    if bridge == null:
        failures.append("Streamed Asterna road chunk did not materialize RoadBridge")
    else:
        var deck := bridge.get_node_or_null("Deck") as MeshInstance3D
        if deck == null or deck.mesh == null:
            failures.append("RoadBridge has no physical deck mesh")
        var body := bridge.get_node_or_null("BridgeCollision") as StaticBody3D
        if body == null:
            failures.append("RoadBridge has no StaticBody3D load-bearing collision")
        else:
            var shape_node := body.get_node_or_null("DeckShape") as CollisionShape3D
            if shape_node == null or shape_node.shape == null:
                failures.append("RoadBridge collision body has no deck collision shape")
            elif shape_node.shape is BoxShape3D:
                var box := shape_node.shape as BoxShape3D
                if box.size.x < HYDROLOGY.ROAD_BRIDGE_HALF_LENGTH * 1.9:
                    failures.append("RoadBridge collision does not span the river crossing")
                if box.size.z < HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH * 1.9:
                    failures.append("RoadBridge collision is narrower than its carriageway")
            for guard_name in ["RailLeftShape", "RailRightShape"]:
                var guard := body.get_node_or_null(guard_name) as CollisionShape3D
                if guard == null or guard.shape == null:
                    failures.append("RoadBridge is missing physical side guard %s" % guard_name)
        for approach_name in ["ApproachNear", "ApproachFar"]:
            var approach := bridge.get_node_or_null(approach_name) as MeshInstance3D
            if approach == null or approach.mesh == null:
                failures.append("RoadBridge is missing visible %s ramp" % approach_name)
            var approach_body := bridge.get_node_or_null("%sCollision" % approach_name) as StaticBody3D
            if approach_body == null:
                failures.append("RoadBridge %s ramp is not load-bearing" % approach_name)
            else:
                var approach_shape := approach_body.get_node_or_null("Shape") as CollisionShape3D
                if approach_shape == null or approach_shape.shape == null:
                    failures.append("RoadBridge %s ramp has no collision shape" % approach_name)
                elif approach_shape.shape is BoxShape3D:
                    var approach_box := approach_shape.shape as BoxShape3D
                    if approach_box.size.x < 10.0:
                        failures.append("RoadBridge %s ramp is too short for a smooth road transition" % approach_name)
                    if approach_box.size.z < HYDROLOGY.ROAD_BRIDGE_HALF_WIDTH * 1.9:
                        failures.append("RoadBridge %s ramp is narrower than the carriageway" % approach_name)
        if deck != null:
            var deck_world_y := chunk.global_position.y + deck.position.y
            var water_y := WorldData.water_level_at(bridge_center)
            if deck_world_y < water_y + HYDROLOGY.ROAD_BRIDGE_CLEARANCE - 0.05:
                failures.append("RoadBridge deck is not safely above river water")
        if bridge.get_node_or_null("RailLeft") == null or bridge.get_node_or_null("RailRight") == null:
            failures.append("RoadBridge is missing visible side rails")
    if HYDROLOGY.crossing_kind_at(bridge_center) != "bridge":
        failures.append("Bridge geometry and hydrology crossing classification disagree")
    if WorldData.water_kind_at(bridge_center) != "river":
        failures.append("Physical bridge unexpectedly removes river water")
    if failures.is_empty():
        print("WORLD_CROSSINGS_SMOKE_OK bridge=streamed deck=physical approaches=physical guards=physical river=preserved")
        get_tree().quit(0)
        return
    for failure in failures:
        push_error(failure)
    get_tree().quit(1)
