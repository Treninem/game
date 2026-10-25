extends Node3D

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    GameState.reset_new_game()
    position = Vector3(200, 3, -100)
    var siege := preload("res://scripts/capital_night_siege.gd").new()
    add_child(siege)
    var xz := CapitalData.CENTER + Vector2(3500, 3500)
    var expected := Vector3(xz.x, WorldData.elevation_at(xz) + 0.9, xz.y)
    siege._spawn_siege_enemy(0, 0, "fixture", 0, xz)
    var enemy := siege.get_child(0) as Node3D
    assert(enemy.global_position.distance_to(expected) < 0.01, "Siege spawn ignores translated parent")
    for child in enemy.get_children():
        if child is MeshInstance3D and child.mesh is PrimitiveMesh:
            assert(not child.visible, "Siege primitive body overlays the actual human")
    var mini := preload("res://scripts/minigame_runtime.gd").new()
    add_child(mini)
    mini.challenge_root = Node3D.new()
    mini.challenge_root.position = Vector3(4, 2, 6)
    add_child(mini.challenge_root)
    mini._spawn_arena_enemy(0, expected)
    var arena := mini.challenge_root.get_child(0) as Node3D
    assert(arena.global_position.distance_to(expected) < 0.01, "Arena spawn ignores transformed challenge root")
    for child in arena.get_children():
        if child is MeshInstance3D and child.mesh is PrimitiveMesh:
            assert(not child.visible, "Arena primitive body overlays the actual human")
    mini.race_points = [expected + Vector3(10, 0, 10)]
    mini._build_race_markers()
    var marker := mini.challenge_root.get_node("Checkpoint_00") as Node3D
    assert(marker.global_position.distance_to(mini.race_points[0]) < 0.01, "Race marker is displaced")
    var plots := preload("res://scripts/plot_runtime.gd").new()
    add_child(plots)
    var plot := plots._build_plot_root({"id": "spawn-fixture", "position": [xz.x, xz.y], "size": 32, "type": "normal"})
    assert(plot.global_position.distance_to(expected - Vector3.UP * 0.86) < 0.01, "Plot root ignores transformed parent")
    print("RUNTIME_SPAWN_TRANSFORMS_OK siege=world_position arena=world_position race=world_position plot=world_position")
    get_tree().quit(0)
