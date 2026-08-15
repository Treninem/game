class_name DoorInteractable
extends AnimatableBody3D

signal door_state_changed(opened: bool)

@export var open_angle_degrees := 96.0
@export var open_speed_degrees := 165.0
@export var starts_open := false
@export var locked := false
@export var interaction_label := "Дверь"

var opened := false
var closed_rotation_y := 0.0
var target_rotation_y := 0.0
var configured := false

func configure(label: String, open_direction: float = -1.0, start_open: bool = false) -> void:
    interaction_label = label
    open_angle_degrees = absf(open_angle_degrees) * (-1.0 if open_direction < 0.0 else 1.0)
    starts_open = start_open
    configured = true

func _ready() -> void:
    # This door is rotated directly from script in physics processing. Keeping
    # sync_to_physics enabled can defer the PhysicsServer transform and leave
    # the previous closed collision in place for queries after an immediate
    # state change. Direct scripted transforms already update AnimatableBody3D
    # collision, so disable the extra AnimationPlayer-oriented synchronization.
    sync_to_physics = false
    collision_layer = 1
    collision_mask = 1
    closed_rotation_y = rotation.y
    opened = starts_open
    target_rotation_y = closed_rotation_y + deg_to_rad(open_angle_degrees if opened else 0.0)
    if opened:
        rotation.y = target_rotation_y

func _physics_process(delta: float) -> void:
    var speed := deg_to_rad(absf(open_speed_degrees))
    rotation.y = move_toward(rotation.y, target_rotation_y, speed * delta)

func interact(_actor: Node = null) -> void:
    if locked:
        GameState.notify("%s заперта." % interaction_label)
        return
    set_open(not opened)
    GameState.notify("%s %s." % [interaction_label, "открыта" if opened else "закрыта"])

func set_open(value: bool, immediate: bool = false) -> void:
    if locked and value:
        return
    if opened == value and not immediate:
        return
    opened = value
    target_rotation_y = closed_rotation_y + deg_to_rad(open_angle_degrees if opened else 0.0)
    if immediate:
        rotation.y = target_rotation_y
    door_state_changed.emit(opened)

func set_locked(value: bool) -> void:
    locked = value
    if locked and opened:
        set_open(false)

func is_open() -> bool:
    return opened
