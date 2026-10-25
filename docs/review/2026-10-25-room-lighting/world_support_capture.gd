extends "res://tests/visual_bow_world.gd"

func _initialize() -> void:
    call_deferred("_install_observer")
    super._initialize()

func _install_observer() -> void:
    var observer:Node=load("D:/Desktop/GitHub/game/build/world_support_observer.gd").new()
    observer.name="ActualSoleObserver"
    root.add_child(observer)

func _capture(label: String) -> void:
    root.get_node("ActualSoleObserver").want_capture=true
    await super._capture(label)
    root.get_node("ActualSoleObserver")._flush()
