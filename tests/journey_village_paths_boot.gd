extends Node
func _ready() -> void:
    var monitor := Node.new()
    monitor.set_script(load("res://tests/journey_village_paths.gd"))
    get_tree().root.add_child.call_deferred(monitor)
    get_tree().change_scene_to_file.call_deferred("res://scenes/stage1.tscn")
