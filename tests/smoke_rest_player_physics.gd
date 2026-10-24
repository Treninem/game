extends Node3D

var player: CharacterBody3D
var home: EnterableBuilding
var checked := 0

func _ready() -> void:
    get_tree().create_timer(100).timeout.connect(func(): push_error("REST_PHYSICS timeout"); get_tree().quit(1))
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await get_tree().physics_frame

func _capture(label: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("user://rest-physics-" + label + ".png")

func _run() -> void:
    GameState.reset_new_game()
    GameState.set_world_value("current_realm", "rest_physics_fixture")
    home = EnterableBuilding.new()
    home.position.x = 60.0
    home.configure(Vector3(12, 3.2, 10))
    add_child(home)
    var decorator := SettlementInteriorVisuals.new()
    add_child(decorator)
    decorator.decorate_building(home)
    var stage := load("res://scenes/stage1.tscn").instantiate() as Node
    player = stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    add_child(player)
    player.call("_set_instanced_world_mode", true)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    add_child(sun)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = 0.65
    add_child(environment)
    var observer := Camera3D.new()
    observer.position = Vector3(60,2.4,0)
    add_child(observer)
    observer.make_current()
    var visual := player.get_node("Avatar") as Node3D
    for sex: String in ["male", "female"]:
        for height: float in [160.0,180.0,195.0]:
            GameState.set_world_value("player_appearance", {"sex":sex,"height_cm":height})
            visual.call("apply_appearance", GameState.get_world_value("player_appearance", {}))
            for name: String in ["Bed", "Bench"]:
                var furniture := home.get_node("InteriorFurniture/" + name) as HouseholdFurniture
                player.global_position = furniture.approach_point() + Vector3.UP * 0.4
                player.velocity = Vector3.ZERO
                await _frames(45)
                assert(player.is_on_floor(), "Approach has no real physical support")
                var grounded := player.global_position
                var label := "%s-%s-%s" % [sex,height,name]
                observer.look_at(furniture.global_position + Vector3.UP * 0.5)
                furniture.interact(player)
                await _frames(8)
                assert(visual.top_level and furniture.occupant == "player", "Player cannot actually use furniture: " + label)
                assert(player.is_on_floor(), "Rest displaces the physical capsule from floor")
                await _capture(label + "-rest")
                assert(SaveManager.save_game(player, 5), "Rest disk save failed")
                player.call("_leave_furniture_rest")
                assert(SaveManager.load_game(player, 5), "Rest disk load failed")
                await _frames(8)
                assert(visual.top_level and furniture.occupant == "player", "Rest disk load loses supported pose")
                GameState.stamina = GameState.max_stamina
                var event := InputEventAction.new()
                event.action = "jump"
                event.pressed = true
                Input.parse_input_event(event)
                Input.flush_buffered_events()
                assert(not visual.top_level and furniture.occupant.is_empty(), "Jump input failed immediate wake")
                assert(String(GameState.get_world_value("player:rest_furniture", "")).is_empty(), "Jump retains saved rest")
                var peak := player.global_position.y
                var airborne := false
                for frame in range(85):
                    await _frames(1)
                    peak = maxf(peak, player.global_position.y)
                    airborne = airborne or not player.is_on_floor()
                    if frame == 0:
                        event = InputEventAction.new()
                        event.action = "jump"
                        Input.parse_input_event(event)
                        Input.flush_buffered_events()
                    if frame == 10:
                        observer.look_at(player.global_position + Vector3.UP * 0.8)
                        await _capture(label + "-jump")
                assert(airborne and peak > grounded.y + 0.25, "Wake jump has no physical ascent")
                assert(player.is_on_floor() and absf(player.global_position.y - grounded.y) < 0.06, "Wake jump fails to land on approach floor")
                assert(visual.scale.distance_to(Vector3.ONE * height / 180.0) < 0.0001, "Wake jump changes appearance scale")
                assert(SaveManager.save_game(player, 5) and SaveManager.load_game(player, 5), "Wake disk round trip failed")
                await _frames(5)
                assert(not visual.top_level and furniture.occupant.is_empty(), "Wake save resurrects old rest")
                observer.look_at(player.global_position + Vector3.UP * 0.8)
                await _capture(label + "-land")
                checked += 1
                print("REST_PHYSICS_CASE ", label, " ascent=", peak-grounded.y, " landing_error=", absf(player.global_position.y-grounded.y))
    # Old furniture IDs remain valid after moving benches to the dining table.
    # An old resting position across a new partition must wake safely in place.
    for record: Array in [["Bench", Vector3(4.67, 0.5, 2.52)], ["BenchSecond", Vector3(-3.22, 0.5, 3.57)]]:
        var bench := home.get_node("InteriorFurniture/" + String(record[0])) as HouseholdFurniture
        player.global_position = home.to_global(record[1])
        player.velocity = Vector3.ZERO
        GameState.set_world_value("player:rest_furniture", bench.furniture_id)
        await _frames(45)
        assert(not visual.top_level and player.is_on_floor() and String(GameState.get_world_value("player:rest_furniture", "")).is_empty(), "Legacy bench save failed to wake safely after the room-layout change")
    print("REST_PHYSICS_OK cases=", checked, " legacy_bench_positions=2 native_jump=true disk_rest_and_wake=true physical_ascent_and_landing=true")
    get_tree().quit(0)
