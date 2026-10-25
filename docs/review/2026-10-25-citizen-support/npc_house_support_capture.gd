extends "res://tests/capture_streamed_home_door.gd"

func _initialize() -> void:
    call_deferred("_install_npc_observer")
    super._initialize()

func _install_npc_observer() -> void:
    var observer: Node = load("D:/Desktop/GitHub/game/build/npc_house_support_observer.gd").new()
    root.add_child(observer)
