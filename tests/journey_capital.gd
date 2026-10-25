extends Node

# Long opt-in traversal QA, separate from bounded CI smoke checks.
# Run with isolated APPDATA/LOCALAPPDATA and --headless --fixed-fps 60.
# Normal movement, gravity and stamina; the driver never writes player position.
func _ready() -> void:
    var monitor := Node.new()
    monitor.set_script(load("res://tests/journey_capital_driver.gd"))
    get_tree().root.add_child.call_deferred(monitor)
    get_tree().change_scene_to_file.call_deferred("res://scenes/stage1.tscn")
