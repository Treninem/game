extends Node

signal exposure_changed(exposure: float)

@export var probe_interval: float = 0.20
@export var probe_height: float = 18.0
@export var head_height: float = 1.55
@export var smoothing_speed: float = 5.5

var exposure: float = 1.0
var _target_exposure: float = 1.0
var _elapsed: float = 0.0

func _ready() -> void:
    set_process(true)
    EnvironmentState.set_local_exposure(exposure)

func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed >= maxf(probe_interval, 0.05):
        _elapsed = 0.0
        _sample_exposure()

    var previous := exposure
    exposure = move_toward(exposure, _target_exposure, delta * maxf(smoothing_speed, 0.1))
    if absf(exposure - previous) > 0.002:
        EnvironmentState.set_local_exposure(exposure)
        exposure_changed.emit(exposure)

func _sample_exposure() -> void:
    if EnvironmentState.is_underwater:
        _target_exposure = 0.0
        return

    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player == null or not is_instance_valid(player):
        _target_exposure = 1.0
        return

    var world := player.get_world_3d()
    if world == null:
        _target_exposure = 1.0
        return

    var origin := player.global_position + Vector3.UP * head_height
    var target := origin + Vector3.UP * maxf(probe_height, 2.0)
    var query := PhysicsRayQueryParameters3D.create(origin, target)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    if player is CollisionObject3D:
        query.exclude = [(player as CollisionObject3D).get_rid()]

    var hit := world.direct_space_state.intersect_ray(query)
    _target_exposure = 0.0 if not hit.is_empty() else 1.0

func is_sheltered() -> bool:
    return exposure < 0.35

func precipitation_factor() -> float:
    return clampf(exposure, 0.0, 1.0)
