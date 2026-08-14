extends Node

enum TrackMode {
    HUMAN,
    PAW,
    HOOF,
    TIRE
}

@export var mode: TrackMode = TrackMode.PAW
@export var spacing: float = 1.25
@export var mark_lifetime: float = 36.0
@export var mark_size: Vector2 = Vector2(0.24, 0.30)
@export var only_deformable_surfaces: bool = true

var _last_position := Vector3.ZERO
var _distance_accum := 0.0
var _ready_for_tracks := false

func _ready() -> void:
    var actor := get_parent() as Node3D
    if actor != null:
        _last_position = actor.global_position
        _ready_for_tracks = true

func _physics_process(_delta: float) -> void:
    var actor := get_parent() as Node3D
    if actor == null or not is_instance_valid(actor):
        return
    if not _ready_for_tracks:
        _last_position = actor.global_position
        _ready_for_tracks = true
        return

    if actor is CharacterBody3D and not (actor as CharacterBody3D).is_on_floor():
        _last_position = actor.global_position
        return

    var moved := actor.global_position - _last_position
    _last_position = actor.global_position
    moved.y = 0.0
    var distance := moved.length()
    if distance < 0.002:
        return

    _distance_accum += distance
    if _distance_accum < maxf(spacing, 0.35):
        return
    _distance_accum = 0.0

    var forward := moved.normalized()
    var surface := WorldVFX.surface_at(actor.global_position)
    if only_deformable_surfaces and not _surface_accepts_tracks(surface):
        return

    _spawn_track(actor.global_position, forward, surface)

func _surface_accepts_tracks(surface: String) -> bool:
    if surface in ["snow", "mud", "sand"]:
        return true
    return surface == "dirt" and EnvironmentState.wetness > 0.30

func _spawn_track(position: Vector3, forward: Vector3, surface: String) -> void:
    var color := _surface_track_color(surface)
    var lifetime := _surface_lifetime(surface)
    var size := mark_size

    match mode:
        TrackMode.HUMAN:
            EnvironmentMarks.spawn_mark(position, Vector3.UP, forward, size, 0, color, lifetime)
        TrackMode.PAW:
            EnvironmentMarks.spawn_mark(position, Vector3.UP, forward, size, 5, color, lifetime)
        TrackMode.HOOF:
            EnvironmentMarks.spawn_mark(position, Vector3.UP, forward, size, 6, color, lifetime)
        TrackMode.TIRE:
            EnvironmentMarks.spawn_mark(position, Vector3.UP, forward, size, 1, color, lifetime)

func _surface_track_color(surface: String) -> Color:
    match surface:
        "snow": return Color(0.40, 0.52, 0.60, 0.34)
        "sand": return Color(0.32, 0.23, 0.14, 0.42)
        "mud": return Color(0.12, 0.075, 0.04, 0.62)
        _: return Color(0.11, 0.085, 0.055, 0.52)

func _surface_lifetime(surface: String) -> float:
    var lifetime := maxf(mark_lifetime, 2.0)
    if surface == "snow":
        lifetime *= 1.25
    elif surface == "mud":
        lifetime *= 1.10
    elif surface == "sand":
        lifetime *= 0.75
    return lifetime
