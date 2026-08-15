class_name SettlementNPC
extends CharacterBody3D

const HUMANOID := preload("res://scripts/humanoid_visual.gd")

@export var display_name := "Житель"
@export var role := "resident"
@export var move_speed := 1.45
@export var palette_index := 0

var route_points_local: Array[Vector3] = []
var route_index := 0
var pause_elapsed := 0.0
var visual: Node3D

func configure(name_value: String, role_value: String, palette_value: int, route_points: Array) -> void:
    display_name = name_value
    role = role_value
    palette_index = palette_value
    route_points_local.clear()
    for point in route_points:
        if point is Vector3:
            route_points_local.append(point)

func _ready() -> void:
    add_to_group("settlement_npc")
    collision_layer = 1
    collision_mask = 1
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(48.0)
    up_direction = Vector3.UP
    _build_collision()
    _build_visual()

func _physics_process(delta: float) -> void:
    if DialogueManager.is_open:
        velocity = Vector3.ZERO
        return

    if not is_on_floor():
        velocity.y -= 18.0 * delta
    elif velocity.y < 0.0:
        velocity.y = -0.15

    if route_points_local.size() < 2:
        velocity.x = move_toward(velocity.x, 0.0, delta * 7.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 7.0)
        move_and_slide()
        return

    if pause_elapsed > 0.0:
        pause_elapsed = maxf(0.0, pause_elapsed - delta)
        velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
        move_and_slide()
        return

    var parent_3d := get_parent() as Node3D
    if parent_3d == null:
        return
    var target := parent_3d.to_global(route_points_local[route_index])
    var flat_delta := target - global_position
    flat_delta.y = 0.0
    if flat_delta.length() <= 0.75:
        route_index = (route_index + 1) % route_points_local.size()
        pause_elapsed = 0.7 + float((palette_index + route_index) % 4) * 0.35
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    var direction := flat_delta.normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed, delta * 5.5)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, delta * 5.5)
    rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 7.0))
    move_and_slide()

func interact(_player: Node) -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    match role:
        "watch":
            DialogueManager.open_dialogue(display_name, "Ворота и дорога перед ними должны оставаться свободными. Проходите, но не стойте в проезде.", [{"text":"Понял.", "action":"close"}])
        "trader":
            DialogueManager.open_dialogue(display_name, "Товары складывают у площади. Пока можно осмотреться и поговорить с местными.", [{"text":"Хорошо.", "action":"close"}])
        "craftsman":
            DialogueManager.open_dialogue(display_name, "Здесь всё приходится чинить руками: дома, ограды, телеги и инструмент.", [{"text":"Ясно.", "action":"close"}])
        _:
            DialogueManager.open_dialogue(display_name, "Добрый день. Держитесь дороги — между домами проходы узкие.", [{"text":"До встречи.", "action":"close"}])

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    collision.position = Vector3(0.0, 0.9, 0.0)
    var shape := CapsuleShape3D.new()
    shape.radius = 0.34
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)

func _build_visual() -> void:
    visual = HUMANOID.new()
    visual.name = "Visual"
    var palettes := [
        [Color(0.24,0.18,0.13), Color(0.42,0.31,0.20), Color(0.67,0.49,0.25)],
        [Color(0.15,0.25,0.18), Color(0.28,0.39,0.29), Color(0.55,0.66,0.42)],
        [Color(0.24,0.25,0.27), Color(0.35,0.37,0.40), Color(0.62,0.66,0.70)],
        [Color(0.27,0.18,0.28), Color(0.42,0.30,0.42), Color(0.66,0.50,0.65)],
        [Color(0.18,0.22,0.30), Color(0.29,0.34,0.43), Color(0.55,0.66,0.80)]
    ]
    var palette: Array = palettes[palette_index % palettes.size()]
    visual.primary_color = palette[0]
    visual.secondary_color = palette[1]
    visual.accent_color = palette[2]
    visual.skin_color = Color(0.66 + 0.035 * float(palette_index % 3), 0.49 + 0.02 * float(palette_index % 2), 0.37)
    visual.hair_color = Color(0.07 + 0.03 * float(palette_index % 3), 0.05, 0.035)
    visual.has_guard_armor = role == "watch"
    visual.has_hood = role == "trader"
    visual.has_apron = role == "craftsman"
    add_child(visual)
