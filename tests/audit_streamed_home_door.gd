extends SceneTree

var errors: Array[String] = []
var fixture: Node3D
var square: Node3D
var home: Node3D
var trader: CharacterBody3D
var artisan: CharacterBody3D
var stream_record: Dictionary = {}

func _initialize() -> void:
    create_timer(210).timeout.connect(func():
        push_error("Streamed household doorway diagnostic watchdog expired")
        quit(1)
    )
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        await physics_frame

func _build_square() -> void:
    square = load("res://scripts/capital_square_life.gd").new()
    square.name = "CapitalSquareLife"
    fixture.add_child(square)
    home = square.get_node("SquareHome")
    trader = square.get_node("SquareTrader")
    artisan = square.get_node("SquareArtisan")

func _person(actor: CharacterBody3D) -> Dictionary:
    var capsule := (actor.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
    return {"position": actor.position, "home_local": home.to_local(actor.global_position),
        "activity": actor.activity, "phase": actor.routine_phase, "crossing": actor.home_crossing,
        "velocity": actor.velocity, "grounded": actor.is_on_floor(),
        "height_m": capsule.height, "radius_m": capsule.radius}

func _stream_during_crossing() -> void:
    var state := root.get_node("GameState")
    var before_trader := trader.position
    var before_artisan := artisan.position
    var saved: Dictionary = state.snapshot()
    var file := FileAccess.open("user://streamed-home-door-snapshot.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(saved))
    file.close()
    stream_record.before = {"trader": _person(trader), "artisan": _person(artisan)}
    square.free()
    var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://streamed-home-door-snapshot.json"))
    state.load_snapshot(disk)
    _build_square()
    stream_record.after = {"trader": _person(trader), "artisan": _person(artisan)}
    stream_record.trader_restore_error_m = trader.position.distance_to(before_trader)
    stream_record.artisan_restore_error_m = artisan.position.distance_to(before_artisan)
    if trader.position.distance_to(before_trader) > .02 or artisan.position.distance_to(before_artisan) > .02:
        errors.append("Disk restoration changed a resident position during physical doorway crossing")

func _run() -> void:
    var state := root.get_node("GameState")
    var mode := OS.get_environment("IMPULS_DOOR_HEIGHT_MODE")
    if mode == "tallest":
        state.set_world_value("appearance:capital:square:provisions", {"sex": "female", "height_cm": 200})
        state.set_world_value("appearance:capital:square:fletcher", {"sex": "male", "height_cm": 200})
    state.world_minutes = 9 * 60
    fixture = Node3D.new()
    var center: Vector2 = load("res://scripts/capital_data.gd").CENTER
    var elevation: float = root.get_node("WorldData").elevation_at(center)
    fixture.position = Vector3(center.x, elevation + .025, center.y)
    root.add_child(fixture)
    current_scene = fixture
    var ground := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(150, .2, 150)
    collision.shape = shape
    collision.position.y = -.1
    ground.add_child(collision)
    fixture.add_child(ground)
    _build_square()
    await _frames(60)
    var initial := {"trader": _person(trader), "artisan": _person(artisan)}
    if mode == "tallest" and (absf(float(initial.trader.height_m) - 2) > .001 or absf(float(initial.artisan.height_m) - 2) > .001):
        errors.append("Requested stature did not reach actual resident capsules")
    state.world_minutes = 22 * 60
    var night_frames := 0
    for frame in range(5400):
        await physics_frame
        night_frames = frame + 1
        if stream_record.is_empty() and (trader.home_crossing or artisan.home_crossing):
            _stream_during_crossing()
        if frame % 600 == 0:
            print("STREAM_HOME_NIGHT frame=", frame, " trader=", JSON.stringify(_person(trader)), " artisan=", JSON.stringify(_person(artisan)), " owner=", home.get_meta("door_user", 0))
        if trader.activity == "Спит дома" and artisan.activity == "Спит дома":
            break
    var night := {"trader": _person(trader), "artisan": _person(artisan), "frames": night_frames}
    if stream_record.is_empty():
        errors.append("Household never exercised an actual doorway crossing and disk restoration")
    for actor: CharacterBody3D in [trader, artisan]:
        var point := home.to_local(actor.global_position)
        if actor.activity != "Спит дома" or point.z > 4 or absf(point.x) > 5.5:
            errors.append("Streamed resident failed to enter and sleep: " + JSON.stringify(_person(actor)))
    state.world_minutes = 9 * 60
    var morning_frames := 0
    for frame in range(5400):
        await physics_frame
        morning_frames = frame + 1
        if frame % 600 == 0:
            print("STREAM_HOME_MORNING frame=", frame, " trader=", JSON.stringify(_person(trader)), " artisan=", JSON.stringify(_person(artisan)), " owner=", home.get_meta("door_user", 0))
        if trader.activity == "Торгует" and artisan.activity == "Ждёт материалы у верстака":
            break
    var morning := {"trader": _person(trader), "artisan": _person(artisan), "frames": morning_frames}
    if trader.activity != "Торгует" or artisan.activity != "Ждёт материалы у верстака":
        errors.append("Streamed residents failed to leave for their real workplaces")
    var file := FileAccess.open("user://streamed-home-door.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"mode": mode, "actual_capital_square_life": true,
        "controlled_isolated_household": true, "manual_play": false,
        "driver_position_assignments_after_setup": 0,
        "initial": initial, "disk_stream": stream_record, "night": night, "morning": morning,
        "errors": errors}, "  "))
    file.close()
    if not errors.is_empty():
        for message in errors: push_error(message)
        quit(1)
        return
    print("STREAMED_HOME_DOOR_OK mode=", mode)
    quit(0)
