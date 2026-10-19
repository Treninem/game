class_name HouseholdFurniture
extends StaticBody3D

# Stable world-space identity, independent of streamed cell/node instance IDs.
var kind := ""
var furniture_id := ""
var occupant := ""
var revision := -1
var storage_ui_open := false
var chest_animation: AnimationPlayer
var lid_target := false

func _ready() -> void:
    kind = "bed" if String(name).begins_with("Bed") else "bench" if String(name).begins_with("Bench") else "chest" if String(name).ends_with("Chest") else "table"
    var home := get_parent().get_parent() as Node3D
    furniture_id = "furniture:%d:%d:%d:%s" % [roundi(home.global_position.x * 100), roundi(home.global_position.y * 100), roundi(home.global_position.z * 100), name]
    process_mode = Node.PROCESS_MODE_ALWAYS
    DialogueManager.dialogue_closed.connect(func(): storage_ui_open = false)
    add_to_group("household_furniture")
    restore_saved_state()

func state() -> Dictionary:
    var value: Variant = GameState.get_world_value(furniture_id, {})
    var saved: Dictionary = value.duplicate(true) if value is Dictionary else {}
    if kind == "chest":
        if not saved.get("owners") is Array:
            var home := get_parent().get_parent()
            saved.owners = ["player"] if name == "GuestChest" else home.get_meta("household_owners", []).duplicate()
        saved.capacity = 200
    return saved

func restore_saved_state() -> void:
    revision = GameState.state_revision
    var saved := state()
    occupant = String(saved.get("occupant", "")) if saved.get("occupant", "") is String else ""

func claim(id: String) -> bool:
    if revision != GameState.state_revision:
        restore_saved_state()
    if id.is_empty() or (kind == "chest" and not allows(id)) or (not occupant.is_empty() and occupant != id):
        return false
    if occupant == id:
        return true
    occupant = id
    var saved := state()
    saved.occupant = id
    GameState.set_world_value(furniture_id, saved)
    return true

func release(id: String) -> void:
    if revision != GameState.state_revision:
        restore_saved_state()
    if occupant != id:
        return
    occupant = ""
    var saved := state()
    saved.occupant = ""
    GameState.set_world_value(furniture_id, saved)

func approach_point() -> Vector3:
    # The left bench is approached from its open side. Its cross-room path is
    # separated from the right bench so simultaneous wake/return paths do not
    # meet head-on at the same point in the aisle.
    return global_position + global_basis * (Vector3(1.45, 0, 0) if kind == "bed" or name == "BenchSecond" or name == "GuestChest" else Vector3(0, 0, -1.05 if kind == "bench" else 1.05))

func contents() -> Dictionary:
    var raw: Variant = state().get("items", {})
    var result := {}
    if raw is Dictionary:
        for item: String in InventorySystem.ITEMS:
            var count: Variant = raw.get(item, 0)
            if (count is int or count is float) and is_finite(float(count)) and float(count) == floor(float(count)) and float(count) > 0 and float(count) <= 100000:
                result[item] = int(count)
    return result

func allows(id: String) -> bool:
    var owners: Array = state().get("owners", [])
    return owners.is_empty() or owners.has(id)

func free_capacity() -> int:
    var used := 0
    for count in contents().values():
        used += int(count)
    return maxi(0, 200 - used)

func transfer(actor: Node3D, item: String, deposit: bool, amount: int = 1) -> bool:
    if kind != "chest" or not _reachable(actor) or not allows("player") or amount < 1 or amount > 100000 or not occupant.is_empty() or not InventorySystem.ITEMS.has(item):
        return false
    var items := contents()
    if deposit:
        # Equipped equipment must remain in the inventory which owns it.
        for slot in [InventorySystem.SLOT_WEAPON, InventorySystem.SLOT_TOOL, InventorySystem.SLOT_BODY]:
            if InventorySystem.equipped_item(slot) == item:
                GameState.notify("Сначала снимите этот предмет.")
                return false
        if free_capacity() < amount or not GameState.remove_item(item, amount):
            return false
        items[item] = int(items.get(item, 0)) + amount
    else:
        if int(items.get(item, 0)) < amount:
            return false
        items[item] = int(items[item]) - amount
        GameState.add_item(item, amount)
    var saved := state()
    saved.items = items
    GameState.set_world_value(furniture_id, saved)
    return true

func _reachable(actor: Node3D) -> bool:
    if actor == null or not actor.is_inside_tree() or not actor.is_in_group("player") or GameState.is_dead:
        return false
    var origin := actor.global_position + Vector3.UP
    if origin.distance_to(global_position) > 3.1:
        return false
    var query := PhysicsRayQueryParameters3D.create(origin, global_position, 1, [actor.get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.collider == self

func interact(actor: Node3D) -> void:
    if not _reachable(actor):
        return
    if not occupant.is_empty():
        GameState.notify("Сейчас этим предметом пользуется житель.")
        return
    if kind == "chest":
        open_storage(actor)
    elif kind in ["bed", "bench"]:
        # Player rest uses the same supported pose as residents; movement wakes.
        actor.set_meta("rest_furniture", furniture_id)
        GameState.set_world_value("player:rest_furniture", furniture_id)
        claim("player")
        GameState.notify("Отдых: движение или прыжок — встать.")

func open_storage(actor: Node3D) -> void:
    if not _reachable(actor) or not occupant.is_empty():
        DialogueManager.close_dialogue()
        return
    if not allows("player"):
        GameState.notify("Личный сундук жителей. Нужно согласие владельца.")
        return
    storage_ui_open = true
    var choices: Array = []
    var items := contents()
    for item: String in InventorySystem.ITEMS:
        var label := String(InventorySystem.item_info(item).get("name", item))
        for deposit: bool in [false, true]:
            var count := int(GameState.inventory.get(item, 0)) if deposit else int(items.get(item, 0))
            if count > 0:
                choices.append({"text": "%s: %s ×1 (есть %d)" % ["Положить" if deposit else "Взять", label, count], "action": "furniture_transfer", "furniture": get_instance_id(), "item": item, "deposit": deposit})
                var batch := mini(count, free_capacity()) if deposit else count
                if batch > 1:
                    choices.append({"text": "%s: %s ×%d" % ["Положить стопку" if deposit else "Взять стопку", label, batch], "action": "furniture_transfer", "furniture": get_instance_id(), "item": item, "deposit": deposit, "amount": batch})
    choices.append({"text": "Закрыть сундук", "action": "close"})
    DialogueManager.open_dialogue("Домашний сундук", "Свободно %d из 200 мест. Можно переносить предметы стопкой. Содержимое и права доступа сохраняются." % free_capacity(), choices)

func apply_rest_pose(actor: CharacterBody3D, visual: Node3D) -> void:
    visual.top_level = true
    visual.global_basis = global_basis.orthonormalized() * (Basis(Vector3.RIGHT, -PI * 0.5) if kind == "bed" else Basis.IDENTITY)
    # The visual alone is supported by furniture; the physical actor remains
    # on the clear approach floor, so waking never embeds a capsule in wood.
    var support := float(get_meta("rest_support_y", 0.34 if kind == "bed" else 0.11))
    var hip: Variant = visual.get("standing_hip_height")
    var hip_height := float(hip) if hip is float and is_finite(hip) and hip > 0.3 else 0.95
    visual.global_position = global_position + global_basis * (Vector3(0, support + 0.10, 0.83) if kind == "bed" else Vector3(0, support + 0.09 - hip_height, 0))
    actor.set_meta("activity", "sleep" if kind == "bed" else "sit")

static func clear_pose(actor: Node3D, visual: Node3D) -> void:
    visual.top_level = false
    visual.transform = Transform3D.IDENTITY
    actor.set_meta("activity", "idle")

func _process(_delta: float) -> void:
    if kind != "chest":
        return
    if chest_animation == null:
        var model := get_node_or_null("RealChestModel")
        if model == null:
            return
        var players := model.find_children("*", "AnimationPlayer", true, false)
        if players.is_empty():
            return
        chest_animation = players[0] as AnimationPlayer
        chest_animation.process_mode = Node.PROCESS_MODE_ALWAYS
        chest_animation.play("Chest_Opened" if not occupant.is_empty() else "Chest_Closed")
    var opened := storage_ui_open and DialogueManager.is_open or not occupant.is_empty()
    if opened != lid_target:
        lid_target = opened
        chest_animation.play("Chest_Open" if opened else "Chest_Close", 0.08)
