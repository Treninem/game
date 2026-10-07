extends Node3D

var failed := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    push_error("Magic runtime smoke failed: %s" % message)
    get_tree().quit(code)

func _check(condition: bool, code: int, message: String) -> bool:
    if condition:
        return true
    _fail(code, message)
    return false

func _run_test() -> void:
    GameState.reset_new_game()
    GameState.health = 20.0
    GameState.mana = GameState.max_mana
    GameState.magic_shield = 0.0
    GameState.is_dead = false
    MagicSystem.cooldowns.clear()

    var hud := get_node_or_null("/root/MagicHUD")
    if not _check(hud != null, 2, "MagicHUD autoload is missing"):
        return
    if not _check(hud is CanvasLayer, 3, "MagicHUD is not a CanvasLayer"):
        return

    var caster := CharacterBody3D.new()
    caster.name = "MagicSmokeCaster"
    caster.add_to_group("player")
    add_child(caster)

    var camera := Camera3D.new()
    camera.name = "Camera3D"
    caster.add_child(camera)
    camera.current = true

    await get_tree().process_frame
    await get_tree().process_frame

    if not _check(is_instance_valid(hud.root), 4, "MagicHUD did not build its root panel"):
        return
    if not _check(hud.root.visible, 5, "MagicHUD stays hidden while a player is present"):
        return

    var heal_index := MagicSystem.SPELL_ORDER.find("heal")
    if not _check(heal_index >= 0, 6, "heal spell is missing from spell order"):
        return
    MagicSystem.selected_index = heal_index
    MagicSystem._announce_selection()
    await get_tree().process_frame

    if not _check(MagicSystem.selected_spell_id() == "heal", 7, "spell selection did not switch to heal"):
        return
    if not _check(hud.spell_label != null and hud.spell_label.text.contains("Лечение"), 8, "MagicHUD did not reflect selected heal spell"):
        return

    var mana_before := GameState.mana
    if not _check(MagicSystem.cast_selected(caster, camera), 9, "heal cast failed"):
        return
    if not _check(GameState.health > 20.0, 10, "heal cast did not restore health"):
        return
    if not _check(GameState.mana < mana_before, 11, "heal cast did not consume mana"):
        return
    if not _check(MagicSystem.cooldown_left("heal") > 0.0, 12, "heal cast did not start cooldown"):
        return

    var shield_index := MagicSystem.SPELL_ORDER.find("shield")
    if not _check(shield_index >= 0, 13, "shield spell is missing from spell order"):
        return
    MagicSystem.selected_index = shield_index
    MagicSystem._announce_selection()
    MagicSystem.cooldowns.erase("shield")
    var shield_mana_before := GameState.mana
    if not _check(MagicSystem.cast_selected(caster, camera), 14, "shield cast failed"):
        return
    if not _check(GameState.magic_shield > 0.0, 15, "shield cast did not create magic shield"):
        return
    if not _check(GameState.mana < shield_mana_before, 16, "shield cast did not consume mana"):
        return

    if not _check(InputMap.has_action("cast_magic") and InputMap.has_action("next_spell"), 17, "magic input actions are missing"):
        return

    print("MAGIC_RUNTIME_SMOKE_OK hud=visible selection=heal casts=heal+shield mana=cooldown inputs=present")
    get_tree().quit(0)
