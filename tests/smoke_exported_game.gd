extends SceneTree

# Run this external harness against --main-pack, so res:// resolves exclusively
# to shipped resources rather than the working copy's source/import cache.
var _finished := false

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    if _finished:
        return
    _finished = true
    push_error("Exported gameplay smoke: " + message)
    quit(1)

func _wait_for(scene_name: String, seconds: float) -> Node:
    var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
    while Time.get_ticks_msec() < deadline:
        if current_scene != null and current_scene.name == scene_name:
            return current_scene
        await process_frame
    return null

func _run() -> void:
    for autoload_name in ["GameState", "SaveManager", "WorldData", "WorldWater", "MapSystem", "LandmarkVFX"]:
        var autoload := root.get_node_or_null(autoload_name)
        if autoload == null or autoload.get_script() == null:
            _fail("Required packaged autoload failed: " + autoload_name)
            return
    var packed := load("res://scenes/boot_launcher.tscn") as PackedScene
    if packed == null:
        _fail("Boot scene is absent from the package")
        return
    root.add_child(packed.instantiate())
    var menu := await _wait_for("MainMenu", 15.0)
    if menu == null:
        _fail("Packaged main menu did not open")
        return
    var music := menu.get_node_or_null("MenuMusic") as AudioStreamPlayer
    if music == null or music.stream == null or not music.playing:
        _fail("Production menu music is absent or not playing in the package")
        return
    menu.call("_new_game")
    if await _wait_for("WorldLoading", 8.0) == null:
        _fail("Packaged new game bypassed the loading screen")
        return
    var world := await _wait_for("Bootstrap", 35.0)
    if world == null:
        _fail("Packaged world did not become playable")
        return
    var player := world.get_node_or_null("World/Player") as CharacterBody3D
    if player == null:
        _fail("Packaged player is missing")
        return
    var human := player.get_node_or_null("Avatar/HumanModel")
    if human == null or human.find_children("*", "Skeleton3D", true, false).is_empty():
        _fail("Packaged human skeleton or model is missing")
        return
    if human.scene_file_path != "res://assets/production/characters/citizen/citizen.glb":
        _fail("Package does not contain the selected adult human")
        return
    var anatomical := human.find_child("AnatomicalHuman", true, false) as MeshInstance3D
    if anatomical == null or anatomical.skin == null:
        _fail("Packaged human lost its anatomical skinned mesh")
        return
    for resource_path in [
        "res://assets/production/nature/temperate/TemperateTree_Broad.glb",
        "res://assets/production/medieval/quaternius_city_core/Prop_Chimney.gltf",
        "res://assets/production/medieval/capital_square/Bench.gltf",
        "res://assets/production/medieval/capital_square/Lantern_Wall.gltf",
        "res://assets/production/medieval/capital_square/Workbench.gltf",
        "res://assets/production/medieval/capital_square/Barrel.gltf",
        "res://assets/production/medieval/capital_square/Barrel_Apples.gltf"
    ]:
        var selected := load(resource_path) as PackedScene
        if selected == null:
            _fail("Missing selected production scene: " + resource_path)
            return
        var instance := selected.instantiate()
        if instance.find_children("*", "MeshInstance3D", true, false).is_empty():
            instance.free()
            _fail("Selected production scene has no authored mesh: " + resource_path)
            return
        instance.free()
    var paving := load("res://assets/production/materials/ground/stone_paving.jpg") as Texture2D
    if paving == null or paving.get_image() == null or not paving.get_image().has_mipmaps():
        _fail("Packaged capital stone photograph or its mipmaps are missing")
        return
    var camera_rig := player.get_node("CameraPivot")
    if camera_rig.get_script().resource_path != "res://scripts/third_person_camera.gd":
        _fail("Packaged third-person obstruction camera is missing")
        return
    var settings := root.get_node("SettingsManager")
    settings.call("set_camera_distance", 9.0)
    for frame in range(3):
        await physics_frame
    if float(camera_rig.get("desired_distance")) != 9.0:
        _fail("Packaged zoom does not reach the gameplay camera")
        return
    settings.call("set_camera_distance", 5.5)
    var human_animations := player.get_node("Avatar").get("animation_player") as AnimationPlayer
    if human_animations == null or not human_animations.has_animation("Walk") or not human_animations.has_animation("Airborne") or not human_animations.has_animation("Axe_Chop"):
        _fail("Packaged human movement animations are missing")
        return
    var tree_script := load("res://scripts/streamed_resource.gd") as Script
    var tree_probe := tree_script.new() as Node3D
    tree_probe.call("configure", "package_tree_probe", "wood", 6)
    world.add_child(tree_probe)
    if not tree_probe.has_method("receive_melee_hit") or tree_probe.get_node_or_null("AuthoredStump") == null or tree_probe.get_node_or_null("AuthoredFallenLog") == null:
        _fail("Packaged axe harvesting or authored stump/log assets are missing")
        return
    tree_probe.free()
    for _i in range(20):
        await physics_frame
    var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 2.0, player.global_position + Vector3.DOWN * 4.0)
    query.exclude = [player.get_rid()]
    query.collision_mask = 1
    if player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
        _fail("No packaged physical ground below the player")
        return
    var terrain_streamer := world.get_node("World/WorldStreamer")
    var chunks: Dictionary = terrain_streamer.get("loaded_chunks")
    if chunks.is_empty():
        _fail("Packaged terrain has no visible chunks")
        return
    for chunk in chunks.values():
        var terrain := chunk.get_node("Terrain") as MeshInstance3D
        var normals: PackedVector3Array = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
        if normals.is_empty() or normals[0].y <= 0.0:
            _fail("Packaged terrain faces downward and is invisible from above")
            return
    var region := world.get_node_or_null("World/StartRegion")
    if region == null or int(region.get("real_tree_count")) < 12:
        _fail("Production nature models are missing from the package")
        return
    var nature_batches := region.get_node("RealNatureDetails").find_children("*", "MultiMeshInstance3D", true, false)
    if nature_batches.is_empty():
        _fail("Packaged woodland has counters but no rendered production meshes")
        return
    var before := player.global_position
    Input.action_press("move_forward", 1.0)
    for _i in range(45):
        await physics_frame
    Input.action_release("move_forward")
    if Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length() < 0.75:
        _fail("Packaged movement did not move the player")
        return
    var state := root.get_node("GameState")
    var inventory := root.get_node("InventorySystem")
    state.call("add_item", "short_bow", 1)
    state.call("add_item", "arrow", 2)
    inventory.call("equip", "short_bow")
    var weapon := player.get_node("Avatar").get("held_weapon") as Node3D
    if weapon == null or String(weapon.get_meta("item_id", "")) != "short_bow":
        _fail("Packaged equipped bow model is missing")
        return
    player.call("_try_attack")
    var inventory_data: Dictionary = state.get("inventory")
    if int(inventory_data.get("arrow", 0)) != 1 or get_nodes_in_group("weapon_projectile").is_empty():
        _fail("Packaged bow did not launch its authored arrow and consume ammo")
        return
    inventory.call("unequip", "weapon")
    if player.get_node("Avatar").get("held_weapon") != null:
        _fail("Packaged unequip left a weapon attached")
        return
    var pause_menu := world.get_node_or_null("UI/GameMenu") as Control
    if pause_menu == null:
        _fail("Packaged pause menu is missing")
        return
    pause_menu.call("open_menu", "saves")
    if not paused or not pause_menu.visible:
        _fail("Packaged pause menu did not pause gameplay")
        return
    pause_menu.call("close_menu")
    _send_key(KEY_I)
    for _i in range(3):
        await process_frame
    var panels := world.get_node("UI/GameplayPanels") as Control
    if not paused or not panels.visible:
        _fail("Packaged inventory shortcut did not open the panel")
        return
    _send_key(KEY_ESCAPE)
    for _i in range(3):
        await process_frame
    if paused or panels.visible or pause_menu.visible:
        _fail("Packaged Escape did not return directly from inventory to gameplay")
        return
    # Probe the actual seven-choice merchant layout from shipped UI code.
    var merchant := (load("res://scripts/settlement_npc.gd") as GDScript).new() as CharacterBody3D
    merchant.call("configure", "Марта", "trader", 1, [])
    world.get_node("World").add_child(merchant)
    merchant.call("_open_shop")
    for frame in range(6):
        await process_frame
    var dialogue := world.get_node("UI/DialogueUI") as Control
    var dialogue_panel := dialogue.get("box") as PanelContainer
    if not root.get_visible_rect().grow(0.5).encloses(dialogue_panel.get_global_rect()):
        _fail("Packaged merchant dialogue extends beyond the screen")
        return
    var choices := dialogue.get("options_box") as VBoxContainer
    var dialogue_scroll := dialogue.get("content_scroll") as ScrollContainer
    if choices.get_child_count() != 7 or dialogue_scroll == null:
        _fail("Packaged merchant choices or bounded scrolling are missing")
        return
    dialogue_scroll.scroll_vertical = int(dialogue_scroll.get_v_scroll_bar().max_value)
    for frame in range(3):
        await process_frame
    var close_choice := choices.get_child(choices.get_child_count() - 1) as Button
    if not root.get_visible_rect().grow(0.5).encloses(close_choice.get_global_rect()):
        _fail("Packaged merchant close option is clipped")
        return
    close_choice.emit_signal("pressed")
    for frame in range(3):
        await process_frame
    if paused or dialogue.visible:
        _fail("Packaged merchant close button did not resume gameplay")
        return
    merchant.free()
    var saves := root.get_node("SaveManager")
    var first_slot := int(saves.get("current_slot"))
    var newer_slot := int(saves.call("first_free_slot"))
    if newer_slot <= 0 or not bool(saves.call("save_game", player, newer_slot)):
        _fail("Unable to create an isolated second save for Continue validation")
        return
    var future_base := int(Time.get_unix_time_from_system()) + 1000
    var original_files: Dictionary = {}
    for slot: int in [first_slot, newer_slot]:
        var path := String(saves.call("_slot_path", slot))
        var original := FileAccess.get_file_as_string(path)
        original_files[path] = original
        var payload: Dictionary = JSON.parse_string(original)
        payload["saved_at_unix"] = future_base + (100 if slot == newer_slot else 0)
        var file := FileAccess.open(path, FileAccess.WRITE)
        file.store_string(JSON.stringify(payload))
        file.close()
    var menu_probe: Control = (load("res://scripts/startup_menu.gd") as GDScript).new()
    var latest_slot := int(menu_probe.call("latest_save_slot"))
    menu_probe.free()
    for path: String in original_files:
        var file := FileAccess.open(path, FileAccess.WRITE)
        file.store_string(original_files[path])
        file.close()
    if latest_slot != newer_slot:
        _fail("Packaged Continue selected the first save instead of the newest one")
        return
    world.queue_free()
    await create_timer(0.1).timeout
    _finished = true
    print("EXPORTED_GAME_SMOKE_OK boot=ok music=ok loading=ok terrain=physical nature=production movement=ok pause=ok input_navigation=ok continue=latest")
    quit(0)

func _send_key(code: Key) -> void:
    var press := InputEventKey.new()
    press.physical_keycode = code
    press.pressed = true
    Input.parse_input_event(press)
    var release := InputEventKey.new()
    release.physical_keycode = code
    release.pressed = false
    Input.parse_input_event(release)
