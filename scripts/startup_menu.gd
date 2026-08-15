extends Control

const WORLD_SCENE := "res://scenes/stage1.tscn"

@onready var settings_overlay: Control = $SettingsOverlay

var frame: PanelContainer
var menu_column: VBoxContainer
var content: VBoxContainer
var title_label: Label
var continue_button: Button
var update_button: Button
var status_label: Label
var update_status_label: Label
var install_update_button: Button
var latest_slot := 0
var save_row_count := 0
var current_page := "home"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_ui()
    _prepare_settings_overlay()
    UpdateManager.status_changed.connect(_on_update_status_changed)
    get_viewport().size_changed.connect(_layout_frame)
    _refresh_continue_state()
    show_page("home")
    call_deferred("_layout_frame")

func startup_actions() -> PackedStringArray:
    return PackedStringArray(["continue", "new_game", "saves", "settings", "check_updates"])

func latest_save_slot() -> int:
    var result := 0
    var newest := ""
    for info in SaveManager.list_slots():
        if not bool(info.get("exists", false)):
            continue
        var saved_at := String(info.get("saved_at", ""))
        if result == 0 or saved_at.naturalnocasecmp_to(newest) > 0:
            result = int(info.get("slot", 0))
            newest = saved_at
    return result

func continue_is_available() -> bool:
    return latest_slot > 0

func continue_button_is_visible() -> bool:
    return is_instance_valid(continue_button) and continue_button.visible

func settings_overlay_ready() -> bool:
    return is_instance_valid(settings_overlay) and settings_overlay.has_method("open_menu")

func show_page(page: String) -> void:
    current_page = page
    _clear_content()
    match page:
        "saves": _show_saves()
        "updates": _show_updates()
        _: _show_home()

func open_settings() -> void:
    if not settings_overlay_ready():
        status_label.text = "Меню настроек недоступно."
        return
    settings_overlay.call("open_menu", "settings")
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_settings_overlay() -> void:
    if settings_overlay_ready() and settings_overlay.visible:
        settings_overlay.call("close_menu")
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color(0.004, 0.008, 0.014, 1.0)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    move_child(background, 0)

    var glow := ColorRect.new()
    glow.color = Color(0.02, 0.10, 0.15, 0.45)
    glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
    glow.offset_bottom = 130.0
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(glow)
    move_child(glow, 1)

    frame = PanelContainer.new()
    frame.name = "MainFrame"
    frame.add_theme_stylebox_override("panel", _panel_style())
    add_child(frame)
    move_child(frame, 2)

    var outer := MarginContainer.new()
    outer.add_theme_constant_override("margin_left", 20)
    outer.add_theme_constant_override("margin_right", 20)
    outer.add_theme_constant_override("margin_top", 20)
    outer.add_theme_constant_override("margin_bottom", 20)
    frame.add_child(outer)

    var split := HBoxContainer.new()
    split.add_theme_constant_override("separation", 22)
    outer.add_child(split)

    var menu_panel := PanelContainer.new()
    menu_panel.name = "MenuPanel"
    menu_panel.custom_minimum_size = Vector2(250, 0)
    menu_panel.add_theme_stylebox_override("panel", _sidebar_style())
    split.add_child(menu_panel)

    var menu_margin := MarginContainer.new()
    menu_margin.add_theme_constant_override("margin_left", 14)
    menu_margin.add_theme_constant_override("margin_right", 14)
    menu_margin.add_theme_constant_override("margin_top", 16)
    menu_margin.add_theme_constant_override("margin_bottom", 16)
    menu_panel.add_child(menu_margin)

    menu_column = VBoxContainer.new()
    menu_column.add_theme_constant_override("separation", 8)
    menu_margin.add_child(menu_column)

    var brand_row := HBoxContainer.new()
    brand_row.add_theme_constant_override("separation", 10)
    menu_column.add_child(brand_row)
    var icon := TextureRect.new()
    icon.texture = load("res://assets/branding/impuls_icon.png")
    icon.custom_minimum_size = Vector2(52, 52)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    brand_row.add_child(icon)
    var brand_stack := VBoxContainer.new()
    brand_row.add_child(brand_stack)
    var brand := Label.new()
    brand.text = "ImPuls"
    brand.add_theme_font_size_override("font_size", 24)
    brand.modulate = Color(0.78, 0.93, 1.0)
    brand_stack.add_child(brand)
    var version := Label.new()
    version.text = String(ProjectSettings.get_setting("application/config/version", "development"))
    version.add_theme_font_size_override("font_size", 10)
    version.modulate = Color(0.40, 0.60, 0.72)
    brand_stack.add_child(version)
    menu_column.add_child(HSeparator.new())

    continue_button = _menu_button("Продолжить", Callable(self, "_continue_game"), true)
    continue_button.name = "ContinueButton"
    _menu_button("Новая игра", Callable(self, "_new_game")).name = "NewGameButton"
    _menu_button("Сохранения", Callable(self, "show_page").bind("saves")).name = "SavesButton"
    _menu_button("Настройки", Callable(self, "open_settings")).name = "SettingsButton"
    update_button = _menu_button("Проверить обновления", Callable(self, "_show_updates_and_check"))
    update_button.name = "CheckUpdatesButton"

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    menu_column.add_child(spacer)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 11)
    status_label.modulate = Color(0.47, 0.66, 0.78)
    menu_column.add_child(status_label)
    _menu_button("Выйти", Callable(get_tree(), "quit"), false, true)

    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_constant_override("separation", 10)
    split.add_child(right)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 28)
    title_label.modulate = Color(0.82, 0.94, 1.0)
    right.add_child(title_label)
    right.add_child(HSeparator.new())
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    right.add_child(scroll)
    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    scroll.add_child(margin)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    margin.add_child(content)

func _prepare_settings_overlay() -> void:
    if not is_instance_valid(settings_overlay):
        return
    settings_overlay.visibility_changed.connect(_on_settings_visibility_changed)
    var nav_buttons = settings_overlay.get("nav_buttons")
    if nav_buttons is Dictionary:
        for hidden_section in ["main", "saves"]:
            var button = nav_buttons.get(hidden_section)
            if button is Button:
                button.visible = false
    var sidebar = settings_overlay.get("sidebar")
    if sidebar is VBoxContainer:
        for child in sidebar.get_children():
            if child is Button and child.text == "Вернуться в игру":
                child.text = "Назад в главное меню"

func _on_settings_visibility_changed() -> void:
    if not settings_overlay.visible:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _layout_frame() -> void:
    if not is_instance_valid(frame):
        return
    var available := size
    if available.x < 10.0 or available.y < 10.0:
        available = get_viewport_rect().size
    var target := Vector2(minf(1020.0, available.x - 44.0), minf(650.0, available.y - 44.0))
    target.x = maxf(580.0, target.x)
    target.y = maxf(430.0, target.y)
    target.x = minf(target.x, available.x)
    target.y = minf(target.y, available.y)
    frame.size = target
    frame.position = ((available - target) * 0.5).floor()
    var menu_panel := frame.get_node_or_null("MarginContainer/HBoxContainer/MenuPanel") as PanelContainer
    if menu_panel != null:
        menu_panel.custom_minimum_size.x = 195.0 if target.x < 780.0 else 250.0

func _show_home() -> void:
    title_label.text = "Главное меню"
    var subtitle := "Сохранений пока нет."
    if latest_slot > 0:
        var info := SaveManager.slot_info(latest_slot)
        subtitle = "Последнее сохранение: слот %02d • %s • %s" % [latest_slot, String(info.get("location", "мир ImPuls")), String(info.get("world_time", "--:--"))]
    _hero("ImPuls", subtitle)
    _body("Мир начинает загружаться только после выбора «Продолжить» или «Новая игра». Настройки, сохранения и проверка обновлений доступны до входа в игру.")
    if latest_slot > 0:
        _content_button("Продолжить", Callable(self, "_continue_game"), false, true)
    else:
        _content_button("Новая игра", Callable(self, "_new_game"), false, true)
    _content_button("Сохранения", Callable(self, "show_page").bind("saves"))
    _content_button("Настройки", Callable(self, "open_settings"))

func _show_saves() -> void:
    title_label.text = "Сохранения"
    _body("10 независимых слотов. Пустой слот можно использовать для новой игры; существующий — загрузить или удалить.")
    for info in SaveManager.list_slots():
        save_row_count += 1
        var slot := int(info.get("slot", save_row_count))
        var exists := bool(info.get("exists", false))
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _row_style())
        content.add_child(card)
        var margin := MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 12)
        margin.add_theme_constant_override("margin_right", 12)
        margin.add_theme_constant_override("margin_top", 8)
        margin.add_theme_constant_override("margin_bottom", 8)
        card.add_child(margin)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        margin.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "Слот %02d\n%s" % [slot, ("%s • %s" % [String(info.get("location", "мир ImPuls")), String(info.get("world_time", "--:--"))]) if exists else "Пустой слот"]
        row.add_child(label)
        if exists:
            _content_button("Загрузить", Callable(self, "_load_slot").bind(slot), false, true, row).custom_minimum_size.x = 94
            _content_button("Удалить", Callable(self, "_delete_slot").bind(slot), true, false, row).custom_minimum_size.x = 82
        else:
            _content_button("Новая игра", Callable(self, "_start_new_game_in_slot").bind(slot), false, true, row).custom_minimum_size.x = 112
    _content_button("Назад", Callable(self, "show_page").bind("home"))

func _show_updates() -> void:
    title_label.text = "Обновления"
    _hero("Стабильный канал", "Проверка использует существующий UpdateManager и не мешает офлайн-запуску игры.")
    _content_button("Проверить обновления", Callable(self, "_check_updates"), false, true)
    update_status_label = _body("Обновления ещё не проверялись.")
    install_update_button = _content_button("Установить обновление", Callable(UpdateManager, "install_latest_update"))
    install_update_button.visible = UpdateManager.update_available
    _content_button("Назад", Callable(self, "show_page").bind("home"))

func _show_updates_and_check() -> void:
    show_page("updates")
    _check_updates()

func _check_updates() -> void:
    update_button.disabled = true
    update_button.text = "Проверка обновлений..."
    UpdateManager.check_for_updates()

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status_label):
        update_status_label.text = text
    if is_instance_valid(install_update_button):
        install_update_button.visible = available
    update_button.disabled = UpdateManager.checking
    update_button.text = "Проверка обновлений..." if UpdateManager.checking else "Проверить обновления"
    status_label.text = text

func _refresh_continue_state() -> void:
    latest_slot = latest_save_slot()
    continue_button.visible = latest_slot > 0
    continue_button.disabled = latest_slot <= 0
    status_label.text = "Продолжение: слот %02d" % latest_slot if latest_slot > 0 else "Сохранений пока нет"

func _continue_game() -> void:
    _refresh_continue_state()
    if latest_slot <= 0 or not SaveManager.prepare_load(latest_slot):
        status_label.text = "Сохранение для продолжения не найдено."
        return
    _enter_world()

func _new_game() -> void:
    var slot := SaveManager.first_free_slot()
    if slot <= 0:
        status_label.text = "Все 10 слотов заняты. Освободите слот в разделе сохранений."
        show_page("saves")
        return
    _start_new_game_in_slot(slot)

func _start_new_game_in_slot(slot: int) -> void:
    SaveManager.prepare_new_game(slot)
    _enter_world()

func _load_slot(slot: int) -> void:
    if SaveManager.prepare_load(slot):
        _enter_world()

func _delete_slot(slot: int) -> void:
    SaveManager.delete_slot(slot)
    _refresh_continue_state()
    show_page("saves")

func _enter_world() -> void:
    get_tree().paused = false
    var err := get_tree().change_scene_to_file(WORLD_SCENE)
    if err != OK:
        status_label.text = "Не удалось открыть игровой мир. Код ошибки: %s" % err
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _clear_content() -> void:
    update_status_label = null
    install_update_button = null
    save_row_count = 0
    for child in content.get_children():
        child.free()

func _menu_button(text: String, callback: Callable, primary: bool = false, danger: bool = false) -> Button:
    var button := Button.new()
    button.text = text
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size.y = 46
    button.focus_mode = Control.FOCUS_ALL
    var bg := Color(0.026, 0.047, 0.068, 0.98)
    var border := Color(0.08, 0.22, 0.32, 0.82)
    if primary:
        bg = Color(0.035, 0.16, 0.22, 0.98)
        border = Color(0.18, 0.62, 0.78, 0.94)
    elif danger:
        bg = Color(0.12, 0.03, 0.04, 0.98)
        border = Color(0.45, 0.10, 0.14, 0.88)
    button.add_theme_stylebox_override("normal", _button_style(bg, border))
    button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.08), border.lightened(0.15)))
    button.pressed.connect(callback)
    menu_column.add_child(button)
    return button

func _content_button(text: String, callback: Callable, danger: bool = false, primary: bool = false, parent: Container = null) -> Button:
    var target: Container = content if parent == null else parent
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 42
    var bg := Color(0.042, 0.066, 0.092, 0.98)
    var border := Color(0.11, 0.28, 0.39, 0.82)
    if primary:
        bg = Color(0.04, 0.20, 0.28, 0.98)
        border = Color(0.18, 0.72, 0.92, 0.96)
    elif danger:
        bg = Color(0.15, 0.04, 0.05, 0.98)
        border = Color(0.55, 0.13, 0.18, 0.88)
    button.add_theme_stylebox_override("normal", _button_style(bg, border))
    button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.08), border.lightened(0.15)))
    button.pressed.connect(callback)
    target.add_child(button)
    return button

func _hero(title: String, text: String) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _hero_style())
    content.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    card.add_child(margin)
    var stack := VBoxContainer.new()
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
    stack.add_child(body)

func _body(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.70, 0.78, 0.86)
    content.add_child(label)
    return label

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.009, 0.016, 0.026, 0.985)
    style.border_color = Color(0.11, 0.39, 0.58, 0.92)
    style.set_border_width_all(1)
    style.set_corner_radius_all(14)
    style.shadow_color = Color(0, 0, 0, 0.55)
    style.shadow_size = 18
    return style

func _sidebar_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.028, 0.043, 0.98)
    style.border_color = Color(0.06, 0.20, 0.31, 0.86)
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
