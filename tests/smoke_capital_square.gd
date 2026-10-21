extends Node

var errors: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await get_tree().physics_frame

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    await _frames(120)
    GameState.set_process(false)
    world.set_process(false) # Keep this recipe fixture at the requested work hour.
    GameState.world_minutes = 9 * 60
    var player := world.get_node("World/Player") as CharacterBody3D
    # Isolated collision/workshop fixture. This is not the no-teleport journey.
    player.global_position = Vector3(CapitalData.CENTER.x, WorldData.elevation_at(CapitalData.CENTER) + 0.08, CapitalData.CENTER.y + 14)
    player.call("_begin_ground_guard", true)
    await _frames(240)
    var city := world.get_node("World/CityDistrict")
    var cell: Node3D = city.loaded_cells.get(Vector2i.ZERO)
    var square := cell.get_node_or_null("CapitalSquareLife") if cell != null else null
    if square == null:
        push_error("Actual capital streaming did not create the working square")
        get_tree().quit(1)
        return
    if get_tree().get_nodes_in_group("capital_square_prop").size() < 15:
        errors.append("Square is missing selected authored props")
    if WorldVFX.surface_at(Vector3(CapitalData.CENTER.x, 0.04, CapitalData.CENTER.y)) != "stone":
        errors.append("Stone paving is still treated as soil for walking effects")
    for prop: Node3D in get_tree().get_nodes_in_group("capital_square_prop"):
        if prop is StaticBody3D:
            var collision := prop.get_child(prop.get_child_count() - 1) as CollisionShape3D
            if collision == null:
                errors.append("Solid square furniture has no collision")
                continue
            var box := collision.shape as BoxShape3D
            var bottom := prop.global_position.y + collision.position.y - box.size.y * 0.5
            var ground := WorldData.elevation_at(Vector2(prop.global_position.x, prop.global_position.z))
            if absf(bottom - ground - 0.025) > 0.01:
                errors.append("Authored square prop is floating above its physical ground")
    var plaza := cell.get_node("CentralPlaza") as MeshInstance3D
    var top := plaza.position.y + (plaza.mesh as BoxMesh).size.y * 0.5
    if absf(top - WorldData.elevation_at(CapitalData.CENTER)) > 0.04:
        errors.append("Rendered paving does not meet the walking surface")
    if ((plaza.mesh as BoxMesh).material as StandardMaterial3D).albedo_texture == null:
        errors.append("Capital paving lost the selected photographic texture")
    for road: MeshInstance3D in world.find_children("RoadSurface", "MeshInstance3D", true, false):
        for vertex: Vector3 in road.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
            var point := road.to_global(vertex)
            if Vector2(point.x, point.z).distance_to(CapitalData.CENTER) < 80:
                errors.append("World dirt overlay still paints over the capital paving")
    MapSystem.refresh_features()
    var fixtures := 0
    for feature: Dictionary in MapSystem.features_near(CapitalData.CENTER, 65):
        if feature.kind == "fixture":
            fixtures += 1
    if fixtures < 10:
        errors.append("Local map does not record the real square furniture footprints")
    var before := player.global_position
    Input.action_press("move_forward")
    await _frames(360)
    Input.action_release("move_forward")
    if before.distance_to(player.global_position) < 18.0 or not player.is_on_floor():
        errors.append("New furniture blocks the main square crossing or leaves the player unsupported")
    var trader := square.get_node("SquareTrader") as SettlementNPC
    var artisan := square.get_node("SquareArtisan") as SettlementNPC
    if Vector3(artisan.routine_plan(9 * 60).target).distance_to(Vector3(-23, 0, -10.3)) > 0.01:
        errors.append("Artisan's actual schedule is not linked to the authored workbench")
    var work_stock: Dictionary = trader._shop_stock()
    var arrows_before := int(work_stock.get("arrow", 0))
    var coins_before := GameState.coins
    GameState.add_item("wood", 1)
    GameState.add_item("stone", 1)
    if not trader.complete_trade("wood", true) or not trader.complete_trade("stone", true):
        errors.append("Square merchant cannot purchase real workshop inputs")
    if GameState.coins != coins_before + 2:
        errors.append("Workshop supply trade did not pay the player")
    await _frames(120)
    if String(artisan.get_meta("activity", "")) != "work":
        errors.append("Supplied artisan does not perform work at the bench")
    await _frames(480)
    work_stock = trader._shop_stock()
    if int(work_stock.get("arrow", 0)) != arrows_before + 5 or int(work_stock.get("wood", 0)) != 0 or int(work_stock.get("stone", 0)) != 0:
        errors.append("Working artisan did not consume the canonical recipe into real shop stock")
    await _frames(540)
    if int(trader._shop_stock().get("arrow", 0)) != arrows_before + 5:
        errors.append("Workshop creates free goods without supplied materials")
    if String(artisan.get_meta("activity", "")) != "idle":
        errors.append("Unsupplied artisan keeps pretending to manufacture goods")
    # A streamed-out artisan must not reset the finite shop or grant new stock.
    var saved_stock := trader._shop_stock().duplicate(true)
    square.free()
    var replacement := preload("res://scripts/capital_square_life.gd").new()
    replacement.name = "CapitalSquareLife"
    cell.add_child(replacement)
    await _frames(90)
    if replacement.get_node("SquareTrader")._shop_stock() != saved_stock:
        errors.append("Reloading the square resets finite trade/crafting state")
    GameState.world_minutes = 20 * 60
    replacement.call("_process", 1.1)
    for light: OmniLight3D in replacement.lamps:
        if not light.visible:
            errors.append("Authored stall lantern does not illuminate evening trade")
    var environment_controller := world.get_node("World/WorldEnvironmentController")
    environment_controller.call("set_time_of_day", GameState.world_minutes)
    if environment_controller.environment.ambient_light_energy < 0.5:
        errors.append("Evening fill again erases human silhouettes")
    for error in errors:
        push_error(error)
    if errors.is_empty():
        print("CAPITAL_SQUARE_OK props=authored grounded=true route=walked paving=textured workshop=canonical_recipe supplied=paid stock=finite reload=persistent lamps=evening")
    world.queue_free()
    await get_tree().process_frame
    get_tree().quit(0 if errors.is_empty() else 1)
