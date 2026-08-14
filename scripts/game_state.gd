extends Node

signal inventory_changed
signal quest_changed
signal survival_changed
signal location_changed(location: String)
signal notification_requested(message: String)
signal player_died

const CONTENT_PHASE := "world_foundation"
const DEFAULT_INVENTORY := {
    "wood": 0,
    "stone": 0,
    "starter_axe": 0,
    "raw_meat": 0,
    "berries": 2,
    "water_flask": 1
}

var inventory: Dictionary = DEFAULT_INVENTORY.duplicate(true)
# Kept for backward save compatibility. Gameplay quests are intentionally
# suspended until the world/capital/regions are stable and authored.
var quest_stage: int = 0
var city_quest_stage: int = 0
var city_reputation: int = 0
var coins: int = 20
var current_location := "Люменград • территория столицы"
# Legacy shelter fields are retained only so older saves can be migrated safely.
var house_built: bool = false
var house_position: Vector3 = Vector3.ZERO
var health: float = 100.0
var max_health: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var temperature: float = 36.6
var world_minutes: float = 8.0 * 60.0
var enemies_defeated: int = 0
var is_dead: bool = false
var world_state: Dictionary = {}

func reset_new_game() -> void:
    inventory = DEFAULT_INVENTORY.duplicate(true)
    quest_stage = 0
    city_quest_stage = 0
    city_reputation = 0
    coins = 20
    current_location = "Люменград • территория столицы"
    house_built = false
    house_position = Vector3.ZERO
    health = max_health
    stamina = max_stamina
    hunger = 100.0
    thirst = 100.0
    temperature = 36.6
    world_minutes = 8.0 * 60.0
    enemies_defeated = 0
    is_dead = false
    world_state = {"content_phase": CONTENT_PHASE, "world_foundation_v1": true}
    _emit_all()
    location_changed.emit(current_location)

func migrate_to_world_foundation() -> void:
    # Removes prototype progression without deleting useful player resources,
    # map exploration or settings from existing save slots.
    quest_stage = 0
    city_quest_stage = 0
    house_built = false
    house_position = Vector3.ZERO
    inventory.erase("building_kit")
    world_state.erase("house")
    world_state.erase("house_position")
    world_state["content_phase"] = CONTENT_PHASE
    world_state["world_foundation_v1"] = true
    _emit_all()

func set_location(location: String) -> void:
    if location.is_empty() or current_location == location:
        return
    current_location = location
    location_changed.emit(current_location)

func set_world_value(key: String, value: Variant) -> void:
    if key.is_empty():
        return
    world_state[key] = value

func get_world_value(key: String, default_value: Variant = null) -> Variant:
    return world_state.get(key, default_value)

func add_item(item_id: String, amount: int = 1) -> void:
    if item_id == "building_kit":
        return
    inventory[item_id] = int(inventory.get(item_id, 0)) + maxi(amount, 0)
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

func use_consumable(item_id: String) -> bool:
    if int(inventory.get(item_id, 0)) <= 0:
        notify("Предмет закончился.")
        return false
    match item_id:
        "berries":
            remove_item(item_id, 1)
            hunger = minf(100.0, hunger + 18.0)
            health = minf(max_health, health + 3.0)
            notify("Вы съели ягоды.")
        "water_flask":
            remove_item(item_id, 1)
            thirst = minf(100.0, thirst + 35.0)
            notify("Вы выпили воду.")
        "raw_meat":
            remove_item(item_id, 1)
            hunger = minf(100.0, hunger + 25.0)
            health = maxf(1.0, health - 4.0)
            notify("Сырое мясо утолило голод, но навредило здоровью.")
        _:
            return false
    survival_changed.emit()
    return true

func consume_stamina(amount: float) -> bool:
    if stamina < amount:
        return false
    stamina = maxf(0.0, stamina - amount)
    survival_changed.emit()
    return true

func restore_stamina(amount: float) -> void:
    stamina = minf(max_stamina, stamina + amount)

func apply_damage(amount: float) -> void:
    if is_dead or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    survival_changed.emit()
    if health <= 0.0:
        is_dead = true
        notify("Вы погибли. Возрождение у безопасной точки столицы.")
        player_died.emit()

func revive() -> void:
    is_dead = false
    health = max_health
    stamina = max_stamina
    hunger = maxf(hunger, 55.0)
    thirst = maxf(thirst, 55.0)
    survival_changed.emit()

func register_enemy_defeat(enemy_id: String = "") -> void:
    if not enemy_id.is_empty():
        set_world_value("enemy:" + enemy_id, true)
    enemies_defeated += 1
    add_item("raw_meat", 1)
    notify("Противник побеждён.")

# Prototype quest/building entry points remain as safe no-ops so older NPC
# scripts cannot crash the world-foundation build. They will be replaced after
# the authored world and capital are complete.
func start_quest() -> void:
    notify("Задания временно отключены: сначала завершается мир и столица.")

func confirm_gathering() -> bool:
    return false

func try_craft_building_kit() -> bool:
    notify("Строительство будет подключено после завершения мира и локаций.")
    return false

func try_mark_house_built(_position: Vector3) -> bool:
    notify("Строительство будет подключено после завершения мира и локаций.")
    return false

func complete_intro_quest() -> bool:
    return false

func start_city_quest() -> bool:
    return false

func complete_city_quest() -> bool:
    return false

func advance_survival(real_seconds: float) -> void:
    world_minutes = fmod(world_minutes + real_seconds * 4.0, 1440.0)
    hunger = maxf(0.0, hunger - real_seconds * 0.025)
    thirst = maxf(0.0, thirst - real_seconds * 0.04)
    restore_stamina(real_seconds * 13.0)
    var hour := int(world_minutes / 60.0)
    var target_temperature := 36.6
    if hour >= 21 or hour < 6:
        target_temperature = 36.2
    temperature = move_toward(temperature, target_temperature, real_seconds * 0.02)
    if hunger <= 0.0 or thirst <= 0.0:
        apply_damage(real_seconds * 0.3)
    survival_changed.emit()

func quest_text() -> String:
    return ""

func snapshot() -> Dictionary:
    return {
        "inventory": inventory.duplicate(true),
        "quest_stage": 0,
        "city_quest_stage": 0,
        "city_reputation": city_reputation,
        "coins": coins,
        "current_location": current_location,
        "house_built": false,
        "house_position": [0.0, 0.0, 0.0],
        "health": health,
        "stamina": stamina,
        "hunger": hunger,
        "thirst": thirst,
        "temperature": temperature,
        "world_minutes": world_minutes,
        "enemies_defeated": enemies_defeated,
        "world_state": world_state.duplicate(true)
    }

func load_snapshot(data: Dictionary) -> void:
    inventory = DEFAULT_INVENTORY.duplicate(true)
    var saved_inventory = data.get("inventory", {})
    if typeof(saved_inventory) == TYPE_DICTIONARY:
        for key in saved_inventory:
            var item_id := String(key)
            if item_id != "building_kit":
                inventory[item_id] = int(saved_inventory[key])
    quest_stage = 0
    city_quest_stage = 0
    city_reputation = maxi(0, int(data.get("city_reputation", 0)))
    coins = maxi(0, int(data.get("coins", 20)))
    current_location = String(data.get("current_location", "Люменград • территория столицы"))
    house_built = false
    house_position = Vector3.ZERO
    health = clampf(float(data.get("health", 100.0)), 0.0, max_health)
    stamina = clampf(float(data.get("stamina", 100.0)), 0.0, max_stamina)
    hunger = clampf(float(data.get("hunger", 100.0)), 0.0, 100.0)
    thirst = clampf(float(data.get("thirst", 100.0)), 0.0, 100.0)
    temperature = clampf(float(data.get("temperature", 36.6)), 30.0, 42.0)
    world_minutes = fmod(float(data.get("world_minutes", 480.0)), 1440.0)
    enemies_defeated = maxi(0, int(data.get("enemies_defeated", 0)))
    var saved_world_state = data.get("world_state", {})
    world_state = saved_world_state.duplicate(true) if typeof(saved_world_state) == TYPE_DICTIONARY else {}
    is_dead = health <= 0.0
    migrate_to_world_foundation()
    location_changed.emit(current_location)

func notify(message: String) -> void:
    notification_requested.emit(message)

func _emit_all() -> void:
    inventory_changed.emit()
    quest_changed.emit()
    survival_changed.emit()
