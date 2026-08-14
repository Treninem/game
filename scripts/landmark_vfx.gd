extends Node

# Attaches reusable physical VFX emitters to authored/generated landmark nodes
# without forcing landmark builders to duplicate particle logic.

var scan_elapsed := 0.0
var hooked: Dictionary = {}

func _ready() -> void:
    set_process(true)
    call_deferred("_scan_landmarks")

func _process(delta: float) -> void:
    scan_elapsed += delta
    if scan_elapsed < 2.0:
        return
    scan_elapsed = 0.0
    _scan_landmarks()

func _scan_landmarks() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return

    _ensure_hook(scene, "ForgeChimney", "smoke", Vector3(0.0, 3.9, 0.0), 0.85, 0.72, 42.0)
    _ensure_hook(scene, "ForgeAnvil", "sparks", Vector3(0.0, 0.45, 0.0), 0.55, 2.8, 24.0)
    _ensure_hook(scene, "FountainWater", "splash", Vector3(0.0, 0.18, 0.0), 0.42, 0.72, 28.0)

func _ensure_hook(
        scene: Node,
        node_name: String,
        kind: String,
        local_offset: Vector3,
        strength: float,
        interval: float,
        distance: float
    ) -> void:
    if hooked.has(node_name):
        var existing = hooked[node_name]
        if is_instance_valid(existing):
            return
        hooked.erase(node_name)

    var target := scene.find_child(node_name, true, false) as Node3D
    if target == null:
        return

    var emitter := WorldEffectEmitter.new()
    emitter.name = node_name + "VFX"
    emitter.effect_kind = kind
    emitter.strength = strength
    emitter.interval_seconds = interval
    emitter.activation_distance = distance
    emitter.randomize_interval = kind != "splash"
    emitter.start_with_effect = false
    target.add_child(emitter)
    emitter.position = local_offset
    hooked[node_name] = emitter
