extends "res://tests/capture_streamed_home_door.gd"

func _initialize() -> void:
    # Observe the unchanged continuous-render scenario. Retain its original
    # household assertions, normal clock, graphics, captures and deadlines.
    call_deferred("_install_observer")
    super._initialize()

func _install_observer() -> void:
    var observer: Node = load("res://tests/household_render_observer.gd").new()
    observer.name = "PassiveHouseholdRenderObserver"
    root.add_child(observer)
