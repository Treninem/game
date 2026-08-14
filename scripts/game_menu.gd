extends Control

const APP_ICON = preload("res://assets/branding/impuls_icon.svg")
const WORLD_MAP_VIEW = preload("res://scripts/world_map_view.gd")

const ACTION_LABELS := {
    "move_forward": "Движение вперёд",
    "move_back": "Движение назад",
    "move_left": "Движение влево",
    "move_right": "Движение вправо",
    "sprint": "Бег",
    "jump": "Прыжок",
    "interact": "Взаимодействие",
    "attack": "Атака",
    "craft": "Быстрый крафт",
    "build": "Строительство",
    "use_food": "Быстрая еда",
    "use_water": "Быстрая вода",
    "open_inventory": "Открыть инвентарь",
    "open_map": "Открыть карту",
    "open_journal": "Открыть журнал",
    "open_crafting": "Открыть крафт",
    "quick_save": "Быстрое сохранение",
    "quick_load": "Быстрая загрузка",
    "pause_menu": "Меню / пауза"
}

var content: VBoxContainer
var update_status: Label
var apply_update_button: Button
var awaiting_action := ""
var rebinding_label: Label
var current_section := "main"
var section_title: Label
var location_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_shell()
    UpdateManager.status_changed.connect(_on_update_status_changed)
    GameState.location_changed.connect(_on_location_changed)
    call_deferred("open_menu", "main")

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
        if visible:
            close_menu()
        else:
            open_menu("main")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_inventory"):
        _toggle_direct_section("inventory")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_map"):
        _toggle_direct_section("map")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_journal"):
        _toggle_direct_section("journal")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_crafting"):
        _toggle_direct_section("crafting")
        get_viewport().set_input_as_handled()

func _toggle_direct_section(section: String) -> void:
    if visible and current_section == section:
        close_menu()
    else:
        open_menu(section)

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
    backdrop.color = Color(0.006, 0.009, 0.015, 0.91)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    var frame := PanelContainer.new()
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame.offset_left = 18
    frame.offset_top = 18
    frame.offset_right = -18
    frame.offset_bottom = -18
    frame.add_theme_stylebox_override("panel", _panel_style())
    add_child(frame)

    var frame_margin := MarginContainer.new()
    frame_margin.add_theme_constant_override("margin_left", 14)
    frame_margin.add_theme_constant_override("margin_right", 14)
    frame_margin.add_theme_constant_override("margin_top", 14)
    frame_margin.add_theme_constant_override("margin_bottom", 14)
    frame.add_child(frame_margin)

    var root := HBoxContainer.new()
    root.add_theme_constant_override("separation", 16)
    frame_margin.add_child(root)

    var sidebar := VBoxContainer.new()
    sidebar.custom_minimum_size.x = 236
    sidebar.add_theme_constant_override("separation", 6)
    root.add_child(sidebar)

    var brand := HBoxContainer.new()
    brand.add_theme_constant_override("separation", 10)
    sidebar.add_child(brand)
    var icon := TextureRect.new()
    icon.texture = APP_ICON
    icon.custom_minimum_size = Vector2(44, 44)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    brand.add_child(icon)
    var brand_stack := VBoxContainer.new()
    brand.add_child(brand_stack)
    var game_name := Label.new()
    game_name.text = "ImPuls"
    game_name.add_theme_font_size_override("font_size", 23)
    brand_stack.add_child(game_name)
    location_label = Label.new()
    location_label.text = GameState.current_location
    location_label.modulate = Color(0.52, 0.72, 0.88)
    location_label.add_theme_font_size_override("font_size", 11)
    location_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    brand_stack.add_child(location_label)

    var sep := HSeparator.new()
    sidebar.add_child(sep)
    _sidebar_button(sidebar, "▶  Продолжить", Callable(self, "close_menu"))
    _sidebar_button(sidebar, "◈  Карта   [M]", Callable(self, "_show_section").bind("map"))
    _sidebar_button(sidebar, "▦  Инвентарь   [I]", Callable(self, "_show_section").bind("inventory"))
    _sidebar_button(sidebar, "⚒  Крафт   [K]", Callable(self, "_show_section").bind("crafting"))
    _sidebar_button(sidebar, "☷  Журнал   [J]", Callable(self, "_show_section").bind("journal"))
    _sidebar_button(sidebar, "▣  Сохранения", Callable(self, "_show_section").bind("saves"))
    _sidebar_button(sidebar, "⚙  Настройки", Callable(self, "_show_section").bind("settings"))
    _sidebar_button(sidebar, "↻  Обновления", Callable(self, "_show_section").bind("updates"))

    var stretch := Control.new()
    stretch.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sidebar.add_child(stretch)
    var slot_label := Label.new()
    slot_label.text = "Слот: %02d   •   %s" % [SaveManager.current_slot, String(ProjectSettings.get_setting("application/config/version", "dev"))]
    slot_label.modulate = Color(0.55, 0.61, 0.68)
    slot_label.add_theme_font_size_override("font_size", 11)
    sidebar.add_child(slot_label)
    _sidebar_button(sidebar, "Выйти из игры", Callable(get_tree(), "quit"), true)

    var right_panel := PanelContainer.new()
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.add_theme_stylebox_override("panel", _content_panel_style())
    root.add_child(right_panel)

    var right_margin := MarginContainer.new()
    right_margin.add_theme_constant_override("margin_left", 22)
    right_margin.add_theme_constant_override("margin_right", 22)
    right_margin.add_theme_constant_override("margin_top", 18)
    right_margin.add_theme_constant_override("margin_bottom", 18)
    right_panel.add_child(right_margin)

    var right_stack := VBoxContainer.new()
    right_stack.add_theme_constant_override("separation", 10)
    right_margin.add_child(right_stack)
    section_title = Label.new()
    section_title.add_theme_font_size_override("font_size", 26)
    right_stack.add_child(section_title)
    var title_sep := HSeparator.new()
    right_stack.add_child(title_sep)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_stack.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    scroll.add_child(content)

func _sidebar_button(parent: Container, text: String, callback: Callable, danger: bool = false) -> Button:
    var button := Button.new()
    button.text = text
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size.y = 39
    button.add_theme_font_size_override("font_size", 14)
    var bg := Color(0.075, 0.095, 0.13, 0.94) if not danger else Color(0.18, 0.06, 0.065, 0.94)
    var border := Color(0.18, 0.38, 0.54, 0.7) if not danger else Color(0.58, 0.18, 0.2, 0.75)
    button.add_theme_stylebox_override("normal", _button_style(bg, border))
    button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.08), border.lightened(0.18)))
    button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.08), border))
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _show_section(section: String) -> void:
    current_section = section
    _clear_content()
    match section:
        "map": _show_map()
        "inventory": _show_inventory()
        "crafting": _show_crafting()
        "journal": _show_journal()
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

func _title(text: String, subtitle: String = "") -> void:
    section_title.text = text
    if not subtitle.is_empty():
        var label := Label.new()
        label.text = subtitle
        label.modulate = Color(0.66, 0.74, 0.82)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_size_override("font_size", 13)
        content.add_child(label)

func _show_main() -> void:
    _title("Пауза", "Основные игровые разделы всегда находятся слева. Ничего не спрятано ниже экрана.")
    _info_card("ТЕКУЩАЯ ЛОКАЦИЯ", GameState.current_location)
    _info_card("ТЕКУЩАЯ ЦЕЛЬ", GameState.quest_text())
    var hints := Label.new()
    hints.text = "Быстрый доступ во время игры:\nM — карта   •   I — инвентарь   •   J — журнал   •   K — крафт   •   Esc — пауза\nF5 — быстро сохранить   •   F9 — быстро загрузить"
    hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hints.add_theme_font_size_override("font_size", 16)
    content.add_child(hints)

func _show_map() -> void:
    _title("Карта мира", "Карта открывается по мере исследования. Тёмные участки остаются скрытыми, пока персонаж туда не доберётся.")
    var map_view := WORLD_MAP_VIEW.new()
    map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_view.custom_minimum_size.y = 500
    content.add_child(map_view)

func _show_inventory() -> void:
    _title("Инвентарь и экипировка", "Открывается прямо из игры клавишей I.")
    var weapon_id := InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    var weapon_name := "не выбрано" if weapon_id.is_empty() else String(InventorySystem.item_info(weapon_id).get("name", weapon_id))
    _info_card("ОРУЖИЕ", "%s   •   бонус атаки +%.0f" % [weapon_name, InventorySystem.attack_bonus()])
    var rows := InventorySystem.inventory_rows()
    if rows.is_empty():
        _body("Инвентарь пуст.")
        return
    for info in rows:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        content.add_child(row)
        var text := Label.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        text.text = "%s ×%d\n%s  •  %s" % [String(info.get("name", "")), int(info.get("amount", 0)), String(info.get("category", "")), String(info.get("description", ""))]
        row.add_child(text)
        var item_id := String(info.get("id", ""))
        if not String(info.get("equip_slot", "")).is_empty():
            var equip_text := "Экипировано" if InventorySystem.equipped_item(String(info.get("equip_slot", ""))) == item_id else "Экипировать"
            _button(equip_text, Callable(self, "_equip_item").bind(item_id), row).custom_minimum_size.x = 135
        elif item_id in ["berries", "water_flask", "raw_meat", "cooked_meat"]:
            _button("Использовать", Callable(self, "_use_item").bind(item_id), row).custom_minimum_size.x = 120

func _equip_item(item_id: String) -> void:
    InventorySystem.equip(item_id)
    _show_section("inventory")

func _use_item(item_id: String) -> void:
    if item_id == "cooked_meat":
        if GameState.remove_item(item_id, 1):
            GameState.hunger = minf(100.0, GameState.hunger + 45.0)
            GameState.health = minf(GameState.max_health, GameState.health + 5.0)
            GameState.survival_changed.emit()
            GameState.notify("Вы съели жареное мясо.")
    else:
        GameState.use_consumable(item_id)
    _show_section("inventory")

func _show_crafting() -> void:
    _title("Крафт", "Открывается прямо из игры клавишей K. Материалы списываются только при успешном создании.")
    var recipes := InventorySystem.available_recipes()
    if recipes.is_empty():
        _body("Пока нет доступных рецептов.")
        return
    for recipe in recipes:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        content.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "%s\nНужно: %s" % [String(recipe.get("name", "")), InventorySystem.requirements_text(recipe.get("requirements", {}))]
        row.add_child(label)
        var craft_button := _button("Создать", Callable(self, "_craft_recipe").bind(String(recipe.get("id", ""))), row)
        craft_button.custom_minimum_size.x = 120
        craft_button.disabled = not bool(recipe.get("can_craft", false))

func _craft_recipe(recipe_id: String) -> void:
    InventorySystem.craft(recipe_id)
    _show_section("crafting")

func _show_journal() -> void:
    _title("Журнал заданий", "Открывается прямо из игры клавишей J.")
    var intro_status := "Не начато"
    if GameState.quest_stage > 0 and GameState.quest_stage < 4:
        intro_status = "Активно"
    elif GameState.quest_stage >= 4:
        intro_status = "Завершено"
    _info_card("ПЕРВОЕ УБЕЖИЩЕ  •  " + intro_status, GameState.quest_text() if GameState.quest_stage < 4 else "Первое поручение Миры завершено.")

    var city_status := "Не начато"
    if GameState.city_quest_stage == 1:
        city_status = "Активно"
    elif GameState.city_quest_stage >= 2:
        city_status = "Завершено"
    var city_text := "Поговорите с кузнецом Раданом в Южном квартале."
    if GameState.city_quest_stage == 1:
        city_text = "Принесите Радану 6 камня и 4 древесины для ремонта Южных ворот."
    elif GameState.city_quest_stage >= 2:
        city_text = "Ремонт Южных ворот завершён. Награда получена."
    _info_card("РЕМОНТ ЮЖНЫХ ВОРОТ  •  " + city_status, city_text)
    _body("Монеты: %d   •   Репутация Люменграда: %d   •   Побеждено существ: %d" % [GameState.coins, GameState.city_reputation, GameState.enemies_defeated])

func _show_saves() -> void:
    _title("Сохранения", "10 независимых слотов. Можно создать, перезаписать, загрузить или удалить любой слот.")
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
        _button("Создать" if not bool(info.get("exists", false)) else "Сохранить", Callable(self, "_save_to_slot").bind(slot), row).custom_minimum_size.x = 100
        var load_button := _button("Загрузить", Callable(self, "_load_slot").bind(slot), row)
        load_button.custom_minimum_size.x = 100
        load_button.disabled = not bool(info.get("exists", false))
        var delete_button := _button("Удалить", Callable(self, "_delete_slot").bind(slot), row)
        delete_button.custom_minimum_size.x = 90
        delete_button.disabled = not bool(info.get("exists", false))

func _save_to_slot(slot: int) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null and SaveManager.save_game(player, slot):
        GameState.notify("Сохранено в слот %02d." % slot)
    _show_section("saves")

func _load_slot(slot: int) -> void:
    if not SaveManager.prepare_load(slot):
        return
    get_tree().paused = false
    get_tree().reload_current_scene()

func _delete_slot(slot: int) -> void:
    SaveManager.delete_slot(slot)
    _show_section("saves")

func _show_settings() -> void:
    _title("Настройки", "Настройки не спрятаны: управление, графика, звук и игра/интерфейс находятся здесь отдельными разделами.")
    _button("Управление и переназначение клавиш", Callable(self, "_show_section").bind("controls"))
    _button("Графика и разрешение", Callable(self, "_show_section").bind("graphics"))
    _button("Звук", Callable(self, "_show_section").bind("audio"))
    _button("Игра и интерфейс", Callable(self, "_show_section").bind("other"))
    _button("Сбросить все настройки", Callable(self, "_reset_settings"))

func _show_controls() -> void:
    _title("Управление", "Нажмите кнопку действия, затем новую клавишу или кнопку мыши.")
    rebinding_label = _body("Все основные игровые панели также можно переназначить.")
    for action in ACTION_LABELS:
        var row := HBoxContainer.new()
        content.add_child(row)
        var label := Label.new()
        label.text = String(ACTION_LABELS[action])
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var key_button := _button(SettingsManager.binding_text(action), Callable(self, "_begin_rebind").bind(action), row)
        key_button.custom_minimum_size.x = 160
    _button("← Назад к настройкам", Callable(self, "_show_section").bind("settings"))

func _begin_rebind(action: String) -> void:
    awaiting_action = action
    if is_instance_valid(rebinding_label):
        rebinding_label.text = "Нажмите новую кнопку для: %s" % String(ACTION_LABELS.get(action, action))

func _show_graphics() -> void:
    _title("Графика", "Изменения применяются сразу.")
    _add_checkbox("Полноэкранный режим", bool(SettingsManager.get_value("graphics", "fullscreen")), Callable(self, "_set_setting_bool").bind("graphics", "fullscreen"))
    _add_checkbox("Вертикальная синхронизация (VSync)", bool(SettingsManager.get_value("graphics", "vsync")), Callable(self, "_set_setting_bool").bind("graphics", "vsync"))
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
    _add_slider("Масштаб 3D-рендера", float(SettingsManager.get_value("graphics", "render_scale")), 0.5, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "render_scale"))
    _add_slider("Масштаб интерфейса", float(SettingsManager.get_value("graphics", "ui_scale")), 0.75, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "ui_scale"))
    _button("← Назад к настройкам", Callable(self, "_show_section").bind("settings"))

func _show_audio() -> void:
    _title("Звук", "Отдельная громкость игры, музыки и эффектов.")
    _add_slider("Общая громкость", float(SettingsManager.get_value("audio", "master_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "master_volume"))
    _add_slider("Музыка", float(SettingsManager.get_value("audio", "music_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "music_volume"))
    _add_slider("Эффекты", float(SettingsManager.get_value("audio", "sfx_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "sfx_volume"))
    _add_checkbox("Выключить весь звук", bool(SettingsManager.get_value("audio", "muted")), Callable(self, "_set_setting_bool").bind("audio", "muted"))
    _button("← Назад к настройкам", Callable(self, "_show_section").bind("settings"))

func _show_other() -> void:
    _title("Игра и интерфейс", "Камера, автосохранение и доступность интерфейса.")
    _add_slider("Чувствительность мыши", float(SettingsManager.get_value("gameplay", "mouse_sensitivity")), 0.001, 0.01, 0.0005, Callable(self, "_set_setting_float").bind("gameplay", "mouse_sensitivity"))
    _add_slider("Поле зрения (FOV)", float(SettingsManager.get_value("gameplay", "camera_fov")), 60.0, 100.0, 1.0, Callable(self, "_set_setting_float").bind("gameplay", "camera_fov"))
    _add_slider("Автосохранение, секунд", float(SettingsManager.get_value("gameplay", "autosave_seconds")), 30.0, 300.0, 30.0, Callable(self, "_set_setting_float").bind("gameplay", "autosave_seconds"))
    _add_checkbox("Субтитры", bool(SettingsManager.get_value("gameplay", "subtitles")), Callable(self, "_set_setting_bool").bind("gameplay", "subtitles"))
    _button("← Назад к настройкам", Callable(self, "_show_section").bind("settings"))

func _show_updates() -> void:
    _title("Обновления", "Проверка GitHub Release выполняется только по вашему запросу или фоновым updater после установки.")
    _button("Проверить обновления сейчас", Callable(UpdateManager, "check_for_updates"))
    update_status = _body("Обновления ещё не проверялись.")
    apply_update_button = _button("Обновить и перезапустить", Callable(UpdateManager, "install_latest_update"))
    apply_update_button.visible = UpdateManager.update_available

func _button(text: String, callback: Callable, parent: Container = null) -> Button:
    var target: Container = content if parent == null else parent
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 40
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.055, 0.075, 0.105, 0.96), Color(0.16, 0.34, 0.50, 0.75)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.075, 0.12, 0.17, 1.0), Color(0.25, 0.70, 0.92, 0.95)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.06, 0.08, 0.13, 1.0), Color(0.42, 0.48, 0.92, 1.0)))
    button.pressed.connect(callback)
    target.add_child(button)
    return button

func _body(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.78, 0.83, 0.89)
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
    slider.custom_minimum_size.x = 300
    slider.value_changed.connect(callback)
    row.add_child(slider)
    var value_label := Label.new()
    value_label.text = "%.2f" % value
    value_label.custom_minimum_size.x = 70
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
    _show_section("settings")

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status):
        update_status.text = text
    if is_instance_valid(apply_update_button):
        apply_update_button.visible = available

func _on_location_changed(location: String) -> void:
    if is_instance_valid(location_label):
        location_label.text = location

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.017, 0.027, 0.985)
    style.border_color = Color(0.16, 0.38, 0.55, 0.78)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    return style

func _content_panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.022, 0.030, 0.043, 0.96)
    style.border_color = Color(0.10, 0.22, 0.32, 0.85)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
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
