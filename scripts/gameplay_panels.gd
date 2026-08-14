extends Control

const WORLD_MAP_VIEW = preload("res://scripts/world_map_view.gd")

var panel: PanelContainer
var title_label: Label
var content: VBoxContainer
var current_section := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_shell()
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if DialogueManager.is_open:
        return
    if event.is_action_pressed("open_inventory"):
        _toggle("inventory")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_map"):
        _toggle("map")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_crafting"):
        _toggle("crafting")
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("open_journal"):
        _toggle("journal")
        get_viewport().set_input_as_handled()
        return
    if visible and event.is_action_pressed("pause_menu"):
        close_panel()
        get_viewport().set_input_as_handled()

func _toggle(section: String) -> void:
    if visible and current_section == section:
        close_panel()
        return
    open_panel(section)

func open_panel(section: String) -> void:
    current_section = section
    visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _rebuild_content()

func close_panel() -> void:
    current_section = ""
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_shell() -> void:
    var shade := ColorRect.new()
    shade.color = Color(0.005, 0.008, 0.014, 0.68)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 42
    panel.offset_top = 34
    panel.offset_right = -42
    panel.offset_bottom = -34
    panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)

    var header := HBoxContainer.new()
    root.add_child(header)
    title_label = Label.new()
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 27)
    header.add_child(title_label)
    var hint := Label.new()
    hint.text = "I инвентарь   M карта   K крафт   J журнал   Esc закрыть"
    hint.modulate = Color(0.58, 0.68, 0.78)
    hint.add_theme_font_size_override("font_size", 12)
    header.add_child(hint)

    root.add_child(HSeparator.new())
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    scroll.add_child(content)

func _rebuild_content() -> void:
    for child in content.get_children():
        child.queue_free()
    match current_section:
        "inventory": _show_inventory()
        "map": _show_map()
        "crafting": _show_crafting()
        "journal": _show_journal()
        _: close_panel()

func _show_inventory() -> void:
    title_label.text = "Инвентарь и экипировка"
    var equipped := InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    var equipped_name := "Нет" if equipped.is_empty() else String(InventorySystem.item_info(equipped).get("name", equipped))
    _info("Экипировано", "%s   •   бонус атаки +%.0f" % [equipped_name, InventorySystem.attack_bonus()])

    var rows := InventorySystem.inventory_rows()
    if rows.is_empty():
        _text("Инвентарь пуст.")
        return
    for info in rows:
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _row_style())
        content.add_child(card)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        card.add_child(row)
        var stack := VBoxContainer.new()
        stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(stack)
        var name := Label.new()
        name.text = "%s ×%d" % [String(info.get("name", "")), int(info.get("amount", 0))]
        name.add_theme_font_size_override("font_size", 17)
        stack.add_child(name)
        var desc := Label.new()
        desc.text = "%s  •  %s" % [String(info.get("category", "")), String(info.get("description", ""))]
        desc.modulate = Color(0.70, 0.76, 0.84)
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        stack.add_child(desc)

        var item_id := String(info.get("id", ""))
        var equip_slot := String(info.get("equip_slot", ""))
        if not equip_slot.is_empty():
            var txt := "Экипировано" if InventorySystem.equipped_item(equip_slot) == item_id else "Экипировать"
            var b := _button(txt, Callable(self, "_equip").bind(item_id), row)
            b.custom_minimum_size.x = 145
        elif item_id in ["berries", "water_flask", "raw_meat", "cooked_meat"]:
            var use := _button("Использовать", Callable(self, "_use_item").bind(item_id), row)
            use.custom_minimum_size.x = 135

func _show_map() -> void:
    title_label.text = "Карта мира"
    _text("Открытые территории показаны цветом. Неисследованные области остаются скрытыми. Голубой маркер — персонаж.")
    var map := WORLD_MAP_VIEW.new()
    map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map.custom_minimum_size.y = 560
    content.add_child(map)

func _show_crafting() -> void:
    title_label.text = "Крафт"
    _text("Рецепты доступны напрямую из игры. Материалы списываются только после успешного создания.")
    var recipes := InventorySystem.available_recipes()
    if recipes.is_empty():
        _text("Пока нет изученных рецептов.")
        return
    for recipe in recipes:
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _row_style())
        content.add_child(card)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        card.add_child(row)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.text = "%s\nНужно: %s" % [String(recipe.get("name", "")), InventorySystem.requirements_text(recipe.get("requirements", {}))]
        row.add_child(label)
        var craft := _button("Создать", Callable(self, "_craft").bind(String(recipe.get("id", ""))), row)
        craft.custom_minimum_size.x = 130
        craft.disabled = not bool(recipe.get("can_craft", false))

func _show_journal() -> void:
    title_label.text = "Журнал заданий"
    var intro_status := "Не начато"
    if GameState.quest_stage > 0 and GameState.quest_stage < 4:
        intro_status = "Активно"
    elif GameState.quest_stage >= 4:
        intro_status = "Завершено"
    _info("Первое убежище  •  " + intro_status, GameState.quest_text() if GameState.quest_stage < 4 else "Поручение Миры завершено.")

    var city_status := "Не начато"
    if GameState.city_quest_stage == 1:
        city_status = "Активно"
    elif GameState.city_quest_stage >= 2:
        city_status = "Завершено"
    var city_text := "Поговорите с кузнецом Раданом."
    if GameState.city_quest_stage == 1:
        city_text = "Принесите 6 камня и 4 древесины для ремонта ворот."
    elif GameState.city_quest_stage >= 2:
        city_text = "Ремонт ворот завершён, награда получена."
    _info("Ремонт Южных ворот  •  " + city_status, city_text)
    _text("Монеты: %d   •   Репутация Люменграда: %d   •   Побеждено существ: %d" % [GameState.coins, GameState.city_reputation, GameState.enemies_defeated])

func _equip(item_id: String) -> void:
    InventorySystem.equip(item_id)
    _rebuild_content()

func _craft(recipe_id: String) -> void:
    InventorySystem.craft(recipe_id)
    _rebuild_content()

func _use_item(item_id: String) -> void:
    if item_id == "cooked_meat":
        if GameState.remove_item(item_id, 1):
            GameState.hunger = minf(100.0, GameState.hunger + 45.0)
            GameState.health = minf(GameState.max_health, GameState.health + 5.0)
            GameState.survival_changed.emit()
            GameState.notify("Вы съели жареное мясо.")
    else:
        GameState.use_consumable(item_id)
    _rebuild_content()

func _text(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.76, 0.82, 0.89)
    label.add_theme_font_size_override("font_size", 14)
    content.add_child(label)
    return label

func _info(title: String, text: String) -> void:
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
    heading.modulate = Color(0.48, 0.76, 0.95)
    heading.add_theme_font_size_override("font_size", 12)
    stack.add_child(heading)
    var body := Label.new()
    body.text = text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 15)
    stack.add_child(body)

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

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.017, 0.027, 0.985)
    style.border_color = Color(0.16, 0.45, 0.66, 0.86)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.shadow_color = Color(0, 0, 0, 0.38)
    style.shadow_size = 10
    return style

func _row_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.047, 0.066, 0.96)
    style.border_color = Color(0.10, 0.25, 0.36, 0.72)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 10
    style.content_margin_bottom = 10
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
