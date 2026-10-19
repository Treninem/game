extends Node3D

const RESOURCE := preload("res://scripts/streamed_resource.gd")
var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout

func _tree(id_value: String, position_value: Vector3) -> StaticBody3D:
    var tree := RESOURCE.new()
    tree.configure(id_value, "wood", 5)
    tree.position = position_value
    add_child(tree)
    return tree

func _strike(player: CharacterBody3D) -> void:
    player.attack_elapsed = 0
    GameState.stamina = 100
    player.get_node("CameraPivot/Camera3D/InteractionRay").force_raycast_update()
    player.call("_try_attack")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    var player := world.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    world.free()
    var spawn := WorldGeography.START_SPAWN
    var origin := Vector3(spawn.x, WorldData.elevation_at(spawn), spawn.y)
    var floor_body := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(30, 1, 30)
    collision.shape = box
    floor_body.position = origin + Vector3.DOWN * 0.5
    floor_body.add_child(collision)
    add_child(floor_body)
    add_child(player)
    var audio := preload("res://scripts/world_audio.gd").new()
    add_child(audio)
    player.global_position = origin + Vector3.UP * 0.08
    player.rotation = Vector3.ZERO
    player.get_node("CameraPivot").rotation = Vector3.ZERO
    var tree := _tree("chopping_fixture", origin + Vector3(0, 0, -1.5))
    await _wait(0.5)
    var before := int(GameState.inventory.get("wood", 0))
    tree.interact(player)
    _strike(player)
    await _wait(0.3)
    if tree.cuts != 0 or int(GameState.inventory.get("wood", 0)) != before:
        failures.append("Standing tree yields wood or takes bare-hand damage")
    GameState.add_item("starter_axe", 1)
    InventorySystem.equip("starter_axe")
    tree.global_position.z = origin.z - 1.9
    await _wait(0.1)
    _strike(player)
    await _wait(0.3)
    if tree.cuts != 0 or audio.wood_hit_count != 0:
        failures.append("Short axe cuts a camera-visible trunk beyond arm/tool reach")
    tree.global_position.z = origin.z - 1.5
    await _wait(0.1)
    _strike(player)
    if tree.cuts != 0:
        failures.append("Axe contact happens before the animation wind-up")
    await _wait(0.3)
    if tree.cuts != 1:
        failures.append("Real player axe swing does not damage the reachable trunk")
    var skeleton := player.get_node("Avatar/HumanModel").find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var hand := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin)
    print("CHOP_HAND_FORWARD ", (hand - player.global_position).dot(-player.global_basis.z))
    if (hand - player.global_position).dot(-player.global_basis.z) < 0.15:
        failures.append("Retargeted chopping stroke points sideways instead of forward")
    if audio.wood_hit_count != 1 or audio.last_wood_hit_position.distance_to(tree.global_position + Vector3.UP * 1.1) < 0.1:
        failures.append("Wood contact sound is absent or originates inside the trunk")
    _strike(player)
    InventorySystem.unequip(InventorySystem.SLOT_WEAPON)
    await _wait(0.3)
    if tree.cuts != 1:
        failures.append("Unequipping during wind-up still cuts the tree")
    InventorySystem.equip("starter_axe")
    _strike(player)
    player.rotation.y = PI
    await _wait(0.3)
    if tree.cuts != 1:
        failures.append("Turning away still cuts a tree behind the hero")
    player.rotation.y = 0
    _strike(player)
    player.global_position.x += 5
    await _wait(0.3)
    if tree.cuts != 1:
        failures.append("Axe contact ignores movement out of reach")
    if audio.wood_hit_count != 1:
        failures.append("Cancelled axe swings still play wood-contact audio")
    player.global_position.x = origin.x
    tree.free()
    tree = _tree("chopping_fixture", origin + Vector3(0, 0, -1.5))
    if tree.cuts != 1:
        failures.append("Trunk damage is lost on chunk reload")
    await _wait(0.1)
    for hit in range(2):
        _strike(player)
        await _wait(0.35)
    if not tree.falling or not tree.fallen:
        failures.append("Third physical axe stroke does not fell the tree")
    tree.interact(player)
    if int(GameState.inventory.get("wood", 0)) != before:
        failures.append("Wood is granted before falling completes")
    # Save/load the real world state while a tree is still falling. Reload must
    # finish as a stump with unclaimed loot, never restore the upright crown.
    SaveManager.current_slot = 19
    if not SaveManager.save_game(player):
        failures.append("Could not save falling-tree state")
    GameState.world_state = {}
    if not SaveManager.load_game(player):
        failures.append("Could not reload falling-tree state")
    tree.free()
    tree = _tree("chopping_fixture", origin + Vector3(0, 0, -1.5))
    if not tree.fallen or tree.falling or tree.visual_root.visible or not tree.stump.visible:
        failures.append("Felled tree does not restore as an authored stump")
    await _wait(0.1)
    var blocker := StaticBody3D.new()
    var blocker_shape := CollisionShape3D.new()
    var blocker_box := BoxShape3D.new()
    blocker_box.size = Vector3(4, 2, 0.2)
    blocker_shape.shape = blocker_box
    blocker.add_child(blocker_shape)
    blocker.position = origin + Vector3(0, 0.9, -0.8)
    add_child(blocker)
    await _wait(0.1)
    player.call("_try_interact")
    if int(GameState.inventory.get("wood", 0)) != before:
        failures.append("Nearby wood collection reaches through a wall")
    blocker.free()
    await _wait(0.1)
    player.call("_try_interact")
    player.call("_try_interact")
    if int(GameState.inventory.get("wood", 0)) != before + 5 or tree.uses != 0:
        failures.append("Felled-tree collection duplicates or loses wood")
    tree.free()
    tree = _tree("chopping_fixture", origin + Vector3(0, 0, -1.5))
    tree.interact(player)
    if tree.uses != 0 or int(GameState.inventory.get("wood", 0)) != before + 5 or not tree.stump.visible:
        failures.append("Collected tree respawns its wood or loses the stump")
    var second := _tree("fall_animation_fixture", origin + Vector3(0, 0, -4))
    second.call("_fell", player.global_position)
    await _wait(0.7)
    if second.visual_root.rotation.length() < 0.1 or not second.visual_root.visible:
        failures.append("Tree fall is not visibly animated")
    await _wait(0.8)
    if second.falling or second.visual_root.visible or not second.stump.visible:
        failures.append("Fall does not finish in a stable stump state")
    if not second.fallen_log.visible:
        failures.append("Fallen tree leaves no visible authored wood to collect")
    second.interact(player)
    if second.fallen_log.visible:
        failures.append("Collected logs remain visible")
    tree.free()
    second.free()
    # Exercise the actual start-forest batch promotion, not a resource-only
    # fixture. The untouched neighbour must retain all its mesh transforms.
    var forest := preload("res://scripts/start_region_streamer.gd").new()
    var cell := Node3D.new()
    cell.set_meta("visual_batches", {})
    add_child(cell)
    var scene := preload("res://assets/production/nature/temperate/TemperateTree.glb")
    var tree_world := Vector2(origin.x, origin.z - 1.5)
    forest.call("_spawn_physical_tree", cell, scene, tree_world, 0.9, 0.7, 0)
    forest.call("_spawn_physical_tree", cell, scene, tree_world + Vector2(5, 0), 0.8, 0.2, 1)
    forest.call("_materialize_visual_batches", cell)
    var neighbour_transforms: Array[Transform3D] = []
    for child in cell.get_children():
        if child is MultiMeshInstance3D:
            neighbour_transforms.append(child.multimesh.get_instance_transform(1))
    await _wait(0.1)
    _strike(player)
    await _wait(0.3)
    var promoted: Node = null
    var index := 0
    for child in cell.get_children():
        if child is MultiMeshInstance3D:
            if 0 not in child.get_meta("chopped_indices", []):
                failures.append("Start-forest promotion does not remove its batched instance")
            if DisplayServer.get_name() != "headless" and child.multimesh.get_instance_transform(0).basis.get_scale().length() > 0.001:
                failures.append("Struck tree remains duplicated in the forest draw batch: %s scale=%s source=%s" % [child.name, child.multimesh.get_instance_transform(0).basis.get_scale(), child.get_meta("tree_source", "missing")])
            if child.multimesh.get_instance_transform(1) != neighbour_transforms[index]:
                failures.append("Chopping changes an untouched neighbouring tree")
            index += 1
        elif child.get_script() == RESOURCE:
            promoted = child
    if promoted == null or promoted.cuts != 1 or promoted.global_position.distance_to(Vector3(tree_world.x, WorldData.elevation_at(tree_world), tree_world.y)) > 0.01:
        failures.append("Actual start-region tree promotion loses contact, transform or damage")
    cell.free()
    cell = Node3D.new()
    cell.set_meta("visual_batches", {})
    add_child(cell)
    forest.call("_spawn_physical_tree", cell, scene, tree_world, 0.9, 0.7, 0)
    if cell.get_child_count() != 1 or cell.get_child(0).get_script() != RESOURCE or cell.get_child(0).cuts != 1:
        failures.append("Start-forest streaming restores a damaged tree as an untouched batch")
    cell.free()
    forest.free()
    var trader := preload("res://scripts/settlement_npc.gd").new()
    trader.role = "trader"
    trader.citizen_id = "axe_shop_fixture"
    GameState.set_world_value("shop:axe_shop_fixture", {"berries": 1})
    GameState.coins = 100
    if not trader.complete_trade("starter_axe", false) or not trader.complete_trade("starter_axe", false) or trader.complete_trade("starter_axe", false):
        failures.append("Axe shop migration or finite stock is broken")
    trader.free()
    # Release the owned world, then allow queued audio stops to drain.
    audio.queue_free()
    player.queue_free()
    await get_tree().create_timer(0.15, true).timeout
    if failures.is_empty():
        print("CHOPPING_OK physical_axe=true windup=true reach_rechecked=true cut_reload=true fall_animated=true save_during_fall=true finite_loot=true authored_stump=true axe_shop=true forest_batch=promoted neighbour=unchanged")
    for failure in failures:
        push_error(failure)
    get_tree().quit(0 if failures.is_empty() else 1)
