extends Node

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const WATCHDOG_SECONDS := 6.0

var stage := "boot"
var watchdog: Timer

func _ready() -> void:
    watchdog = Timer.new()
    watchdog.one_shot = true
    watchdog.wait_time = WATCHDOG_SECONDS
    watchdog.timeout.connect(_on_timeout)
    add_child(watchdog)
    watchdog.start()
    call_deferred("_probe")

func _mark(value: String) -> void:
    stage = value
    print("WORLD_SETTLEMENTS_FACTORY_STAGE ", value)

func _probe() -> void:
    _mark("metadata")
    print("WORLD_SETTLEMENTS_FACTORY_META base=", SETTLEMENTS_SCRIPT.get_instance_base_type(), " can_instantiate=", SETTLEMENTS_SCRIPT.can_instantiate())

    _mark("before script.new")
    var settlements = SETTLEMENTS_SCRIPT.new()
    _mark("after script.new")
    if settlements == null:
        _fail(81, "script.new returned null")
        return
    if not settlements is Node3D:
        _fail(82, "script.new returned non-Node3D")
        return

    _mark("before name")
    settlements.name = "FactoryProbeSettlements"
    _mark("after name")

    _mark("before add_child")
    add_child(settlements)
    _mark("after add_child")

    await get_tree().process_frame
    _mark("after process frame")
    if not settlements.has_method("settlement_specs"):
        _fail(83, "constructed settlement streamer has no settlement_specs")
        return

    watchdog.stop()
    print("WORLD_SETTLEMENTS_FACTORY_OK")
    get_tree().quit(0)

func _on_timeout() -> void:
    _fail(89, "construction path aborted or stalled at stage '%s'" % stage)

func _fail(code: int, message: String) -> void:
    if watchdog != null:
        watchdog.stop()
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Settlement factory probe::%s" % clean)
    push_error(message)
    get_tree().quit(code)
