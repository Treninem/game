extends Node3D

const MIN_DISTANCE := 2.0
const MAX_DISTANCE := 9.0
const PROBE_RADIUS := 0.22
const WALL_MARGIN := 0.08

@onready var camera: Camera3D = $Camera3D
@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
var desired_distance := 5.5
var current_distance := 5.5
var probe := SphereShape3D.new()
var camera_height := 0.55

func _ready() -> void:
    process_physics_priority = 100
    probe.radius = PROBE_RADIUS
    camera_height = camera.position.y
    current_distance = camera.position.z
    SettingsManager.settings_changed.connect(_apply_settings)
    _apply_settings()

func _apply_settings() -> void:
    desired_distance = clampf(float(SettingsManager.get_value("gameplay", "camera_distance")), MIN_DISTANCE, MAX_DISTANCE)

func _input(event: InputEvent) -> void:
    if get_tree().paused or DialogueManager.is_open or not SettingsManager.is_gameplay_mouse_captured():
        return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            var direction := -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
            SettingsManager.set_camera_distance(desired_distance + direction * 0.5)
            get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
    if player == null:
        return
    var origin := to_global(Vector3(0, camera_height, 0))
    var backward := global_basis.z.normalized()
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = probe
    query.transform = Transform3D(Basis.IDENTITY, origin)
    query.motion = backward * desired_distance
    query.collision_mask = 1
    query.exclude = [player.get_rid()]
    var space := get_world_3d().direct_space_state
    var fractions := space.cast_motion(query)
    var allowed := maxf(0.0, desired_distance * fractions[0] - WALL_MARGIN) if fractions[0] < 1.0 else desired_distance
    # Casts ignore shapes already overlapping their origin, so also test the
    # starting volume (door frames and very tight rooms).
    query.motion = Vector3.ZERO
    if not space.intersect_shape(query, 1).is_empty():
        allowed = 0.0
    # Pull in immediately; easing through a wall would still expose its back.
    if allowed < current_distance:
        current_distance = allowed
    else:
        current_distance = lerpf(current_distance, allowed, 1.0 - exp(-7.0 * delta))
    camera.position = Vector3(0, camera_height, current_distance)
    var ray := camera.get_node("InteractionRay") as RayCast3D
    ray.target_position = Vector3(0, 0, -(current_distance + 3.0))
