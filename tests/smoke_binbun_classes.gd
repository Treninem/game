extends Node

const PACKS := ["binbun_godot4_core", "binbun_godot4_combat_magic", "binbun_godot4_electric", "binbun_godot4_beam"]
var scripts: Array[String] = []
var scenes: Array[String] = []
var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _collect(folder: String) -> void:
    for file in DirAccess.get_files_at(folder):
        var path := folder.path_join(file)
        if file.ends_with(".gd"):
            scripts.append(path)
        elif file.ends_with(".tscn"):
            scenes.append(path)
    for child in DirAccess.get_directories_at(folder):
        if not child.begins_with("."):
            _collect(folder.path_join(child))

func _run() -> void:
    for pack in PACKS:
        _collect("res://assets/vfx/third_party/" + pack)
    var names := {}
    for path in scripts:
        for line in FileAccess.get_file_as_string(path).split("\n"):
            if not line.begins_with("class_name "):
                continue
            var label := line.trim_prefix("class_name ").strip_edges()
            if names.has(label):
                failures.append("Duplicate global class %s: %s and %s" % [label, names[label], path])
            names[label] = path
    if failures.is_empty():
        for path in scripts:
            var script := load(path) as GDScript
            if script == null or not script.can_instantiate():
                failures.append("Cannot compile library script: " + path)
        for path in scenes:
            var packed := load(path) as PackedScene
            if packed == null or not packed.can_instantiate():
                failures.append("Cannot load library scene: " + path)
                continue
            var instance := packed.instantiate()
            if instance == null:
                failures.append("Cannot instantiate library scene: " + path)
            else:
                instance.free()
    if scripts.size() < 20 or scenes.size() < 20:
        failures.append("Expected physical library coverage is missing")
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("BINBUN_CLASSES_OK unique=", names.size(), " scripts=", scripts.size(), " scenes=", scenes.size(), " instantiated=true")
    get_tree().quit(0 if failures.is_empty() else 1)
