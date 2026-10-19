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
            if not _check(mesh.find_blend_shape_by_name("FaceWidth") >= 0, "Character part has no face/shape morph contract: " + String(mesh.name)):
                return
        if not _check(parts.has("HumanBody") and parts.has("Clothing") and parts.has("Boots") and parts.has("Eyes") and parts.has("Brows"), "Missing physical human/garment parts"):
            return
        for clip in ["Idle", "Walk", "Run", "Jump", "Punch", "Working", "Death", "Axe_Chop", "Bow_Attack_Shoot", "Bow_Attack_Draw", "Sitting"]:
            if not _check(visual.animation_player.has_animation(clip), "Missing actual character clip " + clip):
                return
    if not _check(signatures.size() == 10, "Ten presets only duplicate the same anatomy"):
        return
    creator.name_edit.text = "Элина"
    creator.call("select_preset", 8)
    if not _check(creator.name_edit.text == "Элина", "Selecting a new appearance erased the entered name"):
        return
    var visual = creator.visual
    var before: int = preload("res://scripts/humanoid_visual.gd").palette_materials.size()
    for i in range(60):
        creator.profile.FaceWidth = -0.5 + float(i) / 59.0
        creator.call("_apply_preview")
    if not _check(preload("res://scripts/humanoid_visual.gd").palette_materials.size() == before, "Dragging morph sliders grows the shared material cache"):
        return
    creator.profile.name = "Проверка образа"
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
    print("CHARACTER_CREATOR_OK presets=10 geometry=male+female clothes=separate morphs=4 clips=10 library=roundtrip save=roundtrip cache=bounded legacy=default")
    get_tree().quit(0)
