extends Node

var failures: Array[String] = []
var finished := false

func _ready() -> void:
    get_tree().create_timer(90.0).timeout.connect(func():
        if not finished:
            push_error("Capital gameplay watchdog expired")
            get_tree().quit(1)
    )
    call_deferred("_run")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    for _frame in range(90):
        await get_tree().physics_frame
    var player := world.get_node("World/Player") as CharacterBody3D
    # Inspect the canonical capital itself, not the separate border settlement.
    # Reposition only this isolated test character; no user save is loaded.
    var start := CapitalData.to_world(Vector2(0, 1500))
    player.global_position = Vector3(start.x, WorldData.elevation_at(start) + 0.08, start.y)
    player.call("_begin_ground_guard", true)
    for _frame in range(240):
        await get_tree().physics_frame
    var city := world.get_node("World/CityDistrict")
    var perimeter := world.get_node("World/CapitalPerimeter")
    if city.loaded_cells.size() < 9:
        failures.append("Capital did not stream its surrounding city cells")
    if perimeter.gate_runtime.size() != 32:
        failures.append("Canonical capital does not have all 32 gates")
    for cell: Node3D in city.loaded_cells.values():
        if cell.find_children("AuthoredCityFacades_*", "MultiMeshInstance3D", true, false).is_empty():
            failures.append("Capital cell has no authored house facades")
        for house: StaticBody3D in cell.find_children("House_*", "StaticBody3D", true, false):
            for child in house.get_children():
                if child is MeshInstance3D and child.mesh is BoxMesh:
                    failures.append("Capital house still renders a primitive box body")
    var residents := get_tree().get_nodes_in_group("capital_resident")
    if residents.size() < 2:
        failures.append("Capital streets have no residents")
    var positions: Dictionary = {}
    for npc: Node3D in residents:
        positions[npc.get_instance_id()] = npc.global_position
    var before := player.global_position
    Input.action_press("move_forward")
    for _frame in range(180):
        await get_tree().physics_frame
    Input.action_release("move_forward")
    if player.global_position.distance_to(before) < 5.0:
        failures.append("Player cannot walk through the capital street")
    if not player.is_on_floor():
        failures.append("Player is not grounded after walking through the capital")
    var moving := 0
    for npc: CharacterBody3D in residents:
        if is_instance_valid(npc) and npc.global_position.distance_to(positions[npc.get_instance_id()]) > 0.5:
            moving += 1
        if is_instance_valid(npc) and npc.global_position.y < WorldData.elevation_at(Vector2(npc.global_position.x, npc.global_position.z)) - 0.5:
            failures.append("Capital resident fell through the ground")
    if moving < 2:
        failures.append("Capital residents have no working walking routes")
    if not residents.is_empty():
        residents[0].interact(player)
        if not DialogueManager.is_open:
            failures.append("Capital resident cannot open a dialogue")
        DialogueManager.close_dialogue()
    var landmarks := city.get_node("CapitalLandmarks")
    for anchor: Dictionary in CapitalData.PROTECTED_ANCHORS:
        var destination := CapitalData.to_world(anchor.pos)
        player.global_position = Vector3(destination.x, WorldData.elevation_at(destination) + 0.08, destination.y + 45.0)
        player.call("_begin_ground_guard", true)
        landmarks.call("_refresh_landmarks")
        var landmark := landmarks.get_node_or_null("Landmark_%s" % anchor.id) as Node3D
        if landmark == null:
            failures.append("Missing canonical landmark: %s" % anchor.id)
        elif Vector2(landmark.global_position.x, landmark.global_position.z).distance_to(destination) > 0.1:
            failures.append("Landmark has incorrect world coordinates: %s" % anchor.id)
        elif absf(landmark.global_position.y - WorldData.elevation_at(destination)) > 0.1:
            failures.append("Landmark is not grounded: %s" % anchor.id)
        if landmark != null and landmark.find_children("AtticGables", "MeshInstance3D", true, false).is_empty():
            failures.append("Landmark has open roof gables: %s" % anchor.id)
        if landmark != null:
            var batches := landmark.find_children("*", "MultiMeshInstance3D", true, false)
            if batches.is_empty():
                failures.append("Landmark modules are not batched: %s" % anchor.id)
            for batch: MultiMeshInstance3D in batches:
                for index in range(batch.multimesh.instance_count):
                    var transform := batch.global_transform * batch.multimesh.get_instance_transform(index)
                    if Vector2(transform.origin.x, transform.origin.z).distance_to(destination) > 100.0:
                        failures.append("Batched facade escaped its landmark: %s" % anchor.id)
    player.global_position = Vector3(65, 10, 48)
    landmarks.call("_refresh_landmarks")
    if not landmarks.loaded_landmarks.is_empty():
        failures.append("Capital landmarks do not unload outside the capital")
    if failures.is_empty():
        print("CAPITAL_GAMEPLAY_SMOKE_OK city=Lumengrad gates=32 cells=%d residents=%d walking=%d player=grounded dialogue=working" % [city.loaded_cells.size(), residents.size(), moving])
    else:
        for failure in failures:
            push_error(failure)
    # Release the owned world, then allow queued audio stops to drain.
    world.queue_free()
    await get_tree().create_timer(0.15, true).timeout
    finished = true
    get_tree().quit(0 if failures.is_empty() else 1)
