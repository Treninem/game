extends CharacterBody3D

@export var walk_speed := 5.0
@export var run_speed := 8.0
@export var acceleration := 18.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.0025
@export var gravity := 18.0

@onready var pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-60.0), deg_to_rad(45.0))
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_ESCAPE:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
            KEY_SPACE:
                if is_on_floor():
                    velocity.y = jump_velocity
            KEY_E:
                _try_interact()
            KEY_C:
                GameState.try_craft_building_kit()
            KEY_B:
                _try_build_house()
            KEY_F5:
                if SaveManager.save_game(self):
                    GameState.notify("Игра сохранена.")
            KEY_F9:
                if SaveManager.load_game(self):
                    get_tree().call_group("world_root", "spawn_house_from_state")
                    GameState.notify("Сохранение загружено.")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_vec := Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_A):
        input_vec.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D):
        input_vec.x += 1.0
    if Input.is_physical_key_pressed(KEY_W):
        input_vec.y -= 1.0
    if Input.is_physical_key_pressed(KEY_S):
        input_vec.y += 1.0
    input_vec = input_vec.normalized()

    var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
    var target_speed := run_speed if Input.is_physical_key_pressed(KEY_SHIFT) else walk_speed
    var target := direction * target_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    move_and_slide()

func _try_interact() -> void:
    if not interaction_ray.is_colliding():
        GameState.notify("Рядом нет объекта для взаимодействия.")
        return
    var collider = interaction_ray.get_collider()
    if collider != null and collider.has_method("interact"):
        collider.interact(self)
    else:
        GameState.notify("С этим объектом пока нельзя взаимодействовать.")

func _try_build_house() -> void:
    var forward := -global_transform.basis.z
    var build_position := global_position + Vector3(forward.x, 0.0, forward.z).normalized() * 5.0
    build_position.y = 0.0
    if GameState.try_mark_house_built(build_position):
        get_tree().call_group("world_root", "spawn_house_from_state")
