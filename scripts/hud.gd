extends Control

const ICON_HEALTH = preload("res://assets/ui/icon_health.svg")
const ICON_STAMINA = preload("res://assets/ui/icon_stamina.svg")
const ICON_HUNGER = preload("res://assets/ui/icon_hunger.svg")
const ICON_THIRST = preload("res://assets/ui/icon_thirst.svg")
const MINIMAP_VIEW = preload("res://scripts/minimap_view.gd")

var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var hp_value: Label
var stamina_value: Label
var hunger_value: Label
var thirst_value: Label
var clock_text: Label
var location_text: Label
var economy_text: Label
var quick_food: Label
var quick_water: Label
var quick_meat: Label
var notice: Label
var notice_timer := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_hud()
    GameState.inventory_changed.connect(_refresh)
    GameState.survival_changed.connect(_refresh)
    GameState.location_changed.connect(_on_location_changed)
    GameState.notification_requested.connect(_show_notice)
    _refresh()

func _process(delta: float) -> void:
    if notice_timer > 0.0:
        notice_timer -= delta
        if notice_timer <= 0.0 and is_instance_valid(notice):
            notice.visible = false

func _build_hud() -> void:
    _build_vitals()
    _build_minimap()
    _build_quickbar()
    _build_notice()

func _build_vitals() -> void:
    var card := PanelContainer.new()
    card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    card.position = Vector2(22, -166)
    card.custom_minimum_size = Vector2(278, 144)
    card.add_theme_stylebox_override("panel", _card_style(0.72))
    add_child(card)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    card.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 5)
    margin.add_child(stack)

    var hp = _vital_row(ICON_HEALTH, "HP", Color(0.78, 0.18, 0.20))
    stack.add_child(hp["root"])
    hp_bar = hp["bar"]
    hp_value = hp["value"]
    var st = _vital_row(ICON_STAMINA, "Выносливость", Color(0.20, 0.72, 0.42))
    stack.add_child(st["root"])
    stamina_bar = st["bar"]
    stamina_value = st["value"]
    var hu = _vital_row(ICON_HUNGER, "Сытость", Color(0.86, 0.60, 0.20))
    stack.add_child(hu["root"])
    hunger_bar = hu["bar"]
    hunger_value = hu["value"]
    var th = _vital_row(ICON_THIRST, "Жажда", Color(0.20, 0.60, 0.90))
    stack.add_child(th["root"])
    thirst_bar = th["bar"]
    thirst_value = th["value"]

func _build_minimap() -> void:
    var holder := VBoxContainer.new()
    holder.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    holder.position = Vector2(-272, 20)
    holder.custom_minimum_size = Vector2(250, 0)
    holder.add_theme_constant_override("separation", 5)
    add_child(holder)

    var minimap := MINIMAP_VIEW.new()
    minimap.custom_minimum_size = Vector2(250, 250)
    holder.add_child(minimap)

    var meta := PanelContainer.new()
    meta.add_theme_stylebox_override("panel", _card_style(0.70))
    holder.add_child(meta)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 7)
    margin.add_theme_constant_override("margin_bottom", 7)
    meta.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 1)
    margin.add_child(stack)
    location_text = Label.new()
    location_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    location_text.modulate = Color(0.54, 0.78, 0.96)
    location_text.add_theme_font_size_override("font_size", 11)
    stack.add_child(location_text)
    var row := HBoxContainer.new()
    stack.add_child(row)
    economy_text = Label.new()
    economy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    economy_text.modulate = Color(0.92, 0.76, 0.38)
    economy_text.add_theme_font_size_override("font_size", 11)
    row.add_child(economy_text)
    clock_text = Label.new()
    clock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    clock_text.add_theme_font_size_override("font_size", 14)
    row.add_child(clock_text)

func _build_quickbar() -> void:
    var quick := HBoxContainer.new()
    quick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    quick.position = Vector2(-435, -70)
    quick.add_theme_constant_override("separation", 7)
    add_child(quick)
    var food = _quick_slot("1", "Ягоды")
    quick.add_child(food["root"])
    quick_food = food["count"]
    var water = _quick_slot("2", "Вода")
    quick.add_child(water["root"])
    quick_water = water["count"]
    var meat = _quick_slot("3", "Еда")
    quick.add_child(meat["root"])
    quick_meat = meat["count"]
    quick.add_child(_hint_slot("I", "Инвентарь"))
    quick.add_child(_hint_slot("M", "Карта"))

func _build_notice() -> void:
    notice = Label.new()
    notice.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    notice.position = Vector2(300, -112)
    notice.size = Vector2(-600, 44)
    notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    notice.add_theme_font_size_override("font_size", 14)
    notice.add_theme_stylebox_override("normal", _card_style(0.86))
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
    location_text.text = GameState.current_location
    economy_text.text = "◈ %d   ★ %d" % [GameState.coins, GameState.city_reputation]
    quick_food.text = "×%d" % int(GameState.inventory.get("berries", 0))
    quick_water.text = "×%d" % int(GameState.inventory.get("water_flask", 0))
    var cooked := int(GameState.inventory.get("cooked_meat", 0))
    var raw := int(GameState.inventory.get("raw_meat", 0))
    quick_meat.text = "×%d" % (cooked if cooked > 0 else raw)
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
    notice_timer = 3.5

func _vital_row(texture: Texture2D, label_text: String, fill_color: Color) -> Dictionary:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 26
    row.add_theme_constant_override("separation", 7)
    row.add_child(_icon(texture, 20))
    var stack := VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 0)
    row.add_child(stack)
    var header := HBoxContainer.new()
    stack.add_child(header)
    var label := Label.new()
    label.text = label_text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 10)
    label.modulate = Color(0.80, 0.85, 0.91)
    header.add_child(label)
    var value := Label.new()
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value.add_theme_font_size_override("font_size", 10)
    header.add_child(value)
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 6
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

func _quick_slot(key: String, text: String) -> Dictionary:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(78, 46)
    card.add_theme_stylebox_override("panel", _card_style(0.72))
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    card.add_child(stack)
    var top := HBoxContainer.new()
    top.alignment = BoxContainer.ALIGNMENT_CENTER
    top.add_theme_constant_override("separation", 5)
    stack.add_child(top)
    var key_label := Label.new()
    key_label.text = key
    key_label.add_theme_font_size_override("font_size", 14)
    top.add_child(key_label)
    var count := Label.new()
    count.modulate = Color(0.72, 0.82, 0.91)
    count.add_theme_font_size_override("font_size", 11)
    top.add_child(count)
    var label := Label.new()
    label.text = text
    label.modulate = Color(0.68, 0.74, 0.82)
    label.add_theme_font_size_override("font_size", 9)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stack.add_child(label)
    return {"root": card, "count": count}

func _hint_slot(key: String, text: String) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(88, 46)
    card.add_theme_stylebox_override("panel", _card_style(0.62))
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    card.add_child(stack)
    var key_label := Label.new()
    key_label.text = key
    key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    key_label.add_theme_font_size_override("font_size", 13)
    stack.add_child(key_label)
    var text_label := Label.new()
    text_label.text = text
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text_label.modulate = Color(0.64, 0.70, 0.78)
    text_label.add_theme_font_size_override("font_size", 9)
    stack.add_child(text_label)
    return card

func _card_style(alpha: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.035, 0.055, alpha)
    style.border_color = Color(0.18, 0.44, 0.62, 0.46)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.shadow_color = Color(0, 0, 0, 0.28)
    style.shadow_size = 5
    return style

func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(4)
    return style
