extends Node

class DamageTarget extends StaticBody3D:
    var received := 0.0
    func take_damage(amount: float, _source: Node) -> void:
        received += amount
    func apply_status(_id: String, _duration: float, _source: Node) -> void:
        pass

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    for _frame in range(120):
        await get_tree().physics_frame
    var player := world.get_node("World/Player") as CharacterBody3D
    var camera := player.get_node("CameraPivot/Camera3D") as Camera3D
    var light := world.get_node("World/Sun") as DirectionalLight3D
    for index in range(4):
        SettingsManager.set_quality_preset(index)
        await get_tree().process_frame
        await get_tree().process_frame
        if light.shadow_enabled != (index > 0):
            failures.append("Graphics preset failed to update actual world shadows: %d" % index)
        if get_viewport().msaa_3d != int(SettingsManager.QUALITY_PRESETS[index]["msaa"]):
            failures.append("Graphics preset failed to apply viewport anti-aliasing")
    SettingsManager.load_settings()
    if int(SettingsManager.get_value("graphics", "quality_preset")) != 3:
        failures.append("Graphics preset did not persist")
    SettingsManager.set_quality_preset(1)

    GameState.add_item("starter_axe", 1)
    var panels := world.get_node("UI/GameplayPanels")
    panels.call("_equip", "starter_axe")
    if InventorySystem.attack_bonus() != 8.0:
        failures.append("Equipped axe has no attack bonus")
    panels.call("_unequip", InventorySystem.SLOT_WEAPON)
    if InventorySystem.attack_bonus() != 0.0 or int(GameState.inventory.get("starter_axe", 0)) != 1:
        failures.append("Unequip lost the item or retained its attack bonus")
    InventorySystem.equip("starter_axe")
    var avatar := player.get_node("Avatar")
    var held := avatar.get("held_weapon") as Node3D
    if held == null or String(held.get_meta("item_id", "")) != "starter_axe":
        failures.append("Equipped axe is not attached to the human skeleton")
    elif not held.find_children("*", "MeshInstance3D", true, false).is_empty():
        var mesh := held.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
        var size := mesh.get_aabb().size
        var actual_length := maxf((mesh.global_basis * Vector3(size.x, 0, 0)).length(), maxf((mesh.global_basis * Vector3(0, size.y, 0)).length(), (mesh.global_basis * Vector3(0, 0, size.z)).length()))
        if actual_length < 0.60 or actual_length > 0.70:
            failures.append("Equipped axe lost its normalized world scale: %s" % actual_length)

    var target := DamageTarget.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.8, 2.5, 0.8)
    shape.shape = box
    shape.position.y = 1.25
    target.add_child(shape)
    world.add_child(target)
    target.global_position = player.global_position + Vector3(0, 0, -1.3)
    for _frame in range(3):
        await get_tree().physics_frame
    var ray := player.get_node("CameraPivot/Camera3D/InteractionRay") as RayCast3D
    ray.force_raycast_update()
    player.call("_try_attack")
    if target.received != player.attack_damage + 8.0:
        failures.append("Real melee ray did not hit the target with equipped damage; collider=%s damage=%s" % [ray.get_collider(), target.received])
    var mana_before := GameState.mana
    MagicSystem.selected_index = 0
    if not MagicSystem.cast_selected(player, camera):
        failures.append("Fireball did not cast")
    for child in world.get_children():
        if child.get_script() == MagicSystem.PROJECTILE_SCRIPT and child.global_position.distance_to(player.global_position) > 2.0:
            failures.append("Spell projectile still appears at the camera, behind the human")
    if player.cast_elapsed <= 0.0:
        failures.append("Successful spell did not trigger the human's casting gesture")
    if GameState.mana >= mana_before or MagicSystem.cast_selected(player, camera):
        failures.append("Spell mana cost or cooldown is ineffective")
    for _frame in range(45):
        await get_tree().physics_frame
    if target.received <= player.attack_damage + 8.0:
        failures.append("Physical fireball did not travel into and damage the target")
    target.global_position = player.global_position + Vector3(0, 0, -12.0)
    GameState.add_item("short_bow", 1)
    GameState.add_item("arrow", 2)
    InventorySystem.equip("short_bow")
    player.attack_elapsed = 0.0
    for _frame in range(3):
        await get_tree().physics_frame
    var before_arrow := target.received
    player.call("_try_attack")
    player.call("_try_attack")
    if int(GameState.inventory.get("arrow", 0)) != 1:
        failures.append("Bow shot did not consume one arrow or ignored attack cooldown")
    for _frame in range(45):
        await get_tree().physics_frame
    if absf(target.received - before_arrow - 20.0) > 0.01:
        failures.append("Physical arrow did not damage its ranged target exactly once")
    GameState.remove_item("arrow", 1)
    player.attack_elapsed = 0.0
    var before_empty := GameState.stamina
    player.call("_try_attack")
    if GameState.stamina != before_empty:
        failures.append("Empty bow consumed stamina")
    InventorySystem.unequip(InventorySystem.SLOT_WEAPON)
    if avatar.get("held_weapon") != null:
        failures.append("Unequipped weapon is still visible on the human")
    for index in range(1, MagicSystem.SPELL_ORDER.size()):
        GameState.mana = GameState.max_mana
        if String(MagicSystem.SPELL_ORDER[index]) == "heal":
            GameState.health = 50.0
        MagicSystem.selected_index = index
        if not MagicSystem.cast_selected(player, camera):
            failures.append("Spell failed: " + MagicSystem.selected_spell_id())
        if MagicSystem.selected_spell_id() == "heal" and GameState.health <= 50.0:
            failures.append("Healing spell did not restore health")
        await get_tree().physics_frame
    if GameState.magic_shield <= 0.0:
        failures.append("Shield spell did not add protection")
    if failures.is_empty():
        print("GAMEPLAY_ACTIONS_SMOKE_OK quality=4 persisted=true equip=visible unequip=retained melee=hit projectile=hit bow=hit ammo=consumed spells=10")
    else:
        for failure in failures:
            push_error(failure)
    world.queue_free()
    # Match the existing world-audio fixture: stop the scene, then allow the
    # asynchronous mixer to retire its playback before terminating the engine.
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if failures.is_empty() else 1)
