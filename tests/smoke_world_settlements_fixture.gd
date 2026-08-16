extends Node

const FIXTURE := preload("res://tests/fixtures/world_settlements_fixture.tscn")
const WATCHDOG_SECONDS := 8.0

var watchdog: Timer
var stage := "boot"

func _ready() -> void:
    watchdog = Timer.new()
    watchdog.one_shot = true
    watchdog.wait_time = WATCHDOG_SECONDS
    watchdog.timeout.connect(_on_timeout)
    add_child(watchdog)
    watchdog.start()
    call_deferred("_run")

func _mark(value: String) -> void:
    stage = value
    print("WORLD_SETTLEMENTS_FIXTURE_STAGE ", value)

func _run() -> void:
    _mark("before fixture instantiate")
    var settlements := FIXTURE.instantiate() as Node3D
    _mark("after fixture instantiate")
    if settlements == null:
        _fail(91, "fixture instantiate returned null")
        return
    add_child(settlements)
    _mark("after add_child")
    await get_tree().process_frame
    _mark("after process frame")
    if not settlements.has_method("settlement_specs"):
        _fail(92, "scene-based settlement streamer has no settlement_specs")
        return
    var specs: Array = settlements.call("settlement_specs")
    if specs.size() != 3:
        _fail(93, "scene-based settlement streamer returned %d specs instead of 3" % specs.size())
        return
    watchdog.stop()
    print("WORLD_SETTLEMENTS_FIXTURE_OK")
    get_tree().quit(0)

func _on_timeout() -> void:
    _fail(99, "scene-based settlement construction stalled at '%s'" % stage)

func _fail(code: int, message: String) -> void:
    if watchdog != null:
        watchdog.stop()
    print("::error title=Settlement fixture smoke::%s" % message)
    push_error(message)
    get_tree().quit(code)
