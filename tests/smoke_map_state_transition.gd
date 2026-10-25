extends Node

class MapCanvas:
    extends Control
    var renderer = preload("res://scripts/local_map_renderer.gd").new()
    func _draw() -> void:
        renderer.draw_terrain(self, Rect2(0, 0, 240, 240), Vector2(65, 48), 80.0)

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    MapSystem.set_process(false)
    GameState.reset_new_game()
    var player := Node3D.new()
    player.position = Vector3(65, 0, 48)
    player.add_to_group("player")
    add_child(player)
    MapSystem._process(0.0)
    var ally := Node3D.new()
    ally.position = Vector3(70, 0, 48)
    ally.add_to_group("ally")
    add_child(ally)
    MapSystem.refresh_features()
    var canvas := MapCanvas.new()
    canvas.size = Vector2(240, 240)
    add_child(canvas)
    await RenderingServer.frame_post_draw
    var bright: float = canvas.renderer.texture.get_image().get_pixel(24, 24).get_luminance()
    if bright < 0.06:
        failures.append("Revealed map fixture did not render actual terrain")
    var snapshot := GameState.snapshot()
    ally.free()
    GameState.load_snapshot({"world_state": {}})
    canvas.queue_redraw()
    await RenderingServer.frame_post_draw
    var hidden: float = canvas.renderer.texture.get_image().get_pixel(24, 24).get_luminance()
    if hidden > 0.05:
        failures.append("Terrain cache leaks the previous save's explored area")
    if MapSystem.features_near(Vector2(65, 48), 80).any(func(feature): return feature.kind == "ally"):
        failures.append("Previous save's living actor survives the map transition")
    MapSystem._process(0.0)
    if not MapSystem.is_world_explored(Vector2(65, 48)):
        failures.append("Loading at the same player cell does not reveal current surroundings")
    GameState.load_snapshot(snapshot)
    canvas.queue_redraw()
    await RenderingServer.frame_post_draw
    if canvas.renderer.texture.get_image().get_pixel(24, 24).get_luminance() < 0.06:
        failures.append("Loading the explored save does not restore its terrain cache")
    GameState.reset_new_game()
    MapSystem._process(0.0)
    if not MapSystem.is_world_explored(Vector2(65, 48)):
        failures.append("New Game at the same cell leaves its map unexplored")
    if MapSystem.terrain_color(Vector2(15000, 15000)).get_luminance() > 0.05:
        failures.append("State transition reveals unvisited distant terrain")
    print("MAP_STATE_SAMPLES explored=",bright," hidden_after_load=",hidden)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("MAP_STATE_TRANSITION_OK load=same_cell reset=revealed fog=preserved actors=cleared cache=refreshed")
    get_tree().quit(0 if failures.is_empty() else 1)
