extends Node3D
var failures: Array[String] = []
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")
func _run() -> void:
    MagicSystem.set_process(false)
    GameState.reset_new_game()
    MagicSystem.selected_spell_id()
    for index in range(4):
        MagicSystem.select_next()
    var caster := CharacterBody3D.new()
    add_child(caster)
    var camera := Camera3D.new()
    caster.add_child(camera)
    GameState.health = 30.0
    if not MagicSystem.cast_selected(caster, camera):
        push_error("Initial real healing cast failed")
        get_tree().quit(1)
        return
    MagicSystem._process(0.75)
    var expected := MagicSystem.cooldown_left("heal")
    if not SaveManager.save_game(caster, 10):
        failures.append("Could not save magic fixture")
    MagicSystem.select_next()
    MagicSystem._process(10.0)
    if not SaveManager.load_game(caster, 10):
        failures.append("Could not reload magic fixture")
    if MagicSystem.selected_spell_id() != "heal":
        failures.append("Save load loses the selected spell")
    if not is_equal_approx(MagicSystem.cooldown_left("heal"), expected):
        failures.append("Save load loses the remaining spell cooldown")
    var mana_before := GameState.mana
    if MagicSystem.cast_selected(caster, camera) or not is_equal_approx(GameState.mana, mana_before):
        failures.append("Reload permits a cooldown bypass or spends blocked-cast mana")
    MagicSystem.set_process(true)
    var paused_left := MagicSystem.cooldown_left("heal")
    get_tree().paused = true
    for frame in range(4):
        await get_tree().process_frame
    if not is_equal_approx(MagicSystem.cooldown_left("heal"), paused_left):
        failures.append("Spell cooldown advances during pause")
    get_tree().paused = false
    MagicSystem.set_process(false)
    GameState.reset_new_game()
    if MagicSystem.selected_spell_id() != "fireball" or MagicSystem.cooldown_left("shield") > 0 or MagicSystem.cooldown_left("heal") > 0:
        failures.append("New Game inherits the previous spell or cooldown")
    GameState.load_snapshot({"world_state":{"magic_runtime_v1":{"selected_spell":"invalid","cooldowns":{"heal":INF,"shield":-4,"blink":999,"fireball":"bad","unknown":5}}}})
    if MagicSystem.selected_spell_id() != "fireball" or MagicSystem.cooldown_left("heal") != 0 or MagicSystem.cooldown_left("shield") != 0 or MagicSystem.cooldown_left("blink") > 3.5 or MagicSystem.cooldown_left("unknown") != 0:
        failures.append("Malformed saved magic state is not bounded")
    GameState.load_snapshot({"world_state":{}})
    if MagicSystem.selected_spell_id() != "fireball" or not MagicSystem.cooldowns.is_empty():
        failures.append("Legacy save lacks clean magic defaults")
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("MAGIC_STATE_OK cast=real save=roundtrip cooldown=remaining pause=frozen reset=clean legacy=default invalid=bounded")
    get_tree().quit(0 if failures.is_empty() else 1)
