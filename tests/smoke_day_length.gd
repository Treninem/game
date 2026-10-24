extends SceneTree
func _initialize()->void:call_deferred("_run")
func _run()->void:
    var settings:=root.get_node("SettingsManager");var state:=root.get_node("GameState");var saves:=root.get_node("SaveManager")
    var sensitivity:float=settings.get_value("gameplay","mouse_sensitivity")
    assert(absf(settings.world_minutes_per_second()-.5)<.00001,"Default48-minute day not applied")
    settings.set_value("gameplay","day_length_minutes",48.)
    settings.load_settings();assert(absf(settings.world_minutes_per_second()-.5)<.00001)
    state.reset_new_game();state.world_minutes=1430;state.world_day=7
    var hunger:float=state.hunger;var thirst:float=state.thirst
    state.advance_survival(40.)
    assert(state.world_day==8 and absf(state.world_minutes-10)<.0001,"World midnight rollover changed with configurable clock")
    assert(absf(state.hunger-(hunger-1))<.0001 and absf(state.thirst-(thirst-1.6))<.0001,"Clock option changed survival rates")
    var anchor:=Node3D.new();root.add_child(anchor);anchor.position=Vector3(20,.08,20)
    var inventory:Dictionary=state.inventory.duplicate(true);var coins:int=state.coins
    assert(saves.save_game(anchor,9));state.world_minutes=400;state.world_day=1
    assert(saves.load_game(anchor,9));assert(state.world_day==8 and absf(state.world_minutes-10)<.0001)
    assert(state.inventory==inventory and state.coins==coins)
    settings.set_value("gameplay","day_length_minutes",6.)
    assert(absf(settings.world_minutes_per_second()-4)<.0001,"Original fast clock option is unavailable")
    state.advance_survival(15.);assert(absf(state.world_minutes-70)<.0001)
    settings.set_value("gameplay","day_length_minutes",120.)
    assert(absf(settings.world_minutes_per_second()-.2)<.0001)
    for value:Variant in [INF,NAN,"fast",{},null]:
        settings.config.set_value("gameplay","day_length_minutes",value)
        assert(absf(settings.world_minutes_per_second()-.5)<.0001,"Invalid duration poisoned world time")
    settings.set_value("gameplay","day_length_minutes",48.);settings.load_settings()
    assert(absf(float(settings.get_value("gameplay","mouse_sensitivity"))-sensitivity)<.000001)
    assert(absf(settings.world_minutes_per_second()-.5)<.0001)
    # The real menu must accept malformed duration settings and use the same
    # safe value as the clock, rather than converting a Dictionary to float.
    var menu:Control=load("res://scripts/game_menu.gd").new();root.add_child(menu);menu.visible=true
    settings.config.set_value("gameplay","day_length_minutes",{})
    menu._show_section("other")
    var duration_slider:HSlider
    for label:Label in menu.find_children("*","Label",true,false):
        if label.text=="Сутки, реальных минут":duration_slider=label.get_parent().get_parent().get_child(1) as HSlider
    assert(duration_slider!=null and duration_slider.value==48 and duration_slider.min_value==6 and duration_slider.max_value==120)
    duration_slider.value=60;settings.load_settings()
    assert(settings.day_length_minutes()==60 and absf(settings.world_minutes_per_second()-.4)<.0001)
    settings.set_value("gameplay","day_length_minutes",48.)
    menu.free()
    print("DAY_LENGTH_OK default48min=true original6min_available=true max120min=true invalid_fallback=true saved_clock_day_inventory_money=true survival_rates_unchanged=true control_setting_preserved=true")
    anchor.free();quit(0)
