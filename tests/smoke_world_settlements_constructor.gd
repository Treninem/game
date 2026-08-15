extends Node

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const WATCHDOG_SECONDS := 8.0

var current_stage := "boot"
var watchdog: Timer
var failed := false

func _ready() -> void:
    watchdog = Timer.new()
    watchdog.one_shot = true
    watchdog.wait_time = WATCHDOG_SECONDS
    watchdog.timeout.connect(_on_watchdog_timeout)
    add_child(watchdog)
    watchdog.start()
    call_deferred("_run_probe")

func _stage(value: String) -> void:
    current_stage = value
    print("WORLD_SETTLEMENTS_CTOR_STAGE ", value)

func _run_probe() -> void:
    _stage("script metadata")
    print("WORLD_SETTLEMENTS_CTOR base_type=", SETTLEMENTS_SCRIPT.get_instance_base_type(), " can_instantiate=", SETTLEMENTS_SCRIPT.can_instantiate())
    if not SETTLEMENTS_SCRIPT.can_instantiate():
        _fail(71, "world_settlements.gd reports can_instantiate=false")
        return

    _stage("bare Node3D")
    var bare := Node3D.new()
    if bare == null:
        _fail(72, "Node3D.new() unexpectedly failed")
        return

    _stage("set_script")
    bare.set_script(SETTLEMENTS_SCRIPT)
    _stage("set_script returned")
    if bare.get_script() != SETTLEMENTS_SCRIPT:
        bare.free()
        _fail(73, "Node3D.set_script() did not attach world_settlements.gd")
        return
    if not bare.has_method("settlement_specs"):
        bare.free()
        _fail(74, "attached settlement script has no settlement_specs method")
        return

    _stage("set_script probe passed")
    bare.free()

    _stage("script.new")
    var direct = SETTLEMENTS_SCRIPT.new()
    _stage("script.new returned")
    if direct == null or not direct is Node3D:
        _fail(75, "GDScript.new() did not return a Node3D")
        return
    direct.free()

    watchdog.stop()
    _stage("complete")
    print("WORLD_SETTLEMENTS_CONSTRUCTOR_SMOKE_OK")
    get_tree().quit(0)

func _on_watchdog_timeout() -> void:
    _fail(79, "constructor probe stalled or coroutine aborted during stage '%s'" % current_stage)

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    if watchdog != null:
        watchdog.stop()
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=World settlements constructor::%s" % clean)
    push_error(message)
    get_tree().quit(code)
