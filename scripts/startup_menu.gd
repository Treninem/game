extends Control

const LOADING_SCENE := "res://scenes/world_loading.tscn"
const MENU_BG_PREFIX := "res://assets/production/ui/menu_bg_small.webp.b64"
const MENU_BG_PARTS := 4
const EMBEDDED_TEXTURE := preload("res://scripts/embedded_ui_texture.gd")
const BUTTON_TEXTURE := preload("res://assets/staging/ui/kenney_ui_pack_adventure/PNG/Default/button_brown.png")
const HOVER_SOUND := preload("res://assets/audio/ui/kenney_interface/menu_hover.wav")
const CLICK_SOUND := preload("res://assets/audio/ui/kenney_interface/menu_click.wav")

@onready var settings_overlay: Control = $SettingsOverlay

var frame: PanelContainer
var menu_column: VBoxContainer
var content_frame: PanelContainer
var content: VBoxContainer
var content_title: Label
var continue_button: Button
var update_button: Button
var status_label: Label
var update_status_label: Label
var update_progress_bar: ProgressBar
var update_progress_detail: Label
var install_update_button: Button
var hover_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
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
    UpdateManager.progress_changed.connect(_on_update_progress_changed)
    get_viewport().size_changed.connect(_layout_ui)
    _refresh_continue_state()
    show_page("home")
    call_deferred("_layout_ui")

func startup_actions() -> PackedStringArray:
    return PackedStringArray(["continue", "new_game", "saves", "settings", "check_updates"])

func world_loading_scene() -> String:
    return LOADING_SCENE

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
    content_frame.visible = page != "home"
    match page:
        "saves": _show_saves()
        "updates": _show_updates()
        _: _show_home()
    _layout_ui()

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
    var background := TextureRect.new()
    background.name = "MenuBackground"
    background.texture = EMBEDDED_TEXTURE.load_webp_parts(MENU_BG_PREFIX, MENU_BG_PARTS)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var cinematic := ColorRect.new()
    cinematic.color = Color(0.012, 0.010, 0.014, 0.16)
    cinematic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cinematic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(cinematic)

    var left_shadow := ColorRect.new()
    left_shadow.color = Color(0.008, 0.007, 0.010, 0.67)
    left_shadow.anchor_right = 0.40
    left_shadow.anchor_bottom = 1.0
    left_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(left_shadow)

    hover_player = AudioStreamPlayer.new()
    hover_player.stream = HOVER_SOUND
    hover_player.volume_db = -15.0
    hover_player.bus = &"SFX"
    add_child(hover_player)
    click_player = AudioStreamPlayer.new()
    click_player.stream = CLICK_SOUND
    click_player.volume_db = -10.0
    click_player.bus = &"SFX"
    add_child(click_player)

    frame = PanelContainer.new()
    frame.name = "MainFrame"
    frame.add_theme_stylebox_override("panel", _panel_style(0.88))
    add_child(frame)
    var outer := MarginContainer.new()
    outer.add_theme_constant_override("margin_left", 22)
    outer.add_theme_constant_override("margin_right", 22)
    outer.add_theme_constant_override("margin_top", 20)
    outer.add_theme_constant_override("margin_bottom", 20)
    frame.add_child(outer)
    menu_column = VBoxContainer.new()
    menu_column.add_theme_constant_override("separation", 8)
    outer.add_child(menu_column)

    var brand := Label.new()
    brand.text = "ImPuls"
    brand.add_theme_font_size_override("font_size", 42)
    brand.add_theme_color_override("font_color", Color(0.95, 0.84, 0.62))
    brand.add_theme_color_override("font_shadow_color", Color(0,0,0,0.95))
    brand.add_theme_constant_override("shadow_offset_x", 2)
    brand.add_theme_constant_override("shadow_offset_y", 2)
    menu_column.add_child(brand)
    var subtitle := Label.new()
    subtitle.text = "OPEN WORLD  •  SURVIVAL  •  RPG"
    subtitle.add_theme_font_size_override("font_size", 11)
    subtitle.add_theme_color_override("font_color", Color(0.72, 0.61, 0.44))
    menu_column.add_child(subtitle)
    var version := Label.new()
    version.text = "Версия %s" % String(ProjectSettings.get_setting("application/config/version", "development"))
    version.add_theme_font_size_override("font_size", 10)
    version.add_theme_color_override("font_color", Color(0.58, 0.55, 0.50))
    menu_column.add_child(version)
    var separator := HSeparator.new()
    separator.modulate = Color(0.58, 0.42, 0.24, 0.72)
    menu_column.add_child(separator)

    continue_button = _menu_button("▶  ПРОДОЛЖИТЬ", Callable(self, "_continue_game"), true)
    continue_button.name = "ContinueButton"
    _menu_button("⚔  НОВАЯ ИГРА", Callable(self, "_new_game")).name = "NewGameButton"
    _menu_button("▣  ЗАГРУЗИТЬ ИГРУ", Callable(self, "show_page").bind("saves")).name = "SavesButton"
    _menu_button("⚙  НАСТРОЙКИ", Callable(self, "open_settings")).name = "SettingsButton"
    update_button = _menu_button("↻  ОБНОВЛЕНИЯ", Callable(self, "_show_updates_and_check"))
    update_button.name = "CheckUpdatesButton"

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    menu_column.add_child(spacer)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 11)
    status_label.add_theme_color_override("font_color", Color(0.78, 0.72, 0.63))
    menu_column.add_child(status_label)
    _menu_button("⏻  ВЫХОД", Callable(get_tree(), "quit"), false, true)

    content_frame = PanelContainer.new()
    content_frame.name = "ContentFrame"
    content_frame.add_theme_stylebox_override("panel", _panel_style(0.95))
    add_child(content_frame)
    var content_margin := MarginContainer.new()
    for side in ["margin_left", "margin_right"]:
        content_margin.add_theme_constant_override(side, 24)
    content_margin.add_theme_constant_override("margin_top", 20)
    content_margin.add_theme_constant_override("margin_bottom", 20)
    content_frame.add_child(content_margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    content_margin.add_child(stack)
    content_title = Label.new()
    content_title.add_theme_font_size_override("font_size", 27)
    content_title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.63))
    stack.add_child(content_title)
    stack.add_child(HSeparator.new())
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    stack.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    scroll.add_child(content)

func _prepare_settings_overlay() -> void:
    if not is_instance_valid(settings_overlay):
        return
    settings_overlay.visibility_changed.connect(_on_settings_visibility_changed)
    var nav_buttons = settings_overlay.get("nav_buttons")
    if nav_buttons is Dictionary:
        for hidden in ["main", "saves"]:
            var button = nav_buttons.get(hidden)
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

func _layout_ui() -> void:
    if not is_instance_valid(frame):
        return
    var available := get_viewport_rect().size
    var margin := clampf(available.x * 0.045, 18.0, 72.0)
    var menu_width := clampf(available.x * 0.285, 300.0, 410.0)
    var menu_height := minf(clampf(available.y - margin * 2.0, 500.0, 690.0), available.y - 16.0)
    frame.position = Vector2(margin, maxf(8.0, (available.y - menu_height) * 0.5))
    frame.size = Vector2(menu_width, menu_height)
    var content_x := frame.position.x + frame.size.x + clampf(available.x * 0.025, 16.0, 38.0)
    var content_width := maxf(300.0, available.x - content_x - margin)
    if available.x < 900.0:
        content_x = maxf(margin, available.x * 0.34)
        content_width = maxf(260.0, available.x - content_x - 12.0)
    var content_height := minf(menu_height, maxf(390.0, available.y * 0.74))
    content_frame.position = Vector2(content_x, maxf(8.0, (available.y - content_height) * 0.5))
    content_frame.size = Vector2(content_width, content_height)

func _show_home() -> void:
    content_title.text = ""

func _show_saves() -> void:
    content_title.text = "Сохранения"
    _body("10 независимых слотов. Существующий слот можно загрузить или удалить; пустой — использовать для новой игры.")
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
            _content_button("Загрузить", Callable(self, "_load_slot").bind(slot), false, true, row)
            _content_button("Удалить", Callable(self, "_delete_slot").bind(slot), true, false, row)
        else:
            _content_button("Новая игра", Callable(self, "_start_new_game_in_slot").bind(slot), false, true, row)
    _content_button("Назад", Callable(self, "show_page").bind("home"))

func _show_updates() -> void:
    content_title.text = "Обновления"
    _body("Проверка показывает реально полученные байты. При установке открывается отдельное окно с фактически скачанными МБ, процентом, применением дельты и проверкой файлов.")
    _content_button("Проверить обновления", Callable(self, "_check_updates"), false, true)
    update_progress_bar = ProgressBar.new()
    update_progress_bar.min_value = 0
    update_progress_bar.max_value = 100
    update_progress_bar.show_percentage = false
    update_progress_bar.custom_minimum_size.y = 22
    update_progress_bar.add_theme_stylebox_override("background", _progress_style(false))
    update_progress_bar.add_theme_stylebox_override("fill", _progress_style(true))
    content.add_child(update_progress_bar)
    update_progress_detail = _body("Ожидание проверки.")
    update_status_label = _body("Обновления ещё не проверялись.")
    install_update_button = _content_button("Установить обновление", Callable(self, "_install_update"), false, true)
    install_update_button.visible = UpdateManager.update_available
    _content_button("Назад", Callable(self, "show_page").bind("home"))

func _show_updates_and_check() -> void:
    show_page("updates")
    _check_updates()

func _check_updates() -> void:
    update_button.disabled = true
    update_button.text = "↻  ПРОВЕРКА..."
    if is_instance_valid(update_progress_bar):
        update_progress_bar.value = 0
    UpdateManager.check_for_updates()

func _install_update() -> void:
    if is_instance_valid(update_status_label):
        update_status_label.text = "Запуск видимого установщика обновления..."
    UpdateManager.install_latest_update()

func _on_update_progress_changed(stage: String, downloaded: int, total: int, percent: float) -> void:
    if is_instance_valid(update_progress_bar):
        update_progress_bar.value = clampf(percent, 0.0, 100.0) if percent >= 0.0 else 0.0
    if is_instance_valid(update_progress_detail):
        update_progress_detail.text = "%s • %s из %s • %d%%" % [stage, _format_bytes(downloaded), _format_bytes(total), roundi(percent)] if total > 0 and percent >= 0.0 else "%s • получено %s" % [stage, _format_bytes(downloaded)]

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status_label):
        update_status_label.text = text
    if is_instance_valid(install_update_button):
        install_update_button.visible = available
    update_button.disabled = UpdateManager.checking
    update_button.text = "↻  ПРОВЕРКА..." if UpdateManager.checking else "↻  ОБНОВЛЕНИЯ"
    status_label.text = text

func _refresh_continue_state() -> void:
    latest_slot = latest_save_slot()
    continue_button.visible = latest_slot > 0
    continue_button.disabled = latest_slot <= 0
    status_label.text = "Последнее сохранение: слот %02d" % latest_slot if latest_slot > 0 else "Сохранений пока нет"

func _continue_game() -> void:
    _refresh_continue_state()
    if latest_slot <= 0 or not SaveManager.prepare_load(latest_slot):
        status_label.text = "Сохранение для продолжения не найдено."
        return
    _enter_loading_screen()

func _new_game() -> void:
    var slot := SaveManager.first_free_slot()
    if slot <= 0:
        status_label.text = "Все 10 слотов заняты. Освободите слот в разделе сохранений."
        show_page("saves")
        return
    _start_new_game_in_slot(slot)

func _start_new_game_in_slot(slot: int) -> void:
    SaveManager.prepare_new_game(slot)
    _enter_loading_screen()

func _load_slot(slot: int) -> void:
    if SaveManager.prepare_load(slot):
        _enter_loading_screen()

func _delete_slot(slot: int) -> void:
    SaveManager.delete_slot(slot)
    _refresh_continue_state()
    show_page("saves")

func _enter_loading_screen() -> void:
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var err := get_tree().change_scene_to_file(LOADING_SCENE)
    if err != OK:
        status_label.text = "Не удалось открыть экран загрузки. Код: %s" % err

func _clear_content() -> void:
    update_status_label = null
    update_progress_bar = null
    update_progress_detail = null
    install_update_button = null
    save_row_count = 0
    for child in content.get_children():
        child.free()

func _menu_button(text: String, callback: Callable, primary: bool = false, danger: bool = false) -> Button:
    var button := _make_button(text, callback, primary, danger)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size.y = 50
    menu_column.add_child(button)
    return button

func _content_button(text: String, callback: Callable, danger: bool = false, primary: bool = false, parent: Container = null) -> Button:
    var button := _make_button(text, callback, primary, danger)
    button.custom_minimum_size.y = 42
    (content if parent == null else parent).add_child(button)
    return button

func _make_button(text: String, callback: Callable, primary: bool, danger: bool) -> Button:
    var button := Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", Color(0.91, 0.85, 0.74))
    button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.68))
    button.add_theme_stylebox_override("normal", _button_style(Color(0.72,0.64,0.53,0.96 if primary else 0.78)))
    button.add_theme_stylebox_override("hover", _button_style(Color(1.0,0.84,0.52,1.0)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.88,0.64,0.31,1.0)))
    if danger:
        button.modulate = Color(0.90, 0.70, 0.65)
    button.mouse_entered.connect(_play_hover)
    button.focus_entered.connect(_play_hover)
    button.pressed.connect(_play_click)
    button.pressed.connect(callback)
    return button

func _play_hover() -> void:
    hover_player.play()

func _play_click() -> void:
    click_player.play()

func _body(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_color_override("font_color", Color(0.81, 0.78, 0.71))
    content.add_child(label)
    return label

func _panel_style(alpha: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.027, 0.022, alpha)
    style.border_color = Color(0.56, 0.40, 0.21, 0.90)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.shadow_color = Color(0,0,0,0.68)
    style.shadow_size = 16
    return style

func _row_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08,0.065,0.052,0.92)
    style.border_color = Color(0.36,0.27,0.16,0.78)
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    return style

func _button_style(color: Color) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = BUTTON_TEXTURE
    style.modulate_color = color
    style.texture_margin_left = 8
    style.texture_margin_right = 8
    style.texture_margin_top = 8
    style.texture_margin_bottom = 8
    style.content_margin_left = 14
    style.content_margin_right = 12
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    return style

func _progress_style(fill: bool) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.72,0.46,0.18,0.96) if fill else Color(0.02,0.017,0.015,0.95)
    style.border_color = Color(0.96,0.75,0.34,0.95) if fill else Color(0.45,0.33,0.20,0.90)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    return style

func _format_bytes(value: int) -> String:
    if value < 0:
        return "неизвестно"
    if value >= 1024 * 1024 * 1024:
        return "%.2f ГБ" % (float(value) / float(1024 * 1024 * 1024))
    if value >= 1024 * 1024:
        return "%.1f МБ" % (float(value) / float(1024 * 1024))
    if value >= 1024:
        return "%.0f КБ" % (float(value) / 1024.0)
    return "%d Б" % value
