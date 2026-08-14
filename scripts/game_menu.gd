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

const NAV := [
    ["main", "Продолжить / пауза"],
    ["saves", "Сохранения"],
    ["settings", "Настройки"],
    ["controls", "Управление"],
    ["graphics", "Графика"],
    ["audio", "Звук"],
    ["other", "Игра и интерфейс"],
    ["updates", "Обновления"]
]

var frame: PanelContainer
var sidebar: VBoxContainer
var content: VBoxContainer
var title_label: Label
var update_status: Label
var apply_update_button: Button
var awaiting_action := ""
var rebinding_label: Label
var current_section := "main"
var nav_buttons: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_force_pass_scroll_events = false
    _build_shell()
    UpdateManager.status_changed.connect(_on_update_status_changed)
    resized.connect(_apply_responsive_layout)
    call_deferred("_apply_responsive_layout")
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if not awaiting_action.is_empty():
        if event is InputEventKey or event is InputEventMouseButton:
            if SettingsManager.rebind_action(awaiting_action, event):
                awaiting_action = ""
                _show_section("controls")
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
    current_section = section
    visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _apply_responsive_layout()
    _show_section(section)

func close_menu() -> void:
    awaiting_action = ""
    current_section = "main"
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_shell() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.004, 0.007, 0.012, 0.84)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(backdrop)

    var glow := ColorRect.new()
    glow.color = Color(0.02, 0.12, 0.20, 0.24)
    glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
    glow.offset_bottom = 110.0
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(glow)

    frame = PanelContainer.new()
    frame.add_theme_stylebox_override("panel", _panel_style())
    add_child(frame)

    var outer := MarginContainer.new()
    outer.add_theme_constant_override("margin_left", 18)
    outer.add_theme_constant_override("margin_right", 18)
    outer.add_theme_constant_override("margin_top", 18)
    outer.add_theme_constant_override("margin_bottom", 18)
    frame.add_child(outer)

    var split := HBoxContainer.new()
    split.add_theme_constant_override("separation", 18)
    outer.add_child(split)

    var side_panel := PanelContainer.new()
    side_panel.custom_minimum_size = Vector2(210, 0)
    side_panel.add_theme_stylebox_override("panel", _sidebar_style())
    split.add_child(side_panel)

    var side_margin := MarginContainer.new()
    side_margin.add_theme_constant_override("margin_left", 12)
    side_margin.add_theme_constant_override("margin_right", 12)
    side_margin.add_theme_constant_override("margin_top", 14)
    side_margin.add_theme_constant_override("margin_bottom", 14)
    side_panel.add_child(side_margin)

    sidebar = VBoxContainer.new()
    sidebar.add_theme_constant_override("separation", 7)
    side_margin.add_child(sidebar)

    var brand := Label.new()
    brand.text = "ImPuls"
    brand.add_theme_font_size_override("font_size", 30)
    brand.modulate = Color(0.72, 0.91, 1.0)
    sidebar.add_child(brand)

    var stage := Label.new()
    stage.text = "OFFLINE WORLD"
    stage.add_theme_font_size_override("font_size", 10)
    stage.modulate = Color(0.36, 0.58, 0.72)
    sidebar.add_child(stage)
    sidebar.add_child(HSeparator.new())

    for entry in NAV:
        var section := String(entry[0])
        var label := String(entry[1])
        var button := Button.new()
        button.text = label
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size.y = 40
        button.focus_mode = Control.FOCUS_ALL
        button.add_theme_font_size_override("font_size", 13)
        button.pressed.connect(Callable(self, "_nav_pressed").bind(section))
        sidebar.add_child(button)
        nav_buttons[section] = button

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sidebar.add_child(spacer)

    var close := Button.new()
    close.text = "Вернуться в игру"
    close.custom_minimum_size.y = 44
    close.add_theme_font_size_override("font_size", 14)
    close.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.16, 0.22, 0.98), Color(0.18, 0.62, 0.78, 0.92)))
    close.add_theme_stylebox_override("hover", _button_style(Color(0.055, 0.22, 0.30, 1.0), Color(0.30, 0.82, 1.0, 1.0)))
    close.pressed.connect(close_menu)
    sidebar.add_child(close)

    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_constant_override("separation", 10)
    split.add_child(right)

    var top := HBoxContainer.new()
    top.custom_minimum_size.y = 46
    right.add_child(top)
    title_label = Label.new()
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 27)
    top.add_child(title_label)
    var version := Label.new()
    version.text = String(ProjectSettings.get_setting("application/config/version", "dev"))
    version.modulate = Color(0.42, 0.58, 0.69)
    version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top.add_child(version)
    right.add_child(HSeparator.new())

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    scroll.mouse_force_pass_scroll_events = false
    right.add_child(scroll)

    var content_margin := MarginContainer.new()
    content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_margin.add_theme_constant_override("margin_right", 10)
    content_margin.add_theme_constant_override("margin_bottom", 10)
    scroll.add_child(content_margin)

    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    content_margin.add_child(content)

func _apply_responsive_layout() -> void:
    if not is_instance_valid(frame):
        return
    var viewport_size := size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        viewport_size = get_viewport_rect().size
    var target := Vector2(
        minf(1120.0, maxf(520.0, viewport_size.x - 32.0)),
        minf(760.0, maxf(380.0, viewport_size.y - 32.0))
    )
    if viewport_size.x < 760.0:
        target.x = maxf(320.0, viewport_size.x - 18.0)
    if viewport_size.y < 520.0:
        target.y = maxf(300.0, viewport_size.y - 18.0)
    frame.set_anchors_preset(Control.PRESET_CENTER)
    frame.size = target
    frame.position = -target * 0.5

    var compact := target.x < 760.0
    if is_instance_valid(sidebar) and sidebar.get_parent() != null and sidebar.get_parent().get_parent() is PanelContainer:
        var panel := sidebar.get_parent().get_parent() as PanelContainer
        panel.custom_minimum_size.x = 160.0 if compact else 210.0
    for section in nav_buttons:
        var button: Button = nav_buttons[section]
        button.add_theme_font_size_override("font_size", 11 if compact else 13)

func _nav_pressed(section: String) -> void:
    if section == "main" and current_section == "main":
        close_menu()
        return
    _show_section(section)

func _show_section(section: String) -> void:
    current_section = section
    _clear_content()
    _refresh_nav()
    match section:
        "saves": _show_saves()
        "settings": _show_settings()
        "controls": _show_controls()
        "graphics": _show_graphics()
        "audio": _show_audio()
        "other": _show_other()
        "updates": _show_updates()
        _: _show_main()

func _refresh_nav() -> void:
    for section in nav_buttons:
        var button: Button = nav_buttons[section]
        var selected := String(section) == current_section
        var bg := Color(0.055, 0.16, 0.23, 0.98) if selected else Color(0.025, 0.04, 0.06, 0.92)
        var border := Color(0.18, 0.68, 0.92, 0.96) if selected else Color(0.08, 0.18, 0.26, 0.70)
        button.add_theme_stylebox_override("normal", _button_style(bg, border))
        button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.07), border.lightened(0.12)))
        button.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0) if selected else Color(0.72, 0.78, 0.84))

func _clear_content() -> void:
    awaiting_action = ""
    update_status = null
    apply_update_button = null
    for child in content.get_children():
        child.queue_free()

func _show_main() -> void:
    title_label.text = "Пауза"
    _hero_card("Мир продолжается с вашего сохранения", GameState.current_location)
    _button("Продолжить игру", Callable(self, "close_menu"), null, false, true)
    _info_card("Текущее состояние", "Задания и строительство временно отложены. Сейчас приоритет — стабильный мир, столица, леса, поля, дороги, вода и регионы.")
    _body("Быстрые экраны: I — инвентарь   •   M — карта   •   K — крафт   •   J — журнал")
    _button("Сохранения", Callable(self, "_show_section").bind("saves"))
    _button("Настройки", Callable(self, "_show_section").bind("settings"))
    _button("Выйти из игры", Callable(get_tree(), "quit"), null, true)

func _show_saves() -> void:
    title_label.text = "Сохранения"
    _body("10 независимых слотов. Список прокручивается колёсиком мыши и автоматически удерживает выбранный элемент в видимой области.")
    for info in SaveManager.list_slots():
        var slot := int(info["slot"])
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _row_style())
        content.add_child(card)
        var margin := MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 12)
        margin.add_theme_constant_override("margin_right", 12)
        margin.add_theme_constant_override("margin_top", 9)
        margin.add_theme_constant_override("margin_bottom", 9)
        card.add_child(margin)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        margin.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "Слот %02d\n%s  •  %s" % [slot, String(info.get("location", "Пустой слот")) if bool(info.get("exists", false)) else "Пустой слот", String(info.get("world_time", "--:--"))]
        row.add_child(label)
        _button("Сохранить" if bool(info.get("exists", false)) else "Создать", Callable(self, "_save_to_slot").bind(slot), row).custom_minimum_size.x = 92
        var load_button := _button("Загрузить", Callable(self, "_load_slot").bind(slot), row)
        load_button.custom_minimum_size.x = 92
        load_button.disabled = not bool(info.get("exists", false))
        var delete_button := _button("Удалить", Callable(self, "_delete_slot").bind(slot), row, true)
        delete_button.custom_minimum_size.x = 82
        delete_button.disabled = not bool(info.get("exists", false))

func _save_to_slot(slot: int) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null and SaveManager.save_game(player, slot):
        GameState.notify("Сохранено в слот %02d." % slot)
    _show_section("saves")

func _load_slot(slot: int) -> void:
    if not SaveManager.prepare_load(slot):
        return
    awaiting_action = ""
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    get_tree().reload_current_scene()

func _delete_slot(slot: int) -> void:
    SaveManager.delete_slot(slot)
    _show_section("saves")

func _show_settings() -> void:
    title_label.text = "Настройки"
    _hero_card("Настройте игру под свой ПК", "Все изменения применяются сразу и сохраняются локально.")
    _button("Управление", Callable(self, "_show_section").bind("controls"))
    _button("Графика", Callable(self, "_show_section").bind("graphics"))
    _button("Звук", Callable(self, "_show_section").bind("audio"))
    _button("Игра и интерфейс", Callable(self, "_show_section").bind("other"))
    _button("Сбросить настройки", Callable(self, "_reset_settings"), null, true)

func _show_controls() -> void:
    title_label.text = "Управление"
    rebinding_label = _body("Нажмите на назначение, затем нажмите новую клавишу или кнопку мыши.")
    for action in ACTION_LABELS:
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _row_style())
        content.add_child(card)
        var margin := MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 12)
        margin.add_theme_constant_override("margin_right", 12)
        margin.add_theme_constant_override("margin_top", 7)
        margin.add_theme_constant_override("margin_bottom", 7)
        card.add_child(margin)
        var row := HBoxContainer.new()
        margin.add_child(row)
        var label := Label.new()
        label.text = String(ACTION_LABELS[action])
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var key_button := _button(SettingsManager.binding_text(action), Callable(self, "_begin_rebind").bind(action), row)
        key_button.custom_minimum_size.x = 150

func _begin_rebind(action: String) -> void:
    awaiting_action = action
    if is_instance_valid(rebinding_label):
        rebinding_label.text = "Ожидаю новую кнопку для: %s" % String(ACTION_LABELS.get(action, action))

func _show_graphics() -> void:
    title_label.text = "Графика"
    _section_label("Экран")
    _add_checkbox("Полноэкранный режим", bool(SettingsManager.get_value("graphics", "fullscreen")), Callable(self, "_set_setting_bool").bind("graphics", "fullscreen"))
    _add_checkbox("Вертикальная синхронизация (VSync)", bool(SettingsManager.get_value("graphics", "vsync")), Callable(self, "_set_setting_bool").bind("graphics", "vsync"))
    var resolutions := OptionButton.new()
    resolutions.custom_minimum_size.y = 42
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
    _section_label("Качество и масштаб")
    _add_slider("Масштаб 3D", float(SettingsManager.get_value("graphics", "render_scale")), 0.5, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "render_scale"))
    _add_slider("Масштаб интерфейса", float(SettingsManager.get_value("graphics", "ui_scale")), 0.75, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "ui_scale"))

func _show_audio() -> void:
    title_label.text = "Звук"
    _add_slider("Общая громкость", float(SettingsManager.get_value("audio", "master_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "master_volume"))
    _add_slider("Музыка", float(SettingsManager.get_value("audio", "music_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "music_volume"))
    _add_slider("Эффекты", float(SettingsManager.get_value("audio", "sfx_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "sfx_volume"))
    _add_checkbox("Выключить весь звук", bool(SettingsManager.get_value("audio", "muted")), Callable(self, "_set_setting_bool").bind("audio", "muted"))

func _show_other() -> void:
    title_label.text = "Игра и интерфейс"
    _add_slider("Чувствительность мыши", float(SettingsManager.get_value("gameplay", "mouse_sensitivity")), 0.001, 0.01, 0.0005, Callable(self, "_set_setting_float").bind("gameplay", "mouse_sensitivity"))
    _add_slider("Поле зрения", float(SettingsManager.get_value("gameplay", "camera_fov")), 60.0, 100.0, 1.0, Callable(self, "_set_setting_float").bind("gameplay", "camera_fov"))
    _add_slider("Автосохранение, сек.", float(SettingsManager.get_value("gameplay", "autosave_seconds")), 30.0, 300.0, 30.0, Callable(self, "_set_setting_float").bind("gameplay", "autosave_seconds"))
    _add_checkbox("Субтитры", bool(SettingsManager.get_value("gameplay", "subtitles")), Callable(self, "_set_setting_bool").bind("gameplay", "subtitles"))

func _show_updates() -> void:
    title_label.text = "Обновления"
    _hero_card("Автообновление без зависимости от сети", "Если интернет недоступен или обновление повреждено, установленная версия должна продолжить запускаться.")
    _button("Проверить обновления", Callable(UpdateManager, "check_for_updates"), null, false, true)
    update_status = _body("Обновления ещё не проверялись.")
    apply_update_button = _button("Обновить и перезапустить", Callable(UpdateManager, "install_latest_update"))
    apply_update_button.visible = UpdateManager.update_available

func _button(text: String, callback: Callable, parent: Container = null, danger: bool = false, primary: bool = false) -> Button:
    var target: Container = content if parent == null else parent
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 44
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 14)
    var bg := Color(0.045, 0.07, 0.10, 0.98)
    var border := Color(0.12, 0.28, 0.40, 0.80)
    if primary:
        bg = Color(0.04, 0.20, 0.28, 0.98)
        border = Color(0.18, 0.72, 0.92, 0.96)
    elif danger:
        bg = Color(0.17, 0.045, 0.055, 0.98)
        border = Color(0.60, 0.15, 0.20, 0.86)
    button.add_theme_stylebox_override("normal", _button_style(bg, border))
    button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.08), border.lightened(0.15)))
    button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.08), border))
    button.add_theme_stylebox_override("focus", _button_style(bg.lightened(0.04), Color(0.32, 0.78, 1.0, 1.0)))
    button.pressed.connect(callback)
    target.add_child(button)
    return button

func _body(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.70, 0.78, 0.86)
    label.add_theme_font_size_override("font_size", 14)
    content.add_child(label)
    return label

func _section_label(text: String) -> void:
    var label := Label.new()
    label.text = text.to_upper()
    label.modulate = Color(0.38, 0.68, 0.86)
    label.add_theme_font_size_override("font_size", 11)
    label.custom_minimum_size.y = 26
    content.add_child(label)

func _hero_card(title: String, text: String) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _hero_style())
    content.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 15)
    margin.add_theme_constant_override("margin_bottom", 15)
    card.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 5)
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = title
    heading.add_theme_font_size_override("font_size", 20)
    heading.modulate = Color(0.75, 0.92, 1.0)
    stack.add_child(heading)
    var body := Label.new()
    body.text = text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.modulate = Color(0.65, 0.76, 0.84)
    body.add_theme_font_size_override("font_size", 13)
    stack.add_child(body)

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
    heading.modulate = Color(0.45, 0.74, 0.93)
    heading.add_theme_font_size_override("font_size", 11)
    stack.add_child(heading)
    var body := Label.new()
    body.text = text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 14)
    stack.add_child(body)

func _add_checkbox(text: String, value: bool, callback: Callable) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _row_style())
    content.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 7)
    margin.add_theme_constant_override("margin_bottom", 7)
    card.add_child(margin)
    var box := CheckBox.new()
    box.text = text
    box.button_pressed = value
    box.custom_minimum_size.y = 36
    box.toggled.connect(callback)
    margin.add_child(box)

func _add_slider(text: String, value: float, min_value: float, max_value: float, step: float, callback: Callable) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _row_style())
    content.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_bottom", 9)
    card.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 4)
    margin.add_child(stack)
    var top := HBoxContainer.new()
    stack.add_child(top)
    var label := Label.new()
    label.text = text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(label)
    var value_label := Label.new()
    value_label.text = _format_setting_value(value, step)
    value_label.modulate = Color(0.55, 0.78, 0.93)
    value_label.custom_minimum_size.x = 72
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top.add_child(value_label)
    var slider := HSlider.new()
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.value = value
    slider.custom_minimum_size.y = 24
    slider.value_changed.connect(callback)
    slider.value_changed.connect(func(v: float): value_label.text = _format_setting_value(v, step))
    stack.add_child(slider)

func _format_setting_value(value: float, step: float) -> String:
    if step >= 1.0:
        return "%d" % roundi(value)
    if step >= 0.05:
        return "%.2f" % value
    return "%.4f" % value

func _set_setting_bool(value: bool, section: String, key: String) -> void:
    SettingsManager.set_value(section, key, value)
    call_deferred("_apply_responsive_layout")

func _set_setting_float(value: float, section: String, key: String) -> void:
    SettingsManager.set_value(section, key, value)
    if section == "graphics" and key == "ui_scale":
        call_deferred("_apply_responsive_layout")

func _set_resolution(index: int, options: OptionButton) -> void:
    var resolution: Vector2i = options.get_item_metadata(index)
    SettingsManager.set_value("graphics", "resolution_width", resolution.x)
    SettingsManager.set_value("graphics", "resolution_height", resolution.y)
    call_deferred("_apply_responsive_layout")

func _reset_settings() -> void:
    SettingsManager.reset_defaults()
    call_deferred("_apply_responsive_layout")
    _show_section("settings")

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status):
        update_status.text = text
    if is_instance_valid(apply_update_button):
        apply_update_button.visible = available

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.010, 0.016, 0.026, 0.985)
    style.border_color = Color(0.12, 0.42, 0.62, 0.92)
    style.set_border_width_all(1)
    style.set_corner_radius_all(14)
    style.shadow_color = Color(0, 0, 0, 0.50)
    style.shadow_size = 16
    return style

func _sidebar_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.028, 0.043, 0.98)
    style.border_color = Color(0.06, 0.20, 0.31, 0.85)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    return style

func _hero_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.105, 0.145, 0.96)
    style.border_color = Color(0.14, 0.58, 0.78, 0.86)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    return style

func _row_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.026, 0.041, 0.059, 0.96)
    style.border_color = Color(0.08, 0.22, 0.32, 0.75)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style
