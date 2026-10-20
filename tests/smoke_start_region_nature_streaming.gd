extends Node

const START_REGION_STREAMER := preload("res://scripts/start_region_streamer.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const MAX_DETAIL_CELLS := 25

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Start-region nature smoke::%s" % clean)
    push_error("Start-region nature smoke: %s" % message)
    get_tree().quit(code)

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _run_test() -> void:
    var variants := {}
    for scene: PackedScene in START_REGION_STREAMER.TREE_PALETTE:
        variants[scene.resource_path] = true
    if variants.size() != START_REGION_STREAMER.TREE_PALETTE.size() or variants.size() < 2:
        _fail(2, "tree variation aliases the same model more than once")
        return
    var nature := preload("res://scripts/production_nature.gd")
    for scene: PackedScene in [START_REGION_STREAMER.TREE_OAK, START_REGION_STREAMER.TREE_BROAD]:
        var prototype := scene.instantiate()
        nature.prepare(prototype)
        var count_before := nature.bark_materials.size()
        nature.prepare(prototype)
        if nature.bark_materials.size() != count_before:
            _fail(2, "repeated tree preparation leaks bark materials")
            return
        var bark_count := 0
        for mesh: MeshInstance3D in prototype.find_children("*", "MeshInstance3D", true, false):
            for surface in range(mesh.mesh.get_surface_count()):
                var original := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
                if original == null or "Bark_Temperate" not in original.resource_name:
                    continue
                var bark := mesh.get_active_material(surface) as StandardMaterial3D
                if bark == null or bark.albedo_texture != nature.BARK or original.albedo_texture == nature.BARK:
                    _fail(2, "original bark restoration missing or shared source was mutated")
                    return
                bark_count += 1
        prototype.free()
        if bark_count == 0:
            _fail(2, "no actual bark surface validated")
            return
    var ground := START_REGION_STREAMER.GROUND_GRASS.instantiate()
    var grass_triangles := 0
    for mesh: MeshInstance3D in ground.find_children("*","MeshInstance3D",true,false):
        for surface in range(mesh.mesh.get_surface_count()):
            grass_triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
    ground.free()
    if grass_triangles <= 0 or grass_triangles > 180:
        _fail(2,"dense ground cover lost its low-triangle production mesh")
        return
    var player := CharacterBody3D.new()
    player.name = "NatureStreamingTestPlayer"
    player.add_to_group("player")
    player.position = Vector3(GEOGRAPHY.START_SPAWN.x, 3.0, GEOGRAPHY.START_SPAWN.y)
    add_child(player)

    var streamer := START_REGION_STREAMER.new() as Node3D
    if streamer == null:
        _fail(2, "start-region streamer could not be instantiated")
        return
    streamer.name = "StartRegionStreamerUnderTest"
    add_child(streamer)

    await _wait_frames(38)
    var first_center: Vector2i = streamer.call("detail_center_cell")
    var first_cells := int(streamer.call("loaded_detail_cell_count"))
    if first_cells <= 0 or first_cells > MAX_DETAIL_CELLS:
        _fail(3, "initial detail-cell budget invalid: %d" % first_cells)
        return
    if int(streamer.get("real_tree_count")) <= 0 or int(streamer.get("real_nature_detail_count")) <= 0:
        _fail(4, "production nature did not materialize around the start spawn")
        return

    if START_REGION_STREAMER.MAX_DETAIL_OBJECTS > 1850 or START_REGION_STREAMER.GROUND_COVER_GRID > 40:
        _fail(4,"ground cover budget exceeds the fixed production ceiling")
        return
    var ground_cover := 0
    var extra_trees := 0
    var ground_batches := 0
    var roots: Array[Vector2] = []
    for cell: Node in streamer.get("loaded_detail_cells").values():
        ground_cover += int(cell.get_meta("ground_cover_count",0))
        extra_trees += int(cell.get_meta("extra_tree_count",0))
        if int(cell.get_meta("detail_count", 0)) > START_REGION_STREAMER.MAX_DETAIL_OBJECTS:
            _fail(4, "understory exceeded the fixed per-cell detail budget")
            return
        for child in cell.get_children():
            if child is MultiMeshInstance3D and "Grass_Ground" in String(child.get_meta("tree_source","")):
                ground_batches += 1
            if child.is_in_group("map_tree"):
                var point: Vector3 = child.global_position
                var xz := Vector2(point.x,point.z)
                for other in roots:
                    if other.distance_to(xz) < START_REGION_STREAMER.TREE_TRUNK_CLEARANCE - 0.01:
                        _fail(4, "near physical tree trunks intersect the minimum clearance")
                        return
                roots.append(xz)
    if ground_cover < 5000 or extra_trees < 30 or ground_batches <= first_cells:
        _fail(4,"understory density or local spatial batches did not materialize")
        return
    print("UNDERSTORY_METRICS cells=",first_cells," ground_clumps=",ground_cover," extra_trees=",extra_trees," ground_batches=",ground_batches)
    player.position = Vector3(1000.0, 3.0, 800.0)
    await _wait_frames(38)
    var moved_center: Vector2i = streamer.call("detail_center_cell")
    var moved_cells := int(streamer.call("loaded_detail_cell_count"))
    if moved_center == first_center:
        _fail(5, "detail streamer did not follow player movement")
        return
    if moved_cells <= 0 or moved_cells > MAX_DETAIL_CELLS:
        _fail(6, "moving detail-cell budget invalid: %d" % moved_cells)
        return
    if int(streamer.get("real_nature_detail_count")) <= 0:
        _fail(7, "near-field production nature disappeared while still inside start region")
        return

    player.position = Vector3(3000.0, 3.0, 3000.0)
    await _wait_frames(4)
    if int(streamer.call("loaded_detail_cell_count")) != 0:
        _fail(8, "detail cells were retained after leaving the start region")
        return
    if int(streamer.get("real_tree_count")) != 0 or int(streamer.get("real_nature_detail_count")) != 0:
        _fail(9, "detail counters did not clear after leaving the start region")
        return

    player.position = Vector3(GEOGRAPHY.START_SPAWN.x, 3.0, GEOGRAPHY.START_SPAWN.y)
    await _wait_frames(32)
    var rebuilt_cells := int(streamer.call("loaded_detail_cell_count"))
    if rebuilt_cells <= 0 or rebuilt_cells > MAX_DETAIL_CELLS:
        _fail(10, "detail streamer did not rebuild within budget after re-entering")
        return
    if int(streamer.get("real_nature_detail_count")) <= 0:
        _fail(11, "production nature did not rebuild after re-entering")
        return

    print("Start-region nature smoke passed: production detail follows player, stays bounded and unloads outside region")
    get_tree().quit(0)
