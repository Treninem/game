extends Node3D

const RESOURCE := preload("res://scripts/streamed_resource.gd")
const STREAMER := preload("res://scripts/world_streamer.gd")
const NATURE := preload("res://scripts/production_nature.gd")
var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    await _check_combat()
    for type in ["wood", "stone", "berries"]:
        var resource := RESOURCE.new()
        resource.configure("visual_fixture_" + type, type, 1)
        add_child(resource)
        if resource.get_node_or_null("Visual/AuthoredResource") == null:
            failures.append("Missing authored resource model: " + type)
        if type == "stone":
            var convex := false
            for child in resource.get_children():
                if child is CollisionShape3D and child.shape is ConvexPolygonShape3D:
                    convex = true
            if not convex:
                failures.append("Rock collision does not follow authored mesh")
        if type == "berries" and resource.collision_layer != 2:
            failures.append("Soft bush becomes a platform")
        var before := int(GameState.inventory.get(type, 0))
        resource.interact(null)
        if type == "wood":
            if int(GameState.inventory.get(type, 0)) != before or resource.uses != 1:
                failures.append("Standing tree yields wood without an axe")
        elif int(GameState.inventory.get(type, 0)) != before + 1 or resource.collision_layer != 0 or resource.visual_root.visible:
            failures.append("Resource depletion broke: " + type)
        resource.free()

    var grove := Node3D.new()
    add_child(grove)
    var transforms: Array[Transform3D] = [Transform3D.IDENTITY]
    NATURE.add_batches(grove, transforms, true)
    if grove.get_node_or_null("PhysicalTreeTrunks") == null:
        failures.append("Distant world has no physical tree trunks")
    for child in grove.get_children():
        if child is MultiMeshInstance3D and child.visibility_range_begin > 0:
            failures.append("Trees disappear when approached")
    grove.free()

    var streamer := STREAMER.new()
    add_child(streamer)
    streamer.set_process(false)
    var poi: Dictionary = {}
    for entry in WorldData.poi_catalog():
        if String(entry.get("kind", "")) == "danger":
            poi = entry
            break
    if poi.is_empty():
        failures.append("No authored danger area exists")
    else:
        var position: Vector2 = poi.pos
        var coord: Vector2i = streamer.call("_world_to_chunk", position)
        var chunk := Node3D.new()
        var origin: Vector2 = streamer.call("_chunk_origin", coord)
        chunk.position = Vector3(origin.x, 0, origin.y)
        add_child(chunk)
        streamer.call("_add_landmark_if_needed", chunk, coord)
        var enemies: Array[Node] = []
        for child in chunk.get_children():
            if child.is_in_group("hostile"):
                enemies.append(child)
        if enemies.size() != 2:
            failures.append("Danger area does not spawn its live encounter")
        for enemy in enemies:
            if enemy.get_node_or_null("Avatar") == null:
                failures.append("Enemy has no skinned human")
            var coins := GameState.coins
            var meat := int(GameState.inventory.get("raw_meat", 0))
            enemy.take_damage(1000, null, true)
            if GameState.coins != coins + 3 or int(GameState.inventory.get("raw_meat", 0)) != meat:
                failures.append("Human enemy loot is incorrect")
        chunk.free()
        var reloaded := Node3D.new()
        add_child(reloaded)
        streamer.call("_add_landmark_if_needed", reloaded, coord)
        if reloaded.get_child_count() != 0:
            failures.append("Defeated encounter respawns after chunk reload")
        reloaded.free()
    streamer.free()
    if failures.is_empty():
        print("LIVING_WORLD_OK authored_resources=3 depletion=true physical_near_trees=true encounter=2 persistent_loot=true")
    else:
        for failure in failures:
            push_error(failure)
    get_tree().quit(0 if failures.is_empty() else 1)

func _check_combat() -> void:
    var origin := WorldGeography.START_SPAWN
    var height := WorldData.elevation_at(origin)
    var fixture := Node3D.new()
    fixture.position = Vector3(origin.x, height, origin.y)
    add_child(fixture)
    var floor := StaticBody3D.new()
    var floor_shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(12, 1, 12)
    floor_shape.shape = box
    floor_shape.position.y = -0.5
    floor.add_child(floor_shape)
    fixture.add_child(floor)
    var target := CharacterBody3D.new()
    target.add_to_group("player")
    fixture.add_child(target)
    var enemy := preload("res://scripts/enemy.gd").new()
    enemy.position = Vector3(0, 0.05, 1.5)
    enemy.enemy_id = "attack_fixture"
    fixture.add_child(enemy)
    GameState.health = 100
    for frame in range(120):
        await get_tree().physics_frame
    if not enemy.ground_ready or GameState.health >= 100:
        failures.append("Live enemy cannot ground and attack a reachable player")
    var wall := StaticBody3D.new()
    var wall_shape := CollisionShape3D.new()
    box = BoxShape3D.new()
    box.size = Vector3(3, 3, 0.15)
    wall_shape.shape = box
    wall_shape.position = Vector3(0, 1.5, 0.75)
    wall.add_child(wall_shape)
    fixture.add_child(wall)
    for frame in range(3):
        await get_tree().physics_frame
    GameState.health = 100
    for frame in range(120):
        await get_tree().physics_frame
    if GameState.health < 100:
        failures.append("Enemy deals melee damage through a solid wall")
    fixture.free()
