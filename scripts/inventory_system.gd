extends Node

signal equipment_changed
signal crafting_changed

const SLOT_WEAPON := "weapon"
const SLOT_TOOL := "tool"
const SLOT_BODY := "body"

const ITEMS := {
    "wood": {"name": "Древесина", "category": "Ресурс", "description": "Базовый строительный и ремесленный материал.", "equip_slot": ""},
    "stone": {"name": "Камень", "category": "Ресурс", "description": "Камень для строительства и простых инструментов.", "equip_slot": ""},
    "berries": {"name": "Лесные ягоды", "category": "Еда", "description": "Немного утоляют голод и восстанавливают здоровье.", "equip_slot": ""},
    "water_flask": {"name": "Фляга воды", "category": "Напиток", "description": "Восстанавливает запас жидкости.", "equip_slot": ""},
    "raw_meat": {"name": "Сырое мясо", "category": "Еда", "description": "Питательно, но употреблять сырым опасно.", "equip_slot": ""},
    "starter_axe": {"name": "Топор поселенца", "category": "Оружие / инструмент", "description": "Простой топор. Усиливает ближнюю атаку и подходит для работы по дереву.", "equip_slot": SLOT_WEAPON},
    "stone_knife": {"name": "Каменный нож", "category": "Оружие", "description": "Лёгкое раннее оружие для ближнего боя.", "equip_slot": SLOT_WEAPON},
    "campfire_kit": {"name": "Набор для костра", "category": "Походное", "description": "Подготовленные материалы для будущей системы лагеря.", "equip_slot": ""},
    "cooked_meat": {"name": "Жареное мясо", "category": "Еда", "description": "Безопасная и сытная еда.", "equip_slot": ""}
}

# Permanent building recipes are intentionally absent in Stage 10. They will be
# authored only after city/region rules, land ownership and placement constraints
# are stable. Small survival recipes remain useful for traversal testing.
const RECIPES := {
    "stone_knife": {"name": "Каменный нож", "result": "stone_knife", "amount": 1, "requirements": {"wood": 1, "stone": 3}},
    "campfire_kit": {"name": "Походный набор для костра", "result": "campfire_kit", "amount": 1, "requirements": {"wood": 4, "stone": 6}},
    "cooked_meat": {"name": "Жареное мясо", "result": "cooked_meat", "amount": 1, "requirements": {"raw_meat": 1, "wood": 1}}
}

func item_info(item_id: String) -> Dictionary:
    return ITEMS.get(item_id, {"name": item_id, "category": "Неизвестно", "description": "", "equip_slot": ""})

func inventory_rows() -> Array:
    var rows: Array = []
    for item_id in GameState.inventory:
        var amount := int(GameState.inventory.get(item_id, 0))
        if amount <= 0:
            continue
        var info := item_info(String(item_id)).duplicate(true)
        info["id"] = String(item_id)
        info["amount"] = amount
        rows.append(info)
    rows.sort_custom(func(a: Dictionary, b: Dictionary): return String(a.get("name", "")) < String(b.get("name", "")))
    return rows

func available_recipes() -> Array:
    var rows: Array = []
    for recipe_id in RECIPES:
        var recipe: Dictionary = RECIPES[recipe_id]
        var row := recipe.duplicate(true)
        row["id"] = String(recipe_id)
        row["can_craft"] = GameState.has_items(row.get("requirements", {}))
        rows.append(row)
    return rows

func craft(recipe_id: String) -> bool:
    if not RECIPES.has(recipe_id):
        GameState.notify("Этот рецепт сейчас недоступен.")
        return false
    var recipe: Dictionary = RECIPES[recipe_id]
    var requirements: Dictionary = recipe.get("requirements", {})
    if not GameState.has_items(requirements):
        GameState.notify("Недостаточно материалов для: %s" % String(recipe.get("name", recipe_id)))
        return false
    for item_id in requirements:
        if not GameState.remove_item(String(item_id), int(requirements[item_id])):
            return false
    GameState.add_item(String(recipe.get("result", recipe_id)), int(recipe.get("amount", 1)))
    GameState.notify("Создано: %s" % String(recipe.get("name", recipe_id)))
    crafting_changed.emit()
    return true

func equipment() -> Dictionary:
    var saved = GameState.get_world_value("equipment", {})
    if typeof(saved) != TYPE_DICTIONARY:
        return {}
    return saved.duplicate(true)

func equipped_item(slot: String) -> String:
    return String(equipment().get(slot, ""))

func equip(item_id: String) -> bool:
    if int(GameState.inventory.get(item_id, 0)) <= 0:
        return false
    var info := item_info(item_id)
    var slot := String(info.get("equip_slot", ""))
    if slot.is_empty():
        GameState.notify("Этот предмет нельзя экипировать.")
        return false
    var eq := equipment()
    eq[slot] = item_id
    GameState.set_world_value("equipment", eq)
    equipment_changed.emit()
    GameState.notify("Экипировано: %s" % String(info.get("name", item_id)))
    return true

func unequip(slot: String) -> void:
    var eq := equipment()
    if eq.has(slot):
        eq.erase(slot)
        GameState.set_world_value("equipment", eq)
        equipment_changed.emit()

func attack_bonus() -> float:
    match equipped_item(SLOT_WEAPON):
        "starter_axe": return 8.0
        "stone_knife": return 5.0
        _: return 0.0

func requirements_text(requirements: Dictionary) -> String:
    var parts: Array[String] = []
    for item_id in requirements:
        var info := item_info(String(item_id))
        parts.append("%s ×%d" % [String(info.get("name", item_id)), int(requirements[item_id])])
    return ", ".join(parts)
