extends CharacterBody3D

@export var walk_speed := 5.0
@export var run_speed := 8.0
@export var acceleration := 18.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.0025
@export var gravity := 18.0

@onready var pivot: Node3D = $CameraPivot

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-65.0), deg_to_rad(55.0))
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
    var target_speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
    var target := direction * target_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    move_and_slide()
