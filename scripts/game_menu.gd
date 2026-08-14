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
var initial_open := true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_shell()
    UpdateManager.status_changed.connect(_on_update_status_changed)
    SettingsManager.bindings_changed.connect(_refresh_current_if_controls)
    call_deferred("open_menu")

func _unhandled_input(event: InputEvent) -> void:
    if not awaiting_action.is_empty():
        if event is InputEventKey or event is InputEventMouseButton:
            if SettingsManager.rebind_action(awaiting_action, event):
                awaiting_action = ""
                _show_controls()
                get_viewport().set_input_as_handled()
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
    if initial_open:
        initial_open = false
    awaiting_action = ""
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_shell() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.015, 0.02, 0.035, 0.94)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(760, 560)
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-380, -280)
    add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    panel.add_child(margin)

    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    margin.add_child(content)

func _clear_content() -> void:
    awaiting_action = ""
    for child in content.get_children():
        child.queue_free()

func _title(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 28)
    content.add_child(label)

func _subtitle(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(label)
    return label

func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 42
    button.pressed.connect(callback)
    content.add_child(button)
    return button

func _back_button(callback: Callable = Callable(self, "_show_main")) -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 8
    content.add_child(spacer)
    _button("← Назад", callback)

func _show_main() -> void:
    _clear_content()
    _title("ImPuls")
    _subtitle("Версия %s • %s" % [String(ProjectSettings.get_setting("application/config/version", "development")), UpdateManager.local_build_tag()])
    _button("Продолжить", Callable(self, "close_menu"))
    _button("Сохранения — 10 слотов", Callable(self, "_show_saves"))
    _button("Настройки", Callable(self, "_show_settings"))
    _button("Проверить обновления", Callable(UpdateManager, "check_for_updates"))
    update_status = _subtitle("Обновления ещё не проверялись.")
    apply_update_button = _button("Обновить и перезапустить", Callable(UpdateManager, "install_latest_update"))
    apply_update_button.visible = UpdateManager.update_available
    _button("Выйти из игры", Callable(get_tree(), "quit"))

func _on_update_status_changed(text: String, available: bool) -> void:
    if is_instance_valid(update_status):
        update_status.text = text
    if is_instance_valid(apply_update_button):
        apply_update_button.visible = available

func _show_saves() -> void:
    _clear_content()
    _title("Сохранения")
    _subtitle("Можно создать, перезаписать, загрузить или удалить любой из 10 независимых слотов.")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 390
    content.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list)

    for info in SaveManager.list_slots():
        var slot := int(info["slot"])
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        list.add_child(row)

        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if bool(info.get("exists", false)):
            label.text = "Слот %02d  •  %s  •  время мира %s  •  этап задания %d" % [slot, String(info.get("saved_at", "")), String(info.get("world_time", "--:--")), int(info.get("quest_stage", 0))]
        else:
            label.text = "Слот %02d  •  пусто" % slot
        row.add_child(label)

        var save_button := Button.new()
        save_button.text = "Сохранить" if bool(info.get("exists", false)) else "Создать"
        save_button.pressed.connect(Callable(self, "_save_to_slot").bind(slot))
        row.add_child(save_button)

        var load_button := Button.new()
        load_button.text = "Загрузить"
        load_button.disabled = not bool(info.get("exists", false))
        load_button.pressed.connect(Callable(self, "_load_slot").bind(slot))
        row.add_child(load_button)

        var delete_button := Button.new()
        delete_button.text = "Удалить"
        delete_button.disabled = not bool(info.get("exists", false))
        delete_button.pressed.connect(Callable(self, "_delete_slot").bind(slot))
        row.add_child(delete_button)
    _back_button()

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
    _title("Настройки")
    _button("Управление", Callable(self, "_show_controls"))
    _button("Графика", Callable(self, "_show_graphics"))
    _button("Звук", Callable(self, "_show_audio"))
    _button("Игра и интерфейс", Callable(self, "_show_other"))
    _button("Сбросить всё по умолчанию", Callable(self, "_reset_settings"))
    _back_button()

func _show_controls() -> void:
    _clear_content()
    _title("Управление")
    rebinding_label = _subtitle("Нажмите кнопку действия, затем новую клавишу или кнопку мыши.")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.y = 390
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
        rebinding_label.text = "Ожидание новой кнопки для: %s" % String(ACTION_LABELS.get(action, action))

func _refresh_current_if_controls() -> void:
    if visible and not awaiting_action.is_empty():
        return

func _show_graphics() -> void:
    _clear_content()
    _title("Графика")
    _add_checkbox("Полноэкранный режим", bool(SettingsManager.get_value("graphics", "fullscreen")), Callable(self, "_set_setting_bool").bind("graphics", "fullscreen"))
    _add_checkbox("Вертикальная синхронизация (VSync)", bool(SettingsManager.get_value("graphics", "vsync")), Callable(self, "_set_setting_bool").bind("graphics", "vsync"))

    var resolution_row := HBoxContainer.new()
    content.add_child(resolution_row)
    var res_label := Label.new()
    res_label.text = "Разрешение"
    res_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    resolution_row.add_child(res_label)
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
    resolution_row.add_child(resolutions)

    _add_slider("Масштаб 3D-рендера", float(SettingsManager.get_value("graphics", "render_scale")), 0.5, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "render_scale"))
    _add_slider("Масштаб интерфейса", float(SettingsManager.get_value("graphics", "ui_scale")), 0.75, 1.5, 0.05, Callable(self, "_set_setting_float").bind("graphics", "ui_scale"))
    _back_button(Callable(self, "_show_settings"))

func _show_audio() -> void:
    _clear_content()
    _title("Звук")
    _add_slider("Общая громкость", float(SettingsManager.get_value("audio", "master_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "master_volume"))
    _add_slider("Музыка", float(SettingsManager.get_value("audio", "music_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "music_volume"))
    _add_slider("Эффекты", float(SettingsManager.get_value("audio", "sfx_volume")), 0.0, 1.0, 0.05, Callable(self, "_set_setting_float").bind("audio", "sfx_volume"))
    _add_checkbox("Выключить весь звук", bool(SettingsManager.get_value("audio", "muted")), Callable(self, "_set_setting_bool").bind("audio", "muted"))
    _back_button(Callable(self, "_show_settings"))

func _show_other() -> void:
    _clear_content()
    _title("Игра и интерфейс")
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
    slider.custom_minimum_size.x = 280
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

func _set_resolution(index: int, option: OptionButton) -> void:
    var size: Vector2i = option.get_item_metadata(index)
    SettingsManager.set_value("graphics", "resolution_width", size.x)
    SettingsManager.set_value("graphics", "resolution_height", size.y)

func _reset_settings() -> void:
    SettingsManager.reset_defaults()
    _show_settings()
