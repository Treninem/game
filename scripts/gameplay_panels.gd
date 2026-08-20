extends Control

const WORLD_MAP_VIEW = preload("res://scripts/world_map_view.gd")
const SECTIONS := [
    ["inventory", "[I] Инвентарь"],
    ["map", "[M] Карта"],
    ["crafting", "[K] Крафт"],
    ["journal", "[J] Журнал"],
    ["character", "Медальон"],
    ["dungeons", "Подземелья"],
    ["guild", "Гильдия"],
    ["plots", "Участки / VIP"],
    ["events", "Ивенты"]
]

var frame: PanelContainer
var content: VBoxContainer
var title_label: Label
var context_label: Label
var tab_buttons: Dictionary = {}
var current_section := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_force_pass_scroll_events = false
    _build_shell()
    call_deferred("_apply_responsive_layout")
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if DialogueManager.is_open:
        return
    var pause_menu := get_tree().get_first_node_in_group("game_menu") as Control
    if pause_menu != null and pause_menu.visible:
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
    else:
        open_panel(section)

func open_panel(section: String) -> void:
    var valid := false
    for entry in SECTIONS:
        if String(entry[0]) == section:
            valid = true
            break
    if not valid:
        section = "journal"
    current_section = section
    visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _apply_responsive_layout()
    _rebuild_content()

func close_panel() -> void:
    current_section = ""
    visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_shell() -> void:
    var shade := ColorRect.new()
    shade.color = Color(0.002, 0.005, 0.010, 0.78)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)

    var top_glow := ColorRect.new()
    top_glow.color = Color(0.02, 0.15, 0.23, 0.22)
    top_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top_glow.offset_bottom = 96.0
    top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(top_glow)

    frame = PanelContainer.new()
    frame.add_theme_stylebox_override("panel", _panel_style())
    add_child(frame)

    var outer := MarginContainer.new()
    outer.add_theme_constant_override("margin_left", 20)
    outer.add_theme_constant_override("margin_right", 20)
    outer.add_theme_constant_override("margin_top", 16)
    outer.add_theme_constant_override("margin_bottom", 16)
    frame.add_child(outer)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    outer.add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 48
    root.add_child(header)

    var header_text := VBoxContainer.new()
    header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_text)

    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 28)
    title_label.modulate = Color(0.90, 0.96, 1.0)
    header_text.add_child(title_label)

    context_label = Label.new()
    context_label.add_theme_font_size_override("font_size", 11)
    context_label.modulate = Color(0.46, 0.64, 0.76)
    header_text.add_child(context_label)

    var close := Button.new()
    close.text = "Закрыть  [Esc]"
    close.custom_minimum_size = Vector2(132, 40)
    close.focus_mode = Control.FOCUS_ALL
    close.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.055, 0.075, 0.98), Color(0.13, 0.30, 0.40, 0.9)))
    close.add_theme_stylebox_override("hover", _button_style(Color(0.055, 0.12, 0.16, 1.0), Color(0.24, 0.70, 0.90, 1.0)))
    close.pressed.connect(close_panel)
    header.add_child(close)

    root.add_child(HSeparator.new())

    var tabs := GridContainer.new()
    tabs.columns = 5
    tabs.add_theme_constant_override("h_separation", 7)
    tabs.add_theme_constant_override("v_separation", 6)
    root.add_child(tabs)
    for entry in SECTIONS:
        var section := String(entry[0])
        var tab := Button.new()
        tab.text = String(entry[1])
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.custom_minimum_size.y = 38
        tab.focus_mode = Control.FOCUS_ALL
        tab.add_theme_font_size_override("font_size", 12)
        tab.pressed.connect(Callable(self, "_switch_section").bind(section))
        tabs.add_child(tab)
        tab_buttons[section] = tab

    root.add_child(HSeparator.new())

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    scroll.mouse_force_pass_scroll_events = false
    root.add_child(scroll)

    var content_margin := MarginContainer.new()
    content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_margin.add_theme_constant_override("margin_left", 4)
    content_margin.add_theme_constant_override("margin_right", 12)
    content_margin.add_theme_constant_override("margin_top", 4)
    content_margin.add_theme_constant_override("margin_bottom", 12)
    scroll.add_child(content_margin)

    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 11)
    content_margin.add_child(content)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size.y = 26
    root.add_child(footer)
    var footer_left := Label.new()
    footer_left.text = "Колесо мыши — прокрутка • I / M / K / J — быстрые панели • остальные системы — вкладки"
    footer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer_left.add_theme_font_size_override("font_size", 11)
    footer_left.modulate = Color(0.42, 0.54, 0.64)
    footer.add_child(footer_left)
    var footer_right := Label.new()
    footer_right.text = "Мир приостановлен"
    footer_right.add_theme_font_size_override("font_size", 11)
    footer_right.modulate = Color(0.34, 0.66, 0.76)
    footer.add_child(footer_right)

func _apply_responsive_layout() -> void:
    if visible and not current_section.is_empty():
        _refresh_tabs()

func _switch_section(section: String) -> void:
    if current_section == section:
        return
    current_section = section
    _rebuild_content()

func _rebuild_content() -> void:
    for child in content.get_children():
        child.queue_free()
    _refresh_tabs()
    context_label.text = "%s   •   %s" % [GameState.current_location, _section_hint(current_section)]
    match current_section:
        "inventory": _show_inventory()
        "map": _show_map()
        "crafting": _show_crafting()
        "journal": _show_journal()
        "character": _show_character()
        "dungeons": _show_dungeons()
        "guild": _show_guild()
        "plots": _show_plots()
        "events": _show_events()
        _: close_panel()

func _refresh_tabs() -> void:
    for section in tab_buttons:
        var button: Button = tab_buttons[section]
        var selected := String(section) == current_section
        var bg := Color(0.045, 0.16, 0.22, 0.98) if selected else Color(0.025, 0.04, 0.055, 0.94)
        var border := Color(0.20, 0.72, 0.94, 0.98) if selected else Color(0.08, 0.20, 0.28, 0.78)
        button.add_theme_stylebox_override("normal", _button_style(bg, border))
        button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.07), border.lightened(0.12)))
        button.add_theme_color_override("font_color", Color(0.88, 0.97, 1.0) if selected else Color(0.64, 0.72, 0.79))

func _section_hint(section: String) -> String:
    match section:
        "inventory": return "экипировка и предметы"
        "map": return "исследование континента"
        "crafting": return "походные рецепты"
        "journal": return "цели и история"
        "character": return "ранг, уровень и медальон"
        "dungeons": return "5–10 этажей, боссы и скрытые этажи"
        "guild": return "состав, казна, рейтинг и войны"
        "plots": return "32×32 / 96×96 / 128×128 и VIP"
        "events": return "мировые события и мини-игры"
        _: return ""

func _show_inventory() -> void:
    title_label.text = "Инвентарь"
    var equipped := InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    var equipped_name := "Нет" if equipped.is_empty() else String(InventorySystem.item_info(equipped).get("name", equipped))
    _info("ЭКИПИРОВАНО", "%s • бонус атаки +%.0f" % [equipped_name, InventorySystem.attack_bonus()])
    _info("СТРАХОВАНИЕ", "Зарядов на одну смерть: %d" % ProgressionSystem.inventory_insurance_charges())
    _button("Купить страховку инвентаря — %d монет" % ProgressionSystem.INSURANCE_PRICE, Callable(self, "_buy_insurance"))
    var rows := InventorySystem.inventory_rows()
    if rows.is_empty():
        _text("Инвентарь пуст.")
        return
    var grid := GridContainer.new()
    grid.columns = 2 if frame.size.x >= 900.0 else 1
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    content.add_child(grid)
    for info in rows:
        _inventory_card(grid, info)

func _inventory_card(parent: GridContainer, info: Dictionary) -> void:
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.custom_minimum_size.y = 138
    card.add_theme_stylebox_override("panel", _row_style())
    parent.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 13)
    margin.add_theme_constant_override("margin_right", 13)
    margin.add_theme_constant_override("margin_top", 11)
    margin.add_theme_constant_override("margin_bottom", 11)
    card.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 6)
    margin.add_child(stack)
    var top := HBoxContainer.new()
    stack.add_child(top)
    var name := Label.new()
    name.text = String(info.get("name", ""))
    name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name.add_theme_font_size_override("font_size", 17)
    top.add_child(name)
    var amount := Label.new()
    amount.text = "×%d" % int(info.get("amount", 0))
    amount.modulate = Color(0.35, 0.82, 1.0)
    amount.add_theme_font_size_override("font_size", 16)
    top.add_child(amount)
    var desc := Label.new()
    desc.text = "%s • %s" % [String(info.get("category", "")), String(info.get("description", ""))]
    desc.modulate = Color(0.66, 0.73, 0.80)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(desc)
    var item_id := String(info.get("id", ""))
    var equip_slot := String(info.get("equip_slot", ""))
    if not equip_slot.is_empty():
        var label := "Экипировано" if InventorySystem.equipped_item(equip_slot) == item_id else "Экипировать"
        var action := _button(label, Callable(self, "_equip").bind(item_id), stack)
        action.disabled = label == "Экипировано"
    elif item_id in ["berries", "water_flask", "raw_meat", "cooked_meat"]:
        _button("Использовать", Callable(self, "_use_item").bind(item_id), stack)

func _show_map() -> void:
    title_label.text = "Карта мира"
    _text("Исследованные области открываются по мере путешествия. Тёмные территории и неизвестные точки не раскрываются заранее.")
    var map := WORLD_MAP_VIEW.new()
    map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map.custom_minimum_size.y = maxf(430.0, frame.size.y - 280.0)
    content.add_child(map)

func _show_crafting() -> void:
    title_label.text = "Крафт"
    _text("Походные рецепты доступны сразу из игры. Крупное строительство привязано к системе участков и правам владельца.")
    var grid := GridContainer.new()
    grid.columns = 2 if frame.size.x >= 900.0 else 1
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    content.add_child(grid)
    for recipe in InventorySystem.available_recipes():
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_stylebox_override("panel", _row_style())
        grid.add_child(card)
        var margin := MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 13)
        margin.add_theme_constant_override("margin_right", 13)
        margin.add_theme_constant_override("margin_top", 11)
        margin.add_theme_constant_override("margin_bottom", 11)
        card.add_child(margin)
        var stack := VBoxContainer.new()
        stack.add_theme_constant_override("separation", 7)
        margin.add_child(stack)
        var heading := Label.new()
        heading.text = String(recipe.get("name", ""))
        heading.add_theme_font_size_override("font_size", 17)
        stack.add_child(heading)
        var req := Label.new()
        req.text = "Нужно: %s" % InventorySystem.requirements_text(recipe.get("requirements", {}))
        req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        req.modulate = Color(0.66, 0.74, 0.81)
        stack.add_child(req)
        var craft := _button("Создать", Callable(self, "_craft").bind(String(recipe.get("id", ""))), stack)
        craft.disabled = not bool(recipe.get("can_craft", false))

func _show_journal() -> void:
    title_label.text = "Журнал"
    var medal := ProgressionSystem.medallion()
    _info("ПРОГРЕСС", "Ранг %s • уровень %d • опыт %d • заданий %d • подземелий %d" % [String(medal.get("rank", "H")), int(medal.get("level", 1)), int(medal.get("xp", 0)), int(medal.get("tasks", 0)), int(medal.get("dungeons", 0))])
    _info("СТОЛИЦА", "Люменград: территория 4 × 4 км, 32 ворот, защитный пояс, районы и ночное закрытие ворот.")
    _info("СИСТЕМЫ", "Работают ранги H→SSS+, группы, гильдии, подземелья, участки, VIP-ограничения, страхование, войны гильдий, ивенты и мини-игры.")

func _show_character() -> void:
    title_label.text = "Медальон игрока"
    var medal := ProgressionSystem.medallion()
    _info("ИМЯ", String(medal.get("name", "Странник")))
    _info("РАНГ И УРОВЕНЬ", "%s • уровень %d • опыт %d" % [String(medal.get("rank", "H")), int(medal.get("level", 1)), int(medal.get("xp", 0))])
    _info("ДОСТИЖЕНИЯ", "Задания: %d • подземелья: %d • гильдия: %s" % [int(medal.get("tasks", 0)), int(medal.get("dungeons", 0)), String(medal.get("guild", "Нет гильдии"))])
    var party := ProgressionSystem.party()
    var members: Array = party.get("members", [])
    _info("ГРУППА", "Участников: %d • глава: %s • заместитель: %s • средний ранг: %.2f" % [members.size(), String(party.get("leader", "player")), String(party.get("deputy", "нет")), ProgressionSystem.party_average_rank_index()])
    for member in members:
        if member is Dictionary:
            _text("• %s — ранг %s" % [String(member.get("name", member.get("id", ""))), ProgressionSystem.rank_name(int(member.get("rank_index", 0)))])

func _show_dungeons() -> void:
    title_label.text = "Подземелья"
    var state := ProgressionSystem.snapshot()
    if bool(state.get("in_dungeon", false)):
        var run := ProgressionSystem.dungeon_run()
        _info("ТЕКУЩИЙ ЗАБЕГ", "%s • ранг %s • этаж %d/%d • босс на %d этаже" % [String(run.get("name", "")), String(run.get("rank", "H")), int(run.get("current_floor", 1)), int(run.get("floor_count", 5)), int(run.get("boss_floor", 5))])
        if int(run.get("hidden_floor", -1)) > 0:
            _info("СКРЫТЫЙ ЭТАЖ", "Скрытый этаж существует в этом забеге. Он не раскрывается на карте заранее.")
        _button("Покинуть подземелье с частичной наградой", Callable(self, "_abort_dungeon"))
        return
    _text("Управляющий проверяет средний ранг группы, предупреждает о риске и открывает выбранный портал. Каждый забег содержит 5–10 этажей и босса на последнем этаже.")
    var grid := GridContainer.new()
    grid.columns = 2 if frame.size.x >= 900.0 else 1
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    content.add_child(grid)
    for dungeon in ProgressionSystem.dungeon_catalog():
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_stylebox_override("panel", _row_style())
        grid.add_child(card)
        var margin := MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 13)
        margin.add_theme_constant_override("margin_right", 13)
        margin.add_theme_constant_override("margin_top", 11)
        margin.add_theme_constant_override("margin_bottom", 11)
        card.add_child(margin)
        var stack := VBoxContainer.new()
        stack.add_theme_constant_override("separation", 6)
        margin.add_child(stack)
        var heading := Label.new()
        heading.text = "%s  [%s]" % [String(dungeon.get("name", "")), String(dungeon.get("rank", "H"))]
        heading.add_theme_font_size_override("font_size", 16)
        stack.add_child(heading)
        var warning := Label.new()
        warning.text = ProgressionSystem.dungeon_warning(String(dungeon.get("rank", "H")))
        warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        warning.modulate = Color(0.72, 0.75, 0.80)
        stack.add_child(warning)
        var reward := Label.new()
        reward.text = "База: %d монет • %d опыта" % [int(dungeon.get("reward_coins", 0)), int(dungeon.get("reward_xp", 0))]
        reward.modulate = Color(0.40, 0.80, 0.92)
        stack.add_child(reward)
        var start := _button("Открыть портал", Callable(self, "_start_dungeon").bind(String(dungeon.get("rank", "H"))), stack)
        start.disabled = not bool(dungeon.get("available", false))

func _show_guild() -> void:
    title_label.text = "Гильдия"
    var guild := ProgressionSystem.guild()
    if guild.is_empty():
        _text("Гильдия не зарегистрирована. Регистрация стоит 500 монет.")
        _button("Создать гильдию «Стражи Люменграда»", Callable(self, "_create_guild"))
        return
    _info("ГИЛЬДИЯ", "%s • рейтинг %d • побед %d • поражений %d" % [String(guild.get("name", "")), int(guild.get("rating", 1000)), int(guild.get("war_wins", 0)), int(guild.get("war_losses", 0))])
    _info("КАЗНА", "%d монет • участники: %d" % [int(guild.get("treasury", 0)), Array(guild.get("members", [])).size()])
    _button("Внести 100 монет в казну", Callable(self, "_guild_deposit"))
    _text("Война начинается только при взаимном согласии. Награда и захват территории считаются через арену и рейтинг; изъятие 10% казны ограничено одним разом в неделю.")
    _button("Начать согласованную войну с «Серебряным Клыком»", Callable(self, "_start_guild_war"))

func _show_plots() -> void:
    title_label.text = "Участки и VIP"
    var vip := ProgressionSystem.vip_status()
    _info("VIP", "Статус: %s • валюта полёта: %d • полёт: %s • creative: %s" % ["активен" if bool(vip.get("enabled", false)) else "не активен", int(vip.get("flight_currency", 0)), "вкл" if bool(vip.get("flight", false)) else "выкл", "вкл" if bool(vip.get("creative", false)) else "выкл"])
    if not bool(vip.get("enabled", false)):
        _button("Купить королевский VIP-пропуск — 2500 монет", Callable(self, "_purchase_vip"))
    else:
        _button("Купить 60 единиц валюты полёта — 120 монет", Callable(self, "_buy_flight_currency"))
        _button("Переключить VIP-полёт", Callable(self, "_toggle_flight"))
        _button("Переключить Creative на VIP-участке", Callable(self, "_toggle_creative"))
    _info("ПРАВИЛА", "Обычный участок 32×32 • VIP 96×96 • база гильдии 128×128. Полёт отключается в бою и подземельях. Creative не позволяет сундуки, передачу, валюту и редкие/квестовые предметы.")
    _button("Купить обычный участок 32×32 — %d" % ProgressionSystem.NORMAL_PLOT_PRICE, Callable(self, "_buy_plot").bind("normal"))
    _button("Купить VIP-участок 96×96 — %d" % ProgressionSystem.VIP_PLOT_PRICE, Callable(self, "_buy_plot").bind("vip"))
    _button("Купить базу гильдии 128×128 — %d" % ProgressionSystem.GUILD_PLOT_PRICE, Callable(self, "_buy_plot").bind("guild"))
    var plots: Array = ProgressionSystem.plots()
    if plots.is_empty():
        _text("Участков пока нет.")
    for plot in plots:
        if plot is Dictionary:
            var plot_id := String(plot.get("id", ""))
            _info("%s • %s" % [String(plot.get("type", "normal")).to_upper(), plot_id], "%d×%d • соседних участков: %d • владелец: %s" % [int(plot.get("size", 32)), int(plot.get("size", 32)), int(plot.get("parcels", 1)), String(plot.get("owner", "player"))])
            _button("Расширить владение", Callable(self, "_expand_plot").bind(plot_id))
            _button("Продать владение", Callable(self, "_sell_plot").bind(plot_id))

func _show_events() -> void:
    title_label.text = "Ивенты и мини-игры"
    var event_data := ProgressionSystem.active_event()
    _info("АКТИВНЫЙ ИВЕНТ", "%s • %s" % [String(event_data.get("name", "")), String(event_data.get("description", ""))])
    _button("Забрать награду активного ивента", Callable(self, "_claim_event"))
    _text("Мини-игры ведут рекорды и дают награды. Результат считается по набранным очкам; целевой результат указан в карточке.")
    for mini in ProgressionSystem.minigame_catalog():
        _info(String(mini.get("name", "")), "Рекорд %d • цель %d • награда %d монет" % [int(mini.get("record", 0)), int(mini.get("target", 0)), int(mini.get("reward_coins", 0))])
        _button("Пройти испытание", Callable(self, "_play_minigame").bind(String(mini.get("id", "")), int(mini.get("target", 0))))

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

func _buy_insurance() -> void:
    if not ProgressionSystem.buy_inventory_insurance():
        GameState.notify("Недостаточно монет для страховки.")
    _rebuild_content()

func _start_dungeon(rank_id: String) -> void:
    var result := ProgressionSystem.start_dungeon(rank_id)
    if bool(result.get("ok", false)):
        close_panel()
    else:
        GameState.notify("Вход недоступен: %s" % String(result.get("reason", "unknown")))
        _rebuild_content()

func _abort_dungeon() -> void:
    var runtime := get_tree().get_first_node_in_group("dungeon_runtime")
    if runtime != null and runtime.has_method("abort_current_dungeon"):
        runtime.call("abort_current_dungeon")
    else:
        ProgressionSystem.fail_dungeon(false)
    close_panel()

func _create_guild() -> void:
    ProgressionSystem.create_guild("Стражи Люменграда")
    _rebuild_content()

func _guild_deposit() -> void:
    if not ProgressionSystem.guild_deposit(100):
        GameState.notify("Не удалось внести монеты в казну.")
    _rebuild_content()

func _start_guild_war() -> void:
    var request := ProgressionSystem.request_guild_war("Серебряный Клык", true)
    if bool(request.get("ok", false)):
        GameState.notify("Война гильдий зарегистрирована по взаимному согласию.")
    else:
        GameState.notify("Война не зарегистрирована: %s" % String(request.get("reason", "unknown")))
    _rebuild_content()

func _purchase_vip() -> void:
    var vip := ProgressionSystem.vip_status()
    if bool(vip.get("enabled", false)):
        GameState.notify("VIP-пропуск уже активен.")
    elif GameState.coins < 2500:
        GameState.notify("Для VIP-пропуска требуется 2500 монет.")
    else:
        GameState.coins -= 2500
        ProgressionSystem.set_vip_enabled(true)
        GameState.notify("VIP-пропуск активирован.")
    _rebuild_content()

func _buy_flight_currency() -> void:
    var vip := ProgressionSystem.vip_status()
    if not bool(vip.get("enabled", false)):
        GameState.notify("Сначала активируйте VIP-пропуск.")
    elif GameState.coins < 120:
        GameState.notify("Недостаточно монет для валюты полёта.")
    else:
        GameState.coins -= 120
        ProgressionSystem.add_vip_flight_currency(60)
        GameState.notify("Валюта полёта пополнена на 60.")
    _rebuild_content()

func _toggle_flight() -> void:
    var active := ProgressionSystem.toggle_vip_flight()
    GameState.notify("VIP-полёт %s." % ("включён" if active else "выключен"))
    _rebuild_content()

func _toggle_creative() -> void:
    var vip := ProgressionSystem.vip_status()
    var target := not bool(vip.get("creative", false))
    if not ProgressionSystem.set_vip_creative(target):
        GameState.notify("Creative доступен только вне боя и подземелий.")
    _rebuild_content()

func _buy_plot(kind: String) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var pos := Vector2.ZERO
    if player != null:
        pos = Vector2(player.global_position.x, player.global_position.z)
    var result := ProgressionSystem.purchase_plot(kind, pos)
    if not bool(result.get("ok", false)):
        GameState.notify("Участок не куплен: %s" % String(result.get("reason", "unknown")))
    _rebuild_content()

func _expand_plot(plot_id: String) -> void:
    if not ProgressionSystem.expand_plot(plot_id):
        GameState.notify("Расширение недоступно.")
    _rebuild_content()

func _sell_plot(plot_id: String) -> void:
    ProgressionSystem.sell_plot(plot_id)
    _rebuild_content()

func _claim_event() -> void:
    if not ProgressionSystem.claim_event_reward():
        GameState.notify("Награда этого события уже получена.")
    _rebuild_content()

func _play_minigame(minigame_id: String, target: int) -> void:
    var state := ProgressionSystem.snapshot()
    var seed := int(state.get("xp", 0)) + int(state.get("tasks_completed", 0)) * 97 + int(Time.get_ticks_msec() / 250)
    var score := maxi(1, target - 180 + posmod(seed, 361))
    var result := ProgressionSystem.finish_minigame(minigame_id, score)
    GameState.notify("Результат: %d очков • награда %d монет." % [score, int(result.get("reward", 0))])
    _rebuild_content()

func _text(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.modulate = Color(0.72, 0.79, 0.86)
    label.add_theme_font_size_override("font_size", 14)
    content.add_child(label)
    return label

func _info(title: String, text: String) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _row_style())
    content.add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 11)
    margin.add_theme_constant_override("margin_bottom", 11)
    card.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 4)
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = title
    heading.modulate = Color(0.35, 0.80, 1.0)
    heading.add_theme_font_size_override("font_size", 11)
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
    button.custom_minimum_size.y = 38
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 13)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.045, 0.07, 0.095, 0.98), Color(0.12, 0.31, 0.43, 0.82)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.06, 0.15, 0.20, 1.0), Color(0.24, 0.72, 0.94, 1.0)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.035, 0.09, 0.13, 1.0), Color(0.38, 0.78, 1.0, 1.0)))
    button.pressed.connect(callback)
    target.add_child(button)
    return button

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.010, 0.016, 0.026, 0.992)
    style.border_color = Color(0.12, 0.46, 0.65, 0.92)
    style.set_border_width_all(1)
    style.set_corner_radius_all(14)
    style.shadow_color = Color(0, 0, 0, 0.54)
    style.shadow_size = 18
    return style

func _row_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.026, 0.043, 0.061, 0.97)
    style.border_color = Color(0.08, 0.23, 0.33, 0.82)
    style.set_border_width_all(1)
    style.set_corner_radius_all(9)
    return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.content_margin_left = 12
    style.content_margin_right = 12
    return style
