extends Node

const APPEARANCE := preload("res://scripts/character_appearance.gd")
var failed := false

func _ready() -> void:
    get_tree().create_timer(90).timeout.connect(func(): get_tree().quit(1))
    call_deferred("_run")

func _check(value: bool, message: String) -> bool:
    if value:
        return true
    failed = true
    push_error("Character acceptance: " + message)
    get_tree().quit(1)
    return false

func _run() -> void:
    var legacy := APPEARANCE.preset(0)
    legacy.erase("eye_color")
    legacy.erase("height_cm")
    legacy.erase("HeadSize")
    if not _check(APPEARANCE.normalized(legacy).height_cm == 180.0 and APPEARANCE.normalized({"height_cm": -999}).height_cm == 160.0 and APPEARANCE.normalized({"height_cm": INF}).height_cm == 180.0, "Height lacks bounded input and legacy defaults"):
        return
    if not _check(APPEARANCE.normalized(legacy).eye_color == 0 and APPEARANCE.normalized({"eye_color": 999}).eye_color == 4 and APPEARANCE.normalized({"eye_color": INF}).eye_color == 0, "Eye choice lacks legacy defaults or bounded input"):
        return
    if not _check(APPEARANCE.normalized(legacy).HeadSize == 0.0 and APPEARANCE.normalized({"HeadSize": 999}).HeadSize == 0.5 and APPEARANCE.normalized({"HeadSize": NAN}).HeadSize == 0.0, "Head size lacks bounded legacy defaults"):
        return
    var bad := APPEARANCE.normalized({"name": "\n", "sex": "../bad", "Build": NAN, "hair": INF, "Nose": 9000, "skin": -99})
    if not _check(bad.sex == "male" and is_finite(bad.Build) and bad.Nose == 0.5 and bad.skin == 0 and not String(bad.name).is_empty(), "Malformed profile was not normalized"):
        return
    var creator := preload("res://scenes/character_creator.tscn").instantiate()
    add_child(creator)
    await get_tree().process_frame
    await get_tree().process_frame
    var start_button := creator.find_child("StartJourney", true, false) as Button
    if not _check(start_button != null and start_button.get_global_rect().end.y <= get_viewport().get_visible_rect().end.y, "Start button is clipped below the window"):
        return
    var advanced := creator.find_child("AdvancedAppearance", true, false) as CheckButton
    if not _check(advanced != null and creator.find_child("FaceHeight", true, false) == null, "Simple mode is missing or exposes advanced controls"):
        return
    advanced.button_pressed = true
    var head_size := creator.find_child("HeadSize", true, false) as HSlider
    if not _check(head_size != null, "Head size slider missing from the actual face category"):
        return
    creator.set("zoom", 0.85)
    head_size.value = 0.35
    if not _check(absf(creator.camera.position.z) > 0.9, "Larger head lacks close-up camera clearance"):
        return
    var head_mesh := creator.visual.find_child("HumanBody", true, false) as MeshInstance3D
    if not _check(head_mesh != null and is_equal_approx(head_mesh.get_blend_shape_value(head_mesh.find_blend_shape_by_name("HeadSize")), 0.35), "Head size slider does not reach actual geometry"):
        return
    var face_height := creator.find_child("FaceHeight", true, false) as HSlider
    if not _check(face_height != null, "Advanced mode did not reveal actual facial controls"):
        return
    face_height.value = 0.3
    var reset_line := face_height.get_parent().get_child(face_height.get_index() - 1)
    (reset_line.get_child(1) as Button).pressed.emit()
    if not _check(is_zero_approx(float(creator.profile.FaceHeight)), "Individual shape reset did not change the real profile"):
        return
    face_height.value = 0.3
    face_height.drag_started.emit()
    if not _check(is_equal_approx(creator.zoom, 0.85), "Facial editing does not frame the face"):
        return
    creator.call("select_trait_category", "appearance")
    if not _check(creator.find_child("hair", true, false) != null and creator.find_child("FaceHeight", true, false) == null, "Appearance category mixes unrelated controls"):
        return
    creator.call("select_trait_category", "body")
    if not _check(creator.find_child("Build", true, false) != null, "Body category has no functioning body control"):
        return
    var height_slider := creator.find_child("height_cm", true, false) as HSlider
    if not _check(height_slider != null, "Body category has no physical height control"):
        return
    height_slider.value = 195.0
    if not _check(is_equal_approx(creator.visual.scale.y, 195.0 / 180.0), "Height slider does not resize the actual avatar"):
        return
    creator.call("select_trait_category", "face")
    advanced.button_pressed = false
    advanced.button_pressed = true
    if not _check(is_equal_approx(float((creator.find_child("FaceHeight", true, false) as HSlider).value), 0.3), "Category or mode change discarded a selected shape"):
        return
    var signatures := {}
    for i in range(10):
        creator.profile = APPEARANCE.preset(i)
        creator.call("_refresh")
        await get_tree().process_frame
        var visual = creator.visual
        signatures[JSON.stringify([creator.profile.sex, creator.profile.FaceWidth, creator.profile.Nose, creator.profile.Jaw, creator.profile.Build])] = true
        if not _check(visual.current_profile.sex == ("female" if i >= 5 else "male"), "Preset did not instantiate its selected body"):
            return
        var parts := {}
        for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
            parts[String(mesh.name)] = true
            for surface in range(mesh.mesh.get_surface_count()):
                var material := mesh.get_active_material(surface) as StandardMaterial3D
                if material == null:
                    continue
                if String(mesh.name) == "Clothing":
                    if not _check(material.normal_enabled and material.normal_texture != null and material.albedo_texture != null and material.roughness >= 0.8, "Garment lost authored matte fold/detail maps"):
                        return
                elif String(mesh.name) == "Boots":
                    if not _check(material.albedo_texture != null, "Boot leather is flat-colored again"):
                        return
            for shape: String in APPEARANCE.SHAPES:
                var shape_index := mesh.find_blend_shape_by_name(shape)
                if not _check(shape_index >= 0, "Missing synchronized morph: " + String(mesh.name) + "/" + shape):
                    return
        if not _check(parts.has("HumanBody") and parts.has("Clothing") and parts.has("Boots") and parts.has("Eyes") and parts.has("Brows"), "Missing physical human/garment parts"):
            return
        for clip in ["Idle", "Walk", "Run", "Jump", "Punch", "Working", "Death", "Axe_Chop", "Bow_Attack_Shoot", "Bow_Attack_Draw", "Sitting"]:
            if not _check(visual.animation_player.has_animation(clip), "Missing actual character clip " + clip):
                return
    if not _check(signatures.size() == 10, "Ten presets only duplicate the same anatomy"):
        return
    for body_index in [0, 5]:
        creator.call("select_preset", body_index)
        creator.call("select_trait_category", "appearance")
        var eye_choice := creator.find_child("eye_color", true, false) as OptionButton
        if not _check(eye_choice != null and eye_choice.item_count == 5, "Eye choices are missing from the actual editor"):
            return
        var garment := creator.visual.find_child("Clothing", true, false) as MeshInstance3D
        var garment_material := garment.get_active_material(0)
        for color_index in range(5):
            eye_choice.select(color_index)
            eye_choice.item_selected.emit(color_index)
            var eyes := creator.visual.find_child("Eyes", true, false) as MeshInstance3D
            var material := eyes.get_active_material(0) as StandardMaterial3D
            if not _check(material.albedo_texture == preload("res://scripts/humanoid_visual.gd").EYE_TEXTURES[color_index] and creator.profile.eye_color == color_index, "Eye selection did not reach the physical eye material"):
                return
            if not _check(garment.get_active_material(0) == garment_material, "Changing eyes recreated unrelated garment materials"):
                return
        var cache_before: int = preload("res://scripts/humanoid_visual.gd").palette_materials.size()
        for repeat in range(30):
            eye_choice.item_selected.emit(repeat % 5)
        if not _check(preload("res://scripts/humanoid_visual.gd").palette_materials.size() == cache_before, "Repeated eye selection grows material cache"):
            return
    creator.call("select_trait_category", "face")
    var inventory_before := GameState.snapshot()
    var equipped_before := InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    for preset_index in [0, 5]:
        creator.call("select_preset", preset_index)
        for motion in [4, 5, 6]:
            creator.call("select_preview_motion", motion)
            await get_tree().process_frame
            var weapon: Node3D = creator.visual.held_weapon
            if not _check(is_instance_valid(weapon) and creator.visual.held_item == ("starter_axe" if motion == 4 else "short_bow"), "Combat preview has empty hands"):
                return
            if motion == 5:
                creator.visual.animation_player.play("Bow_Attack_Draw")
                creator.visual.animation_player.advance(0.6)
                var skeleton := creator.visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
                skeleton.force_update_all_bone_transforms()
                var shoulder: Vector3 = creator.visual.to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("LeftArm")).origin)
                var wrist: Vector3 = creator.visual.to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("LeftHand")).origin)
                if not _check(wrist.z < shoulder.z - 0.35 and absf(wrist.y - shoulder.y) < 0.2, "Bow arm folds behind the back instead of aiming forward"):
                    return
            creator.call("select_preset", 5 if preset_index == 0 else 0)
            if not _check(is_instance_valid(creator.visual.held_weapon), "Changing body loses preview equipment"):
                return
        creator.call("select_preview_motion", 0)
        if not _check(creator.visual.held_weapon == null, "Returning to Idle leaves preview weapon visible"):
            return
    if not _check(GameState.snapshot() == inventory_before and InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) == equipped_before, "Preview modifies real game inventory or appearance state"):
        return
    creator.call("select_preview_motion", 5)
    await get_tree().process_frame
    var aiming_player: AnimationPlayer = creator.visual.animation_player
    var local_library := aiming_player.get_animation_library("")
    var neighbor := CharacterBody3D.new()
    neighbor.name = "StreamedNeighborFixture"
    add_child(neighbor)
    var neighbor_visual := preload("res://scripts/humanoid_visual.gd").new()
    neighbor_visual.appearance_profile = creator.profile.duplicate(true)
    neighbor.add_child(neighbor_visual)
    if not _check(neighbor_visual.animation_player.get_animation_library("") != local_library and aiming_player.is_playing(), "Spawning another human shares/replaces the active actor animation library"):
        return
    neighbor.queue_free()
    creator.call("select_preview_motion", 0)
    creator.name_edit.text = "Ð­Ð»Ð¸Ð½Ð°"
    creator.call("select_preset", 8)
    if not _check(creator.name_edit.text == "Ð­Ð»Ð¸Ð½Ð°", "Selecting a new appearance erased the entered name"):
        return
    var visual = creator.visual
    var before: int = preload("res://scripts/humanoid_visual.gd").palette_materials.size()
    for i in range(60):
        creator.profile.FaceWidth = -0.5 + float(i) / 59.0
        creator.call("_apply_preview")
    if not _check(preload("res://scripts/humanoid_visual.gd").palette_materials.size() == before, "Dragging morph sliders grows the shared material cache"):
        return
    creator.profile.name = "ÐŸÑ€Ð¾Ð²ÐµÑ€ÐºÐ° Ð¾Ð±Ñ€Ð°Ð·Ð°"
    for key: String in ["HeadSize", "FaceHeight", "FaceDepth", "NoseWidth", "NoseHeight"]:
        creator.profile[key] = 0.27
    creator.profile.eye_color = 4
    creator.profile.height_cm = 193.0
    var expected := APPEARANCE.normalized(creator.profile)
    if not _check(APPEARANCE.save_look(expected) == OK and APPEARANCE.load_look() == expected, "Saved look did not round-trip"):
        return
    GameState.reset_new_game()
    GameState.set_world_value("player_appearance", expected)
    var player := Node3D.new()
    player.position = Vector3(4, 2, 6)
    add_child(player)
    if not _check(SaveManager.save_game(player, 10), "Could not save a character profile with its game slot"):
        return
    GameState.set_world_value("player_appearance", APPEARANCE.preset(0))
    if not _check(SaveManager.load_game(player, 10) and APPEARANCE.normalized(GameState.get_world_value("player_appearance")) == expected, "Game load lost selected sex, shape or clothing"):
        return
    SaveManager.prepare_new_game(2, expected)
    if not _check(SaveManager.consume_new_game_request() and SaveManager.consume_character_profile() == expected, "Creator-to-bootstrap handoff changed the appearance"):
        return
    GameState.load_snapshot({"world_state": {}})
    if not _check(APPEARANCE.normalized(GameState.get_world_value("player_appearance")) == APPEARANCE.preset(0), "Legacy save has no safe appearance default"):
        return
    print("CHARACTER_CREATOR_OK presets=10 geometry=male+female clothes=separate morphs=9 clips=10 library=roundtrip save=roundtrip cache=bounded legacy=default")
    get_tree().quit(0)
