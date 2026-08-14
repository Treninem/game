extends Control

const ACTION_LABELS := {
    "move_forward": "Движение вперёд",
    "move_back": "Движение назад",
    "move_left": "Движение влево",
    "move_right": "Движение вправо",
    "sprint": "Бег",
    "jump": "Прыжок",
    "interact": "Взаимодействие",
    "attack": "Атака",
    "use_food": "Быстрая еда",
    "use_water": "Быстрая вода",
    "open_inventory": "Инвентарь",
    "open_map": "Карта",
    "open_journal": "Журнал",
    "open_crafting": "Крафт",
    "quick_save": "Быстрое сохранение",
    "quick_load": "Быстрая загрузка",
    "pause_menu": "Пауза"
}

var content: VBoxContainer
var title_label: Label
var update_status: Label
var apply_update_button: Button
var awaiting_action := ""
var rebinding_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_shell()
    UpdateManager.status_changed.connect(_on_update_status_changed)
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if not awaiting_action.is_empty():
        if event is InputEventKey or event is InputEventMouseButton:
            if SettingsManager.rebind_action(awaiting_action, event):
                awaiting_action = ""
                _show_controls()
                get_viewport().set_input_as_handled()
        return
    if DialogueManager.is_open:
        return
    if event.is_action_pressed("pause_menu"):
        var gameplay_panels := get_tree().get_first_node_in_group("gameplay_panels") as Control
        if gameplay_panels != null and gameplay_panels.visible:
            return
        if visible:
            close_menu()
        else:
            open_menu("main")
        get_viewport().set_input_as_handled()

func open_menu(section: String = "main") -> void:
    visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _show_section(section)

func close_menu() -> void:
    awaiting_action = ""
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_shell() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.005, 0.008, 0.014, 0.72)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    var frame := PanelContainer.new()
    frame.set_anchors_preset(Control.PRESET_CENTER)
    frame.position = Vector2(-330, -300)
    frame.custom_minimum_size = Vector2(660, 600)
    frame.add_theme_stylebox_override("panel", _panel_style())
    add_child(frame)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    frame.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)
    var top := HBoxContainer.new()
    root.add_child(top)
    title_label = Label.new()
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 28)
    top.add_child(title_label)
    var version := Label.new()
    version.text = String(ProjectSettings.get_setting("application/config/version", "dev"))
    version.modulate = Color(0.48, 0.58, 0.68)
    top.add_child(version)
    root.add_child(HSeparator.new())

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    scroll.add_child(content)

func _show_section(section: String) -> void:
    _clear_content()
    match section:
        "saves": _show_saves()
        "settings": _show_settings()
        "controls": _show_controls()
        "graphics": _show_graphics()
        "audio": _show_audio()
        "other": _show_other()
        "updates": _show_updates()
        _: _show_main()

func _clear_content() -> void:
    awaiting_action = ""
    update_status = null
    apply_update_button = null
    for child in content.get_children():
        child.queue_free()

func _show_main() -> void:
    title_label.text = "Пауза"
    _info_card("Локация", GameState.current_location)
    _button("Продолжить игру", Callable(self, "close_menu"))
    _button("Сохранения — 10 слотов", Callable(self, "_show_section").bind("saves"))
    _button("Настройки", Callable(self, "_show_section").bind("settings"))
    _button("Проверка обновлений", Callable(self, "_show_section").bind("updates"))
    var hint := _body("I — инвентарь   M — карта   K — крафт   J — журнал. Эти экраны открываются прямо из игры и не являются пунктами паузы.")
    hint.modulate = Color(0.58, 0.68, 0.78)
    _button("Выйти из игры", Callable(get_tree(), "quit"), null, true)

func _show_saves() -> void:
    title_label.text = "Сохранения"
    _body("10 независимых слотов: создание, перезапись, загрузка и удаление.")
    for info in SaveManager.list_slots():
        var slot := int(info["slot"])
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _row_style())
        content.add_child(card)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        card.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.text = "Слот %02d\n%s   •   время мира %s" % [slot, String(info.get("saved_at", "пусто")) if bool(info.get("exists", false)) else "Пустой слот", String(info.get("world_time", "--:--"))]
        row.add_child(label)
        _button("Создать" if not bool(info.get("exists", false)) else "Сохранить", Callable(self, "_save_to_slot").bind(slot), row).custom_minimum_size.x = 92
        var load_button := _button("Загрузить", Callable(self, "_load_slot").bind(slot), row)
        load_button.custom_minimum_size.x = 92
        load_button.disabled = not bool(info.get("exists", false))
        var delete_button := _button("Удалить", Callable(self, "_delete_slot").bind(slot), row, true)
        delete_button.custom_minimum_size.x = 84
        delete_button.disabled = not bool(info.get("exists", false))
    _button("← Назад", Callable(self, "_show_section").bind("main"))

func _save_to_slot(slot: int) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null and SaveManager.save_game(player, slot):
        GameState.notify("Сохранено в слот %02d." % slot)
    _show_saves()

func _load_slot(slot: int) -> void:
    if not SaveManager.prepare_load(slot):
        return
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    get_tree().reload_current_scene()

func _delete_slot(slot: int) -> void:
    SaveManager.delete_slot(slot)
    _show_saves()

func _show_settings() -> void:
    title_label.text = "Настройки"
    _button("Управление", Callable(self, "_show_section").bind("controls"))
    _button("Графика", Callable(self, "_show_section").bind("graphics"))
    _button("Звук", Callable(self, "_show_section").bind("audio"))
    _button("Игра и интерфейс", Callable(self, "_show_section").bind("other"))
    _button("Сбросить настройки", Callable(self, "_reset_settings"))
    _button("← Назад", Callable(self, "_show_section").bind("main"))

func _show_controls() -> void:
    title_label.text = "Управление"
    rebinding_label = _body("Нажмите действие, затем новую клавишу или кнопку мыши.")
    for action in ACTION_LABELS:
        var row := HBoxContainer.new()
        content.add_child(row)
        var label := Label.new()
        label.text = String(ACTION_LABELS[action])
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var key_button := _button(SettingsManager.binding_text(action), Callable(self, "_begin_rebind").bind(action), row)
        key_button.custom_minimum_size.x = 150
    _button("← Назад", Callable(self, "_show_section").bind("settings"))

func _begin_rebind(action: String) -> void:
    awaiting_action = action
    if is_instance_valid(rebinding_label):
        rebinding_label.text = "Нажмите новую кнопку для: %s" % String(ACTION_LABELS.get(action, action))

func _show_graphics() -> void:
    title_label.text = "Графика"
    _add_checkbox("Полноэкранный режим", bool(SettingsManager.get_value("graphics", "fullscreen")), Callable(self, "_set_setting_bool").bind("graphics", "fullscreen"))
    _add_checkbox("VSync", bool(SettingsManager.get_value("graphics", "vsync")), Callable(self, "_set_setting_bool").bind("graphics", "vsync"))
    var resolutions := OptionButton.new()
    var options := [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080), Vector2i(2560,1440)]
    var current := Vector2i(int(SettingsManager.get_value("graphics", "resolution_width")), int(SettingsManager.get_value("graphics", "resolution_height")))
    for i in range(options.size()):
        var r: Vector2i = options[i]
        resolutions.add_item("%d × %d" % [r.x, r.y])
        resolutions.set_item_metadata(i, r)
        if r == current:
            resolutions.select(i)
    resolutions.item_selected.connect(Callable(self, "_set_resolution").bind(resolutions))
    content.add_child(resolutions)
    _add_slider("Масштаб 3D", float(SettingsManager.get_value("graphics", "render_scale")), 0.5, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "render_scale"))
    _add_slider("Масштаб интерфейса", float(SettingsManager.get_value("graphics", "ui_scale")), 0.75, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "ui_scale"))
    _button("← Назад", Callable(self, "_show_section").bind("settings"))

func _show_audio() -> void:
    title_label.text = "Звук"
    _add_slider("Общая громкость", float(SettingsManager.get_value("audio", "master_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "master_volume"))
    _add_slider("Музыка", float(SettingsManager.get_value("audio", "music_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "music_volume"))
    _add_slider("Эффекты", float(SettingsManager.get_value("audio", "sfx_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "sfx_volume"))
    _add_checkbox("Выключить весь звук", bool(SettingsManager.get_value("audio", "muted")), Callable(self, "_set_setting_bool").bind("audio", "muted"))
    _button("← Назад", Callable(self, "_show_section").bind("settings"))

func _show_other() -> void:
    title_label.text = "Игра и интерфейс"
    _add_slider("Чувствительность мыши", float(SettingsManager.get_value("gameplay", "mouse_sensitivity")), 0.001, 0.01, 0.0005, Callable(self, "_set_setting_float").bind("gameplay", "mouse_sensitivity"))
    _add_slider("Поле зрения", float(SettingsManager.get_value("gameplay", "camera_fov")), 60.0, 100.0, 1.0, Callable(self, "_set_setting_float").bind("gameplay", "camera_fov"))
    _add_slider("Автосохранение, сек.", float(SettingsManager.get_value("gameplay", "autosave_seconds")), 30.0, 300.0, 30.0, Callable(self, "_set_setting_float").bind("gameplay", "autosave_seconds"))
    _add_checkbox("Субтитры", bool(SettingsManager.get_value("gameplay", "subtitles")), Callable(self, "_set_setting_bool").bind("gameplay", "subtitles"))
    _button("← Назад", Callable(self, "_show_section").bind("settings"))

func _show_updates() -> void:
    title_label.text = "Обновления"
    _body("Если обновление не удалось, установленная версия продолжит запускаться.")
    _button("Проверить обновления", Callable(UpdateManager, "check_for_updates"))
    update_status = _body("Обновления ещё не проверялись.")
    apply_update_button = _button("Обновить и перезапустить", Callable(UpdateManager, "install_latest_update"))
    apply_update_button.visible = UpdateManager.update_available
    _button("← Назад", Callable(self, "_show_section").bind("main"))

func _button(text: String, callback: Callable, parent: Container = null, danger: bool = false) -> Button:
    var target: Container = content if parent == null else parent
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 42
    button.add_theme_font_size_override("font_size", 14)
    var bg := Color(0.055, 0.075, 0.105, 0.96) if not danger else Color(0.18, 0.055, 0.065, 0.96)
    var border := Color(0.16, 0.34, 0.50, 0.75) if not danger else Color(0.60, 0.18, 0.20, 0.78)
    button.add_theme_stylebox_override("normal", _button_style(bg, border))
    button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.08), border.lightened(0.18)))
    button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.08), border))
    button.pressed.connect(callback)
    target.add_child(button)
    return button

func _body(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.76, 0.82, 0.89)
    label.add_theme_font_size_override("font_size", 14)
    content.add_child(label)
    return label

func _info_card(title: String, text: String) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _row_style())
    content.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 13)
    margin.add_theme_constant_override("margin_right", 13)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    card.add_child(margin)
    var stack := VBoxContainer.new()
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = title
    heading.modulate = Color(0.48, 0.73, 0.91)
    heading.add_theme_font_size_override("font_size", 11)
    stack.add_child(heading)
    var body := Label.new()
    body.text = text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 15)
    stack.add_child(body)

func _add_checkbox(text: String, value: bool, callback: Callable) -> void:
    var box := CheckBox.new()
    box.text = text
    box.button_pressed = value
    box.toggled.connect(callback)
    content.add_child(box)

func _add_slider(text: String, value: float, min_value: float, max_value: float, step: float, callback: Callable) -> void:
    var row := HBoxContainer.new()
    content.add_child(row)
    var label := Label.new()
    label.text = text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)
    var slider := HSlider.new()
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.value = value
    slider.custom_minimum_size.x = 280
    slider.value_changed.connect(callback)
    row.add_child(slider)
    var value_label := Label.new()
    value_label.text = "%.2f" % value
    value_label.custom_minimum_size.x = 64
    row.add_child(value_label)
    slider.value_changed.connect(func(v: float): value_label.text = "%.2f" % v)

func _set_setting_bool(value: bool, section: String, key: String) -> void:
    SettingsManager.set_value(section, key, value)

func _set_setting_float(value: float, section: String, key: String) -> void:
    SettingsManager.set_value(section, key, value)

func _set_resolution(index: int, options: OptionButton) -> void:
    var resolution: Vector2i = options.get_item_metadata(index)
    SettingsManager.set_value("graphics", "resolution_width", resolution.x)
    SettingsManager.set_value("graphics", "resolution_height", resolution.y)

func _reset_settings() -> void:
    SettingsManager.reset_defaults()
    _show_settings()

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status):
        update_status.text = text
    if is_instance_valid(apply_update_button):
        apply_update_button.visible = available

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.017, 0.027, 0.985)
    style.border_color = Color(0.16, 0.42, 0.62, 0.88)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.shadow_color = Color(0, 0, 0, 0.40)
    style.shadow_size = 10
    return style

func _row_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.047, 0.066, 0.96)
    style.border_color = Color(0.10, 0.25, 0.36, 0.72)
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    style.content_margin_left = 12
    style.content_margin_right = 12
    return style
