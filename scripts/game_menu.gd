extends Control

const APP_ICON = preload("res://assets/branding/impuls_icon.svg")

const ACTION_LABELS := {
    "move_forward": "Движение вперёд",
    "move_back": "Движение назад",
    "move_left": "Движение влево",
    "move_right": "Движение вправо",
    "sprint": "Бег",
    "jump": "Прыжок",
    "interact": "Взаимодействие",
    "attack": "Атака",
    "craft": "Крафт",
    "build": "Строительство",
    "use_food": "Быстрая еда",
    "use_water": "Быстрая вода",
    "quick_save": "Быстрое сохранение",
    "quick_load": "Быстрая загрузка",
    "pause_menu": "Меню / пауза"
}

var panel: PanelContainer
var content: VBoxContainer
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
    call_deferred("open_menu")

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
            open_menu()
        get_viewport().set_input_as_handled()

func open_menu() -> void:
    visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _show_main()

func close_menu() -> void:
    awaiting_action = ""
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_shell() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.008, 0.012, 0.022, 0.94)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(820, 640)
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-410, -320)
    panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 26)
    margin.add_theme_constant_override("margin_bottom", 26)
    panel.add_child(margin)

    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 9)
    margin.add_child(content)

func _clear_content() -> void:
    awaiting_action = ""
    for child in content.get_children():
        child.queue_free()

func _brand_header(section_title: String = "") -> void:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 12)
    content.add_child(row)
    var icon := TextureRect.new()
    icon.texture = APP_ICON
    icon.custom_minimum_size = Vector2(54, 54)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(icon)
    var stack := VBoxContainer.new()
    row.add_child(stack)
    var brand := Label.new()
    brand.text = "ImPuls"
    brand.add_theme_font_size_override("font_size", 28)
    stack.add_child(brand)
    if not section_title.is_empty():
        var section := Label.new()
        section.text = section_title
        section.modulate = Color(0.56, 0.76, 0.93)
        section.add_theme_font_size_override("font_size", 13)
        stack.add_child(section)

func _subtitle(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.72, 0.78, 0.86)
    content.add_child(label)
    return label

func _button(text: String, callback: Callable, parent: Container = null) -> Button:
    var target: Container = content if parent == null else parent
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 42
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.055, 0.075, 0.11, 0.96), Color(0.18, 0.38, 0.55, 0.7)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.075, 0.12, 0.18, 1.0), Color(0.25, 0.70, 0.92, 0.95)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.09, 0.17, 1.0), Color(0.48, 0.34, 0.92, 1.0)))
    button.pressed.connect(callback)
    target.add_child(button)
    return button

func _back_button(callback: Callable) -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 5
    content.add_child(spacer)
    _button("← Назад", callback)

func _show_main() -> void:
    _clear_content()
    _brand_header("ГЛАВНОЕ МЕНЮ")
    _subtitle("Версия %s  •  %s" % [String(ProjectSettings.get_setting("application/config/version", "development")), UpdateManager.local_build_tag()])
    _button("Продолжить игру", Callable(self, "close_menu"))
    _button("Инвентарь и экипировка", Callable(self, "_show_inventory"))
    _button("Крафт", Callable(self, "_show_crafting"))
    _button("Журнал заданий", Callable(self, "_show_journal"))
    _button("Сохранения  •  10 слотов", Callable(self, "_show_saves"))
    _button("Настройки", Callable(self, "_show_settings"))
    _button("Проверить обновления", Callable(UpdateManager, "check_for_updates"))
    update_status = _subtitle("Обновления ещё не проверялись.")
    apply_update_button = _button("Обновить и перезапустить", Callable(UpdateManager, "install_latest_update"))
    apply_update_button.visible = UpdateManager.update_available
    _button("Выйти из игры", Callable(get_tree(), "quit"))

func _show_inventory() -> void:
    _clear_content()
    _brand_header("ИНВЕНТАРЬ И ЭКИПИРОВКА")
    var weapon_id := InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    var weapon_name := "не выбрано" if weapon_id.is_empty() else String(InventorySystem.item_info(weapon_id).get("name", weapon_id))
    _subtitle("Оружие: %s  •  бонус атаки +%.0f" % [weapon_name, InventorySystem.attack_bonus()])
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 440
    content.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 7)
    scroll.add_child(list)
    var rows := InventorySystem.inventory_rows()
    if rows.is_empty():
        var empty := Label.new()
        empty.text = "Инвентарь пуст."
        list.add_child(empty)
    for info in rows:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        list.add_child(row)
        var text := Label.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        text.text = "%s ×%d\n%s  •  %s" % [String(info.get("name", "")), int(info.get("amount", 0)), String(info.get("category", "")), String(info.get("description", ""))]
        row.add_child(text)
        var item_id := String(info.get("id", ""))
        if not String(info.get("equip_slot", "")).is_empty():
            var equip_text := "Экипировано" if InventorySystem.equipped_item(String(info.get("equip_slot", ""))) == item_id else "Экипировать"
            _button(equip_text, Callable(self, "_equip_item").bind(item_id), row).custom_minimum_size.x = 130
        elif item_id in ["berries", "water_flask", "raw_meat", "cooked_meat"]:
            _button("Использовать", Callable(self, "_use_item").bind(item_id), row).custom_minimum_size.x = 120
    _back_button(Callable(self, "_show_main"))

func _equip_item(item_id: String) -> void:
    InventorySystem.equip(item_id)
    _show_inventory()

func _use_item(item_id: String) -> void:
    if item_id == "cooked_meat":
        if GameState.remove_item(item_id, 1):
            GameState.hunger = minf(100.0, GameState.hunger + 45.0)
            GameState.health = minf(GameState.max_health, GameState.health + 5.0)
            GameState.survival_changed.emit()
            GameState.notify("Вы съели жареное мясо.")
    else:
        GameState.use_consumable(item_id)
    _show_inventory()

func _show_crafting() -> void:
    _clear_content()
    _brand_header("КРАФТ")
    _subtitle("Рецепты открываются по мере прогресса. Материалы списываются только при успешном создании.")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 440
    content.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)
    var recipes := InventorySystem.available_recipes()
    if recipes.is_empty():
        var empty := Label.new()
        empty.text = "Пока нет доступных рецептов."
        list.add_child(empty)
    for recipe in recipes:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        list.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "%s\nНужно: %s" % [String(recipe.get("name", "")), InventorySystem.requirements_text(recipe.get("requirements", {}))]
        row.add_child(label)
        var craft_button := _button("Создать", Callable(self, "_craft_recipe").bind(String(recipe.get("id", ""))), row)
        craft_button.custom_minimum_size.x = 120
        craft_button.disabled = not bool(recipe.get("can_craft", false))
    _back_button(Callable(self, "_show_main"))

func _craft_recipe(recipe_id: String) -> void:
    InventorySystem.craft(recipe_id)
    _show_crafting()

func _show_journal() -> void:
    _clear_content()
    _brand_header("ЖУРНАЛ ЗАДАНИЙ")
    var status := "Активно"
    if GameState.quest_stage == 0:
        status = "Не начато"
    elif GameState.quest_stage >= 4:
        status = "Завершено"
    _subtitle("ПЕРВОЕ УБЕЖИЩЕ  •  %s" % status)
    var body := Label.new()
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 17)
    body.text = "Мира помогает освоиться в окрестностях.\n\nТекущая цель:\n%s\n\nПрогресс ресурсов: древесина %d / 8, камень %d / 4.\nПостроено убежище: %s.\nПобеждено существ: %d." % [GameState.quest_text(), int(GameState.inventory.get("wood", 0)), int(GameState.inventory.get("stone", 0)), "да" if GameState.house_built else "нет", GameState.enemies_defeated]
    content.add_child(body)
    _back_button(Callable(self, "_show_main"))

func _show_saves() -> void:
    _clear_content()
    _brand_header("СОХРАНЕНИЯ")
    _subtitle("10 независимых слотов: создание, перезапись, загрузка и удаление.")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 420
    content.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 7)
    scroll.add_child(list)
    for info in SaveManager.list_slots():
        var slot := int(info["slot"])
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 7)
        list.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.text = "Слот %02d  •  %s  •  %s" % [slot, String(info.get("saved_at", "пусто")) if bool(info.get("exists", false)) else "пусто", String(info.get("world_time", "--:--"))]
        row.add_child(label)
        _button("Создать" if not bool(info.get("exists", false)) else "Сохранить", Callable(self, "_save_to_slot").bind(slot), row).custom_minimum_size.x = 92
        var load_button := _button("Загрузить", Callable(self, "_load_slot").bind(slot), row)
        load_button.custom_minimum_size.x = 92
        load_button.disabled = not bool(info.get("exists", false))
        var delete_button := _button("Удалить", Callable(self, "_delete_slot").bind(slot), row)
        delete_button.custom_minimum_size.x = 82
        delete_button.disabled = not bool(info.get("exists", false))
    _back_button(Callable(self, "_show_main"))

func _save_to_slot(slot: int) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null and SaveManager.save_game(player, slot):
        GameState.notify("Сохранено в слот %02d." % slot)
    _show_saves()

func _load_slot(slot: int) -> void:
    if not SaveManager.prepare_load(slot):
        return
    get_tree().paused = false
    get_tree().reload_current_scene()

func _delete_slot(slot: int) -> void:
    SaveManager.delete_slot(slot)
    _show_saves()

func _show_settings() -> void:
    _clear_content()
    _brand_header("НАСТРОЙКИ")
    _button("Управление", Callable(self, "_show_controls"))
    _button("Графика", Callable(self, "_show_graphics"))
    _button("Звук", Callable(self, "_show_audio"))
    _button("Игра и интерфейс", Callable(self, "_show_other"))
    _button("Сбросить настройки", Callable(self, "_reset_settings"))
    _back_button(Callable(self, "_show_main"))

func _show_controls() -> void:
    _clear_content()
    _brand_header("УПРАВЛЕНИЕ")
    rebinding_label = _subtitle("Нажмите действие, затем новую клавишу или кнопку мыши.")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 430
    content.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list)
    for action in ACTION_LABELS:
        var row := HBoxContainer.new()
        list.add_child(row)
        var label := Label.new()
        label.text = String(ACTION_LABELS[action])
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var key_button := Button.new()
        key_button.text = SettingsManager.binding_text(action)
        key_button.custom_minimum_size.x = 150
        key_button.pressed.connect(Callable(self, "_begin_rebind").bind(action))
        row.add_child(key_button)
    _back_button(Callable(self, "_show_settings"))

func _begin_rebind(action: String) -> void:
    awaiting_action = action
    if is_instance_valid(rebinding_label):
        rebinding_label.text = "Нажмите новую кнопку для: %s" % String(ACTION_LABELS.get(action, action))

func _show_graphics() -> void:
    _clear_content()
    _brand_header("ГРАФИКА")
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
    _back_button(Callable(self, "_show_settings"))

func _show_audio() -> void:
    _clear_content()
    _brand_header("ЗВУК")
    _add_slider("Общая громкость", float(SettingsManager.get_value("audio", "master_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "master_volume"))
    _add_slider("Музыка", float(SettingsManager.get_value("audio", "music_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "music_volume"))
    _add_slider("Эффекты", float(SettingsManager.get_value("audio", "sfx_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "sfx_volume"))
    _add_checkbox("Выключить весь звук", bool(SettingsManager.get_value("audio", "muted")), Callable(self, "_set_setting_bool").bind("audio", "muted"))
    _back_button(Callable(self, "_show_settings"))

func _show_other() -> void:
    _clear_content()
    _brand_header("ИГРА И ИНТЕРФЕЙС")
    _add_slider("Чувствительность мыши", float(SettingsManager.get_value("gameplay", "mouse_sensitivity")), 0.001, 0.01, 0.0005, Callable(self, "_set_setting_float").bind("gameplay", "mouse_sensitivity"))
    _add_slider("Поле зрения (FOV)", float(SettingsManager.get_value("gameplay", "camera_fov")), 60.0, 100.0, 1.0, Callable(self, "_set_setting_float").bind("gameplay", "camera_fov"))
    _add_slider("Автосохранение, секунд", float(SettingsManager.get_value("gameplay", "autosave_seconds")), 30.0, 300.0, 30.0, Callable(self, "_set_setting_float").bind("gameplay", "autosave_seconds"))
    _add_checkbox("Субтитры", bool(SettingsManager.get_value("gameplay", "subtitles")), Callable(self, "_set_setting_bool").bind("gameplay", "subtitles"))
    _back_button(Callable(self, "_show_settings"))

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
    _show_settings()

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status):
        update_status.text = text
    if is_instance_valid(apply_update_button):
        apply_update_button.visible = available

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.045, 0.98)
    style.border_color = Color(0.22, 0.68, 0.92, 0.7)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_left = 18
    style.corner_radius_bottom_right = 18
    return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.content_margin_left = 14
    style.content_margin_right = 14
    return style
