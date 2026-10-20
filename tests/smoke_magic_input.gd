extends Node3D

var casts := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(60.0, true, false, true).timeout.connect(func(): get_tree().quit(99))
    call_deferred("_run")

func _run() -> void:
    assert(DisplayServer.get_name() != "headless", "Requires graphical display")
    GameState.reset_new_game()
    SettingsManager.set_value("graphics", "ui_scale", 1.0)
    SettingsManager.set_value("gameplay", "compatible_mouse", true)
    var stage := preload("res://scenes/stage1.tscn").instantiate()
    stage.set_script(null)
    var player := stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    player.owner = null
    var world := stage.get_node("World")
    stage.remove_child(world)
    world.free()
    stage.add_child(player)
    add_child(stage)
    player.set_physics_process(false)
    MagicSystem.spell_cast.connect(func(_id: String): casts += 1)
    for frame in range(4):
        await get_tree().process_frame
    var hud := get_node("/root/MagicHUD")
    assert(hud.root.visible)
    for point in [Vector2(950, 520), hud.mana_bar.get_global_rect().get_center(), hud.spell_label.get_global_rect().get_center()]:
        _prepare()
        var before := casts
        print("MAGIC_MOUSE_BEGIN ", point, " paused=", get_tree().paused, " dead=", GameState.is_dead)
        await _click(point)
        print("MAGIC_MOUSE_POINT ", point, " casts=", casts - before)
        assert(casts == before + 1, "HUD consumes right-click spell input")
    _prepare()
    var before := casts
    var menu := stage.get_node("UI/GameMenu")
    menu.open_menu("main")
    await _click(hud.mana_bar.get_global_rect().get_center())
    assert(casts == before and is_equal_approx(GameState.mana, 100.0), "Paused menu allows casting")
    menu.close_menu()
    _prepare()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await _click(Vector2(950, 520))
    assert(casts == before and SettingsManager.is_gameplay_mouse_captured(), "Recapture click casts a spell")
    await _click(Vector2(950, 520))
    assert(casts == before + 1, "Second click after recapture does not cast")
    _prepare()
    before = casts
    var action := InputEventAction.new()
    action.action = "cast_magic"
    action.pressed = true
    Input.parse_input_event(action)
    await get_tree().process_frame
    var release := InputEventAction.new()
    release.action = "cast_magic"
    Input.parse_input_event(release)
    await get_tree().process_frame
    assert(casts == before + 1, "Action-event cast fails")
    GameState.stamina = 100.0
    await _click(hud.mana_bar.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
    assert(player.attack_elapsed > 0.0 and GameState.stamina < 100.0, "HUD consumes melee attack input")
    print("MAGIC_INPUT_OK mouse_points=3 action=true pause=blocked recapture=safe attack=true")
    get_tree().quit(0)

func _prepare() -> void:
    MagicSystem.selected_spell_id()
    MagicSystem.selected_index = MagicSystem.SPELL_ORDER.find("heal")
    MagicSystem.cooldowns.clear()
    GameState.health = 45.0
    GameState.mana = 100.0
    SettingsManager.capture_gameplay_mouse()

func _click(point: Vector2, button: int = MOUSE_BUTTON_RIGHT) -> void:
    var press := InputEventMouseButton.new()
    press.button_index = button
    press.pressed = true
    press.position = point
    press.global_position = point
    Input.parse_input_event(press)
    await get_tree().process_frame
    var release := InputEventMouseButton.new()
    release.button_index = button
    release.position = point
    release.global_position = point
    Input.parse_input_event(release)
    await get_tree().process_frame
