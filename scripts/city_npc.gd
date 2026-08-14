extends CharacterBody3D

const HUMANOID := preload("res://scripts/humanoid_visual.gd")

@export var display_name := "Житель"
@export var role := "citizen"
@export var work_position := Vector3.ZERO
@export var evening_position := Vector3.ZERO
@export var home_position := Vector3.ZERO
@export var move_speed := 1.65
@export var palette_index := 0

var visual: Node3D
var current_target := Vector3.ZERO

func _ready() -> void:
    add_to_group("city_npc")
    _build_collision()
    _build_visual()
    if work_position == Vector3.ZERO:
        work_position = global_position
    if evening_position == Vector3.ZERO:
        evening_position = global_position
    if home_position == Vector3.ZERO:
        home_position = global_position
    current_target = global_position

func _physics_process(_delta: float) -> void:
    if DialogueManager.is_open:
        velocity = Vector3.ZERO
        return
    current_target = _scheduled_target()
    var flat_delta := current_target - global_position
    flat_delta.y = 0.0
    if flat_delta.length() < 0.35:
        velocity = Vector3.ZERO
        return
    var direction := flat_delta.normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.12)
    move_and_slide()

func interact(_player: Node) -> void:
    velocity = Vector3.ZERO
    match role:
        "blacksmith":
            _blacksmith_dialogue()
        "merchant":
            DialogueManager.open_dialogue(display_name, "Рынок только открывается, но товары уже идут через южные ворота. Скоро здесь появятся нормальные торговые прилавки и заказы.", [{"text": "Понятно.", "action": "close"}])
        "guard":
            DialogueManager.open_dialogue(display_name, "Южные ворота охраняют дорогу к окраинам. После заката патрули усиливаются. За стенами лучше держать оружие под рукой.", [{"text": "Спасибо за предупреждение.", "action": "close"}])
        "innkeeper":
            DialogueManager.open_dialogue(display_name, "Таверна ещё обустраивается. Позже здесь можно будет снять комнату, поесть, услышать слухи и взять местные поручения.", [{"text": "Зайду позже.", "action": "close"}])
        "artisan":
            DialogueManager.open_dialogue(display_name, "В этом квартале нужны руки: плотники, каменщики, кожевники. Город растёт, и работы хватит всем.", [{"text": "Буду иметь в виду.", "action": "close"}])
        _:
            DialogueManager.open_dialogue(display_name, "Южный квартал меняется каждый день. Рынок расширяется, стража чинит стену, а за воротами всё чаще замечают тварей.", [{"text": "До встречи.", "action": "close"}])

func _blacksmith_dialogue() -> void:
    match GameState.city_quest_stage:
        0:
            DialogueManager.open_dialogue(display_name, "Я Радан, кузнец Южного квартала. На воротах лопнули две крепёжные скобы. Принеси 6 камня и 4 древесины — подготовлю ремонтный комплект и заплачу.", [
                {"text": "Берусь за работу.", "action": "start_city_quest"},
                {"text": "Позже.", "action": "close"}
            ])
        1:
            DialogueManager.open_dialogue(display_name, "Принёс материалы для ремонта ворот? Мне нужно 6 камня и 4 древесины.", [
                {"text": "Передать материалы.", "action": "complete_city_quest"},
                {"text": "Ещё собираю.", "action": "close"}
            ])
        _:
            DialogueManager.open_dialogue(display_name, "Хорошая работа с воротами. Когда кузница заработает полностью, смогу улучшать оружие и инструменты.", [{"text": "Зайду ещё.", "action": "close"}])

func _scheduled_target() -> Vector3:
    var hour := int(GameState.world_minutes / 60.0) % 24
    if hour >= 7 and hour < 17:
        return work_position
    if hour >= 17 and hour < 22:
        return evening_position
    return home_position

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    collision.position = Vector3(0, 0.9, 0)
    var shape := CapsuleShape3D.new()
    shape.radius = 0.34
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)

func _build_visual() -> void:
    visual = HUMANOID.new()
    visual.name = "Visual"
    var palettes := [
        [Color(0.18, 0.25, 0.36), Color(0.28, 0.38, 0.46), Color(0.30, 0.76, 0.92)],
        [Color(0.34, 0.16, 0.12), Color(0.46, 0.30, 0.18), Color(0.88, 0.58, 0.24)],
        [Color(0.16, 0.28, 0.20), Color(0.26, 0.40, 0.29), Color(0.55, 0.78, 0.48)],
        [Color(0.27, 0.20, 0.34), Color(0.38, 0.29, 0.48), Color(0.72, 0.50, 0.91)],
        [Color(0.20, 0.22, 0.24), Color(0.32, 0.34, 0.36), Color(0.62, 0.68, 0.74)]
    ]
    var palette: Array = palettes[palette_index % palettes.size()]
    visual.primary_color = palette[0]
    visual.secondary_color = palette[1]
    visual.accent_color = palette[2]
    visual.skin_color = Color(0.68 + 0.04 * (palette_index % 3), 0.50, 0.38)
    visual.hair_color = Color(0.08 + 0.04 * (palette_index % 2), 0.055, 0.04)
    visual.has_apron = role == "blacksmith" or role == "artisan"
    visual.has_guard_armor = role == "guard"
    visual.has_hood = role == "merchant"
    add_child(visual)
