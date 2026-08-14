extends Control

const ICON_HEALTH = preload("res://assets/ui/icon_health.svg")
const ICON_STAMINA = preload("res://assets/ui/icon_stamina.svg")
const ICON_HUNGER = preload("res://assets/ui/icon_hunger.svg")
const ICON_THIRST = preload("res://assets/ui/icon_thirst.svg")
const ICON_QUEST = preload("res://assets/ui/icon_quest.svg")

var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var hp_value: Label
var stamina_value: Label
var hunger_value: Label
var thirst_value: Label
var quest_text: Label
var resources_text: Label
var combat_text: Label
var clock_text: Label
var location_text: Label
var economy_text: Label
var notice: Label
var notice_timer := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_hud()
    GameState.inventory_changed.connect(_refresh)
    GameState.quest_changed.connect(_refresh)
    GameState.survival_changed.connect(_refresh)
    GameState.location_changed.connect(_on_location_changed)
    GameState.notification_requested.connect(_show_notice)
    _refresh()

func _process(delta: float) -> void:
    if notice_timer > 0.0:
        notice_timer -= delta
        if notice_timer <= 0.0 and is_instance_valid(notice):
            notice.text = ""
            notice.visible = false

func _build_hud() -> void:
    var quest_card := PanelContainer.new()
    quest_card.position = Vector2(24, 24)
    quest_card.custom_minimum_size = Vector2(430, 82)
    quest_card.add_theme_stylebox_override("panel", _card_style(0.82))
    add_child(quest_card)

    var quest_margin := MarginContainer.new()
    quest_margin.add_theme_constant_override("margin_left", 14)
    quest_margin.add_theme_constant_override("margin_right", 16)
    quest_margin.add_theme_constant_override("margin_top", 11)
    quest_margin.add_theme_constant_override("margin_bottom", 11)
    quest_card.add_child(quest_margin)

    var quest_row := HBoxContainer.new()
    quest_row.add_theme_constant_override("separation", 12)
    quest_margin.add_child(quest_row)
    quest_row.add_child(_icon(ICON_QUEST, 34))
    var quest_box := VBoxContainer.new()
    quest_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    quest_row.add_child(quest_box)
    var quest_title := Label.new()
    quest_title.text = "ТЕКУЩАЯ ЦЕЛЬ"
    quest_title.modulate = Color(0.63, 0.78, 0.92)
    quest_title.add_theme_font_size_override("font_size", 12)
    quest_box.add_child(quest_title)
    quest_text = Label.new()
    quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_text.add_theme_font_size_override("font_size", 15)
    quest_box.add_child(quest_text)

    var vitals_card := PanelContainer.new()
    vitals_card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    vitals_card.position = Vector2(24, -196)
    vitals_card.custom_minimum_size = Vector2(340, 172)
    vitals_card.add_theme_stylebox_override("panel", _card_style(0.78))
    add_child(vitals_card)

    var vitals_margin := MarginContainer.new()
    vitals_margin.add_theme_constant_override("margin_left", 14)
    vitals_margin.add_theme_constant_override("margin_right", 14)
    vitals_margin.add_theme_constant_override("margin_top", 12)
    vitals_margin.add_theme_constant_override("margin_bottom", 12)
    vitals_card.add_child(vitals_margin)
    var vitals := VBoxContainer.new()
    vitals.add_theme_constant_override("separation", 7)
    vitals_margin.add_child(vitals)
    var hp = _vital_row(ICON_HEALTH, "Здоровье", Color(0.76, 0.18, 0.20))
    vitals.add_child(hp["root"])
    hp_bar = hp["bar"]
    hp_value = hp["value"]
    var st = _vital_row(ICON_STAMINA, "Выносливость", Color(0.22, 0.72, 0.42))
    vitals.add_child(st["root"])
    stamina_bar = st["bar"]
    stamina_value = st["value"]
    var hu = _vital_row(ICON_HUNGER, "Сытость", Color(0.86, 0.60, 0.20))
    vitals.add_child(hu["root"])
    hunger_bar = hu["bar"]
    hunger_value = hu["value"]
    var th = _vital_row(ICON_THIRST, "Жажда", Color(0.20, 0.60, 0.90))
    vitals.add_child(th["root"])
    thirst_bar = th["bar"]
    thirst_value = th["value"]

    var info_card := PanelContainer.new()
    info_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    info_card.position = Vector2(-354, 24)
    info_card.custom_minimum_size = Vector2(330, 132)
    info_card.add_theme_stylebox_override("panel", _card_style(0.76))
    add_child(info_card)
    var info_margin := MarginContainer.new()
    info_margin.add_theme_constant_override("margin_left", 14)
    info_margin.add_theme_constant_override("margin_right", 14)
    info_margin.add_theme_constant_override("margin_top", 10)
    info_margin.add_theme_constant_override("margin_bottom", 10)
    info_card.add_child(info_margin)
    var info_box := VBoxContainer.new()
    info_box.add_theme_constant_override("separation", 3)
    info_margin.add_child(info_box)
    location_text = Label.new()
    location_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    location_text.modulate = Color(0.52, 0.78, 0.96)
    location_text.add_theme_font_size_override("font_size", 13)
    info_box.add_child(location_text)
    clock_text = Label.new()
    clock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    clock_text.add_theme_font_size_override("font_size", 18)
    info_box.add_child(clock_text)
    economy_text = Label.new()
    economy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    economy_text.modulate = Color(0.90, 0.76, 0.40)
    economy_text.add_theme_font_size_override("font_size", 12)
    info_box.add_child(economy_text)
    resources_text = Label.new()
    resources_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    resources_text.modulate = Color(0.83, 0.87, 0.92)
    resources_text.add_theme_font_size_override("font_size", 12)
    info_box.add_child(resources_text)
    combat_text = Label.new()
    combat_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    combat_text.modulate = Color(0.66, 0.72, 0.80)
    combat_text.add_theme_font_size_override("font_size", 11)
    info_box.add_child(combat_text)

    var quick := HBoxContainer.new()
    quick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    quick.position = Vector2(-336, -76)
    quick.add_theme_constant_override("separation", 8)
    add_child(quick)
    quick.add_child(_quick_slot("1", "Ягоды"))
    quick.add_child(_quick_slot("2", "Вода"))
    quick.add_child(_quick_slot("3", "Мясо"))

    notice = Label.new()
    notice.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    notice.position = Vector2(260, -116)
    notice.size = Vector2(-520, 48)
    notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    notice.add_theme_font_size_override("font_size", 16)
    notice.add_theme_stylebox_override("normal", _card_style(0.88))
    notice.visible = false
    add_child(notice)

func _refresh() -> void:
    if not is_instance_valid(hp_bar):
        return
    hp_bar.max_value = GameState.max_health
    hp_bar.value = GameState.health
    hp_value.text = "%d/%d" % [roundi(GameState.health), roundi(GameState.max_health)]
    stamina_bar.value = GameState.stamina
    stamina_value.text = "%d" % roundi(GameState.stamina)
    hunger_bar.value = GameState.hunger
    hunger_value.text = "%d" % roundi(GameState.hunger)
    thirst_bar.value = GameState.thirst
    thirst_value.text = "%d" % roundi(GameState.thirst)
    quest_text.text = GameState.quest_text()
    location_text.text = GameState.current_location
    economy_text.text = "Монеты %d   •   Репутация города %d" % [GameState.coins, GameState.city_reputation]
    resources_text.text = "Дерево %d   Камень %d   Ягоды %d   Вода %d" % [
        int(GameState.inventory.get("wood", 0)),
        int(GameState.inventory.get("stone", 0)),
        int(GameState.inventory.get("berries", 0)),
        int(GameState.inventory.get("water_flask", 0))
    ]
    combat_text.text = "Побеждено: %d   •   %s" % [GameState.enemies_defeated, "Топор" if int(GameState.inventory.get("starter_axe", 0)) > 0 else "Без оружия"]
    var hour := int(GameState.world_minutes / 60.0) % 24
    var minute := int(GameState.world_minutes) % 60
    clock_text.text = "%02d:%02d" % [hour, minute]

func _on_location_changed(_location: String) -> void:
    _refresh()

func _show_notice(message: String) -> void:
    if not is_instance_valid(notice):
        return
    notice.text = "  " + message + "  "
    notice.visible = true
    notice_timer = 4.0

func _vital_row(texture: Texture2D, label_text: String, fill_color: Color) -> Dictionary:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 30
    row.add_theme_constant_override("separation", 8)
    row.add_child(_icon(texture, 23))
    var stack := VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 1)
    row.add_child(stack)
    var header := HBoxContainer.new()
    stack.add_child(header)
    var label := Label.new()
    label.text = label_text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 11)
    label.modulate = Color(0.82, 0.86, 0.91)
    header.add_child(label)
    var value := Label.new()
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value.add_theme_font_size_override("font_size", 11)
    header.add_child(value)
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 8
    bar.max_value = 100.0
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _bar_style(Color(0.08, 0.10, 0.14, 0.92)))
    bar.add_theme_stylebox_override("fill", _bar_style(fill_color))
    stack.add_child(bar)
    return {"root": row, "bar": bar, "value": value}

func _icon(texture: Texture2D, size_px: int) -> TextureRect:
    var icon := TextureRect.new()
    icon.texture = texture
    icon.custom_minimum_size = Vector2(size_px, size_px)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func _quick_slot(key: String, text: String) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(98, 50)
    card.add_theme_stylebox_override("panel", _card_style(0.74))
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 6)
    card.add_child(row)
    var key_label := Label.new()
    key_label.text = key
    key_label.add_theme_font_size_override("font_size", 17)
    row.add_child(key_label)
    var text_label := Label.new()
    text_label.text = text
    text_label.modulate = Color(0.78, 0.82, 0.88)
    text_label.add_theme_font_size_override("font_size", 12)
    row.add_child(text_label)
    return card

func _card_style(alpha: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.035, 0.055, alpha)
    style.border_color = Color(0.20, 0.45, 0.62, 0.48)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.shadow_color = Color(0, 0, 0, 0.28)
    style.shadow_size = 6
    return style

func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(4)
    return style
