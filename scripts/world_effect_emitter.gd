extends Node3D
class_name WorldEffectEmitter

# Reusable scene component for non-magic continuous/intermittent effects:
# campfires, fireplaces, forges, chimneys, vents, steam leaks, grinding sparks,
# dust leaks, waterfalls and other authored world props.

@export_enum("fire", "smoke", "steam", "dust", "sparks", "splash", "debris") var effect_kind := "smoke"
@export_range(0.1, 3.0, 0.05) var strength := 1.0
@export_range(0.04, 10.0, 0.01) var interval_seconds := 0.55
@export_range(2.0, 120.0, 1.0) var activation_distance := 34.0
@export var enabled := true
@export var randomize_interval := true
@export var start_with_effect := false

var elapsed := 0.0
var next_interval := 0.55

func _ready() -> void:
    next_interval = _resolve_interval()
    set_process(true)
    if start_with_effect and enabled:
        call_deferred("emit_once")

func _process(delta: float) -> void:
    if not enabled or get_tree().paused:
        return
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player == null:
        return
    if global_position.distance_squared_to(player.global_position) > activation_distance * activation_distance:
        elapsed = minf(elapsed, next_interval)
        return

    elapsed += delta
    if elapsed < next_interval:
        return
    elapsed = 0.0
    next_interval = _resolve_interval()
    emit_once()

func emit_once(multiplier: float = 1.0) -> void:
    if not enabled:
        return
    WorldVFX.spawn_environment_effect(effect_kind, global_position, clampf(strength * multiplier, 0.1, 4.0))

func burst(multiplier: float = 1.8) -> void:
    WorldVFX.spawn_environment_effect(effect_kind, global_position, clampf(strength * multiplier, 0.2, 5.0))
    if effect_kind in ["sparks", "debris", "splash"]:
        ScreenVFX.shake(0.006 * clampf(multiplier, 0.5, 3.0), 0.06)

func set_effect_enabled(value: bool) -> void:
    enabled = value
    elapsed = 0.0

func configure(kind: String, effect_strength: float = 1.0, interval: float = 0.55) -> void:
    var supported := ["fire", "smoke", "steam", "dust", "sparks", "splash", "debris"]
    effect_kind = kind.to_lower() if kind.to_lower() in supported else "smoke"
    strength = clampf(effect_strength, 0.1, 3.0)
    interval_seconds = clampf(interval, 0.04, 10.0)
    next_interval = _resolve_interval()

func _resolve_interval() -> float:
    var base := maxf(interval_seconds, 0.04)
    if not randomize_interval:
        return base
    return base * randf_range(0.72, 1.28)
