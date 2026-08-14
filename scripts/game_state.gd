extends Node

signal inventory_changed
signal quest_changed
signal survival_changed
signal notification_requested(message: String)

const DEFAULT_INVENTORY := {
    "wood": 0,
    "stone": 0,
    "building_kit": 0,
    "starter_axe": 0
}

var inventory: Dictionary = DEFAULT_INVENTORY.duplicate(true)
var quest_stage: int = 0
var house_built: bool = false
var house_position: Vector3 = Vector3.ZERO
var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var world_minutes: float = 8.0 * 60.0

func reset_new_game() -> void:
    inventory = DEFAULT_INVENTORY.duplicate(true)
    quest_stage = 0
    house_built = false
    house_position = Vector3.ZERO
    health = 100.0
    hunger = 100.0
    thirst = 100.0
    world_minutes = 8.0 * 60.0
    _emit_all()

func add_item(item_id: String, amount: int = 1) -> void:
    inventory[item_id] = int(inventory.get(item_id, 0)) + max(amount, 0)
    inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
    var current := int(inventory.get(item_id, 0))
    if amount < 0 or current < amount:
        return false
    inventory[item_id] = current - amount
    inventory_changed.emit()
    return true

func has_items(requirements: Dictionary) -> bool:
    for item_id in requirements:
        if int(inventory.get(item_id, 0)) < int(requirements[item_id]):
            return false
    return true

func start_quest() -> void:
    if quest_stage != 0:
        return
    quest_stage = 1
    quest_changed.emit()
    notification_requested.emit("Задание: соберите 8 дерева и 4 камня.")

func confirm_gathering() -> bool:
    if quest_stage != 1:
        return false
    if not has_items({"wood": 8, "stone": 4}):
        notification_requested.emit("Пока недостаточно ресурсов: нужно 8 дерева и 4 камня.")
        return false
    quest_stage = 2
    quest_changed.emit()
    notification_requested.emit("Ресурсы собраны. Нажмите C, чтобы создать строительный набор.")
    return true

func try_craft_building_kit() -> bool:
    if quest_stage < 2:
        notification_requested.emit("Сначала получите рецепт у Миры.")
        return false
    if house_built or int(inventory.get("building_kit", 0)) > 0:
        notification_requested.emit("Строительный набор уже создан или дом уже построен.")
        return false
    var recipe := {"wood": 8, "stone": 4}
    if not has_items(recipe):
        notification_requested.emit("Для набора требуется 8 дерева и 4 камня.")
        return false
    remove_item("wood", 8)
    remove_item("stone", 4)
    add_item("building_kit", 1)
    notification_requested.emit("Создан строительный набор. Нажмите B, чтобы поставить убежище.")
    return true

func try_mark_house_built(position: Vector3) -> bool:
    if house_built:
        notification_requested.emit("Убежище уже построено.")
        return false
    if not remove_item("building_kit", 1):
        notification_requested.emit("Нужен строительный набор. Создайте его клавишей C.")
        return false
    house_built = true
    house_position = position
    if quest_stage == 2:
        quest_stage = 3
        quest_changed.emit()
    notification_requested.emit("Убежище построено. Вернитесь к Мире.")
    return true

func complete_intro_quest() -> bool:
    if quest_stage != 3 or not house_built:
        return false
    quest_stage = 4
    add_item("starter_axe", 1)
    quest_changed.emit()
    notification_requested.emit("Цепочка завершена. Получен стартовый топор.")
    return true

func advance_survival(real_seconds: float) -> void:
    world_minutes = fmod(world_minutes + real_seconds * 4.0, 1440.0)
    hunger = maxf(0.0, hunger - real_seconds * 0.025)
    thirst = maxf(0.0, thirst - real_seconds * 0.04)
    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - real_seconds * 0.3)
    survival_changed.emit()

func quest_text() -> String:
    match quest_stage:
        0:
            return "Поговорите с Мирой [E]."
        1:
            return "Соберите 8 дерева и 4 камня, затем вернитесь к Мире."
        2:
            return "Создайте строительный набор [C] и постройте убежище [B]."
        3:
            return "Вернитесь к Мире за наградой."
        4:
            return "Первое поручение завершено."
        _:
            return ""

func snapshot() -> Dictionary:
    return {
        "inventory": inventory.duplicate(true),
        "quest_stage": quest_stage,
        "house_built": house_built,
        "house_position": [house_position.x, house_position.y, house_position.z],
        "health": health,
        "hunger": hunger,
        "thirst": thirst,
        "world_minutes": world_minutes
    }

func load_snapshot(data: Dictionary) -> void:
    inventory = DEFAULT_INVENTORY.duplicate(true)
    var saved_inventory = data.get("inventory", {})
    if saved_inventory is Dictionary:
        for key in saved_inventory:
            inventory[String(key)] = int(saved_inventory[key])
    quest_stage = int(data.get("quest_stage", 0))
    house_built = bool(data.get("house_built", false))
    var pos = data.get("house_position", [0.0, 0.0, 0.0])
    if pos is Array and pos.size() == 3:
        house_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
    else:
        house_position = Vector3.ZERO
    health = clampf(float(data.get("health", 100.0)), 0.0, 100.0)
    hunger = clampf(float(data.get("hunger", 100.0)), 0.0, 100.0)
    thirst = clampf(float(data.get("thirst", 100.0)), 0.0, 100.0)
    world_minutes = fmod(float(data.get("world_minutes", 480.0)), 1440.0)
    _emit_all()

func notify(message: String) -> void:
    notification_requested.emit(message)

func _emit_all() -> void:
    inventory_changed.emit()
    quest_changed.emit()
    survival_changed.emit()
