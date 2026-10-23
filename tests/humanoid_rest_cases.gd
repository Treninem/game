extends RefCounted

func run(parent: Node3D) -> Array[String]:
    var failures: Array[String] = []
    var home := Node3D.new()
    parent.add_child(home)
    home.position.x = 60.0
    var furniture_group := Node3D.new()
    home.add_child(furniture_group)
    var bed := preload("res://scripts/household_furniture.gd").new()
    bed.name = "Bed"
    furniture_group.add_child(bed)
    var bench := preload("res://scripts/household_furniture.gd").new()
    bench.name = "Bench"
    furniture_group.add_child(bench)
    var stage := load("res://scenes/stage1.tscn").instantiate() as Node
    var actor := stage.get_node("World/Player") as CharacterBody3D
    actor.get_parent().remove_child(actor)
    stage.free()
    parent.add_child(actor)
    actor.set_physics_process(false)
    actor.set_process_input(false)
    actor.call("_set_instanced_world_mode", true)
    actor.position = Vector3(60, 1, 0)
    var visual := actor.get_node("Avatar") as Node3D
    visual.set_process(false)
    var checked := 0
    for sex: String in ["male", "female"]:
        for height: float in [160.0, 180.0, 195.0]:
            var profile := {"sex": sex, "height_cm": height}
            GameState.set_world_value("player_appearance", profile)
            visual.call("apply_appearance", profile)
            visual.set("appearance_revision", GameState.state_revision)
            var expected := Vector3.ONE * height / 180.0
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            var processed := {"count": 0}
            visual.get("grip_modifier").modification_processed.connect(func(): processed.count += 1)
            for furniture: HouseholdFurniture in [bed, bench]:
                for item: String in ["", "starter_axe", "short_bow", "stone_knife"]:
                    InventorySystem.unequip(InventorySystem.SLOT_WEAPON)
                    if not item.is_empty():
                        if int(GameState.inventory.get(item, 0)) == 0:
                            GameState.add_item(item, 1)
                        InventorySystem.equip(item)
                    furniture.claim("player")
                    GameState.set_world_value("player:rest_furniture", furniture.furniture_id)
                    actor.set_meta("rest_furniture", furniture.furniture_id)
                    visual.set("appearance_revision", GameState.state_revision)
                    var inventory := GameState.inventory.duplicate(true)
                    var original_position := actor.global_position
                    var before_count: int = processed.count
                    for iteration in range(3):
                        furniture.apply_rest_pose(actor, visual)
                        visual.call("_process", 1.0 / 60.0)
                        skeleton.advance(1.0 / 60.0)
                        await parent.get_tree().process_frame
                    var label := "%s/%s/%s/%s" % [sex, height, furniture.kind, item]
                    if processed.count == before_count:
                        failures.append("Rest fixture did not process final skeleton: " + label)
                    if visual.scale.distance_to(expected) > 0.0001:
                        failures.append("Rest changes body scale: " + label)
                    if furniture.kind == "bed":
                        var face_up := (visual.global_basis * Vector3.FORWARD).normalized()
                        var head := furniture.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin))
                        var hips := furniture.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin))
                        if face_up.dot(Vector3.UP) < 0.99 or head.z < hips.z + 0.3 * expected.y:
                            failures.append("Sleeper is not supine with head toward the pillow: " + label)
                    if furniture.kind == "bench":
                        var hip := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin)
                        if absf(hip.y - (bench.global_position.y + float(bench.get_meta("rest_support_y", 0.11)) + 0.09 * expected.y)) > 0.025:
                            failures.append("Seated pelvis misses seat for selected height: " + label)
                    var weapon: Node3D = visual.get("held_weapon")
                    if is_instance_valid(weapon) and weapon.visible:
                        failures.append("Rest keeps weapon active in the hand: " + label)
                    if inventory != GameState.inventory or InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != item:
                        failures.append("Rest changes equipment ownership: " + label)
                    actor.set("attack_elapsed", 0.0)
                    GameState.stamina = GameState.max_stamina
                    if item.is_empty():
                        GameState.mana = 0.0
                        var event := InputEventAction.new()
                        event.action = "cast_magic"
                        event.pressed = true
                        actor.call("_unhandled_input", event)
                    else:
                        actor.call("_try_attack")
                    if visual.top_level or not furniture.occupant.is_empty() or String(GameState.get_world_value("player:rest_furniture", "")) != "" or String(actor.get_meta("rest_furniture", "")) != "":
                        failures.append("Action starts before releasing furniture and rest pose: " + label)
                    # Cleanup also permits the old-code negative control to finish.
                    furniture.release("player")
                    GameState.set_world_value("player:rest_furniture", "")
                    HouseholdFurniture.clear_pose(actor, visual)
                    actor.set("attack_elapsed", 0.0)
                    actor.set("pending_bow_elapsed", 0.0)
                    actor.set("pending_axe_elapsed", 0.0)
                    visual.call("_process", 1.0 / 60.0)
                    skeleton.advance(1.0 / 60.0)
                    await parent.get_tree().process_frame
                    if visual.top_level or visual.scale.distance_to(expected) > 0.0001 or actor.global_position.distance_to(original_position) > 0.0001:
                        failures.append("Wake changes dimensions or physical actor: " + label)
                    if is_instance_valid(weapon) and not weapon.visible:
                        failures.append("Wake fails to restore held equipment: " + label)
                    checked += 1
    InventorySystem.unequip(InventorySystem.SLOT_WEAPON)
    actor.queue_free()
    home.queue_free()
    await parent.get_tree().process_frame
    print("HUMANOID_REST_CHECKED poses=", checked, " bodies=2 heights=3 furniture=2 equipment=4 repeated_pose=true actor_root_unchanged=true")
    return failures
