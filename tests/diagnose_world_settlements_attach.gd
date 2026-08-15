extends Node3D

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const WATCHDOG_SECONDS := 20.0

var current_stage := "boot"
var finished := false
var watchdog: Timer

func _ready() -> void:
    watchdog = Timer.new()
    watchdog.name = "SettlementAttachDiagnosticWatchdog"
    watchdog.one_shot = true
    watchdog.wait_time = WATCHDOG_SECONDS
    watchdog.timeout.connect(_on_watchdog_timeout)
    add_child(watchdog)
    watchdog.start()
    call_deferred("_run_diagnostic")

func _stage(value: String) -> void:
    current_stage = value
    print("WORLD_SETTLEMENTS_DIAG_STAGE ", value)

func _on_watchdog_timeout() -> void:
    _stop(90, "diagnostic stalled or coroutine aborted during stage '%s'" % current_stage)

func _stop(code: int, message: String) -> void:
    if finished:
        return
    finished = true
    if watchdog != null:
        watchdog.stop()
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=World settlements attach diagnostic::%s" % clean)
    push_error("World settlements attach diagnostic: %s" % message)
    get_tree().quit(code)

func _run_diagnostic() -> void:
    _stage("instantiate settlement streamer")
    var raw_instance := SETTLEMENTS_SCRIPT.new()
    if raw_instance == null:
        _stop(81, "SETTLEMENTS_SCRIPT.new() returned null")
        return

    _stage("cast settlement streamer")
    var settlements := raw_instance as WorldSettlements
    if settlements == null:
        raw_instance.free()
        _stop(82, "new instance could not be cast to WorldSettlements")
        return

    _stage("name settlement streamer")
    settlements.name = "DiagnosticSettlements"

    _stage("attach settlement streamer")
    add_child(settlements)

    _stage("settlement streamer attached")
    if settlements.get_parent() != self:
        _stop(83, "settlement streamer parent is incorrect after add_child")
        return

    await get_tree().process_frame
    _stage("settlement streamer survived one frame")

    # This diagnostic must never turn the release gate green. Once the failing
    # boundary is known, restore the full smoke scene and fix the root cause.
    _stop(91, "diagnostic reached one-frame survival; restore full smoke before release")
