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
var location_text: Label
var clock_text: Label
var quick_food: Label
var quick_water: Label
var notice: Label
var notice_timer := 0.0
var refresh_elapsed := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_hud()
    GameState.inventory_changed.connect(_refresh)
    GameState.survival_changed.connect(_refresh)
    GameState.location_changed.connect(_on_location_changed)
    GameState.notification_requested.connect(_show_notice)
    _refresh()

func _process(delta: float) -> void:
    refresh_elapsed += delta
    if refresh_elapsed >= 0.25:
        refresh_elapsed = 0.0
        _refresh()
    if notice_timer > 0.0:
        notice_timer -= delta
        if notice_timer <= 0.0 and is_instance_valid(notice):
            notice.visible = false

func _build_hud() -> void:
    _build_vitals()
    _build_minimap_card()
    _build_quickbar()
    _build_notice()

func _build_vitals() -> void:
    var card := PanelContainer.new()
    card.name = "VitalsCard"
    card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    card.offset_left = 18.0
    card.offset_top = -166.0
    card.offset_right = 304.0
    card.offset_bottom = -18.0
    card.add_theme_stylebox_override("panel", _card_style(0.80))
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

    var hp := _vital_row(ICON_HEALTH, "HP")
    stack.add_child(hp["root"])
    hp_bar = hp["bar"]
    hp_value = hp["value"]
    var stamina := _vital_row(ICON_STAMINA, "Выносливость")
    stack.add_child(stamina["root"])
    stamina_bar = stamina["bar"]
    stamina_value = stamina["value"]
    var hunger := _vital_row(ICON_HUNGER, "Сытость")
    stack.add_child(hunger["root"])
    hunger_bar = hunger["bar"]
    hunger_value = hunger["value"]
    var thirst := _vital_row(ICON_THIRST, "Жажда")
    stack.add_child(thirst["root"])
    thirst_bar = thirst["bar"]
    thirst_value = thirst["value"]

func _build_minimap_card() -> void:
    var holder := VBoxContainer.new()
    holder.name = "MinimapCard"
    holder.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    holder.offset_left = -274.0
    holder.offset_top = 18.0
    holder.offset_right = -18.0
    holder.offset_bottom = 332.0
    holder.add_theme_constant_override("separation", 6)
    add_child(holder)

    var minimap := MINIMAP_VIEW.new()
    minimap.name = "Minimap"
    minimap.custom_minimum_size = Vector2(256, 250)
    holder.add_child(minimap)

    var meta := PanelContainer.new()
    meta.custom_minimum_size.y = 56.0
    meta.add_theme_stylebox_override("panel", _card_style(0.82))
    holder.add_child(meta)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_bottom", 6)
    meta.add_child(margin)
    var stack := VBoxContainer.new()
    margin.add_child(stack)
    location_text = Label.new()
    location_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    location_text.modulate = Color(0.60, 0.84, 1.0)
    location_text.add_theme_font_size_override("font_size", 12)
    stack.add_child(location_text)
    clock_text = Label.new()
    clock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    clock_text.add_theme_font_size_override("font_size", 14)
    stack.add_child(clock_text)

func _build_quickbar() -> void:
    var card := PanelContainer.new()
    card.name = "Quickbar"
    card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    card.offset_left = 330.0
    card.offset_top = -76.0
    card.offset_right = -330.0
    card.offset_bottom = -18.0
    card.add_theme_stylebox_override("panel", _card_style(0.78))
    add_child(card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 7)
    margin.add_theme_constant_override("margin_bottom", 7)
    card.add_child(margin)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 8)
    margin.add_child(row)
    var food := _quick_slot("1", "Ягоды")
    row.add_child(food["root"])
    quick_food = food["count"]
    var water := _quick_slot("2", "Вода")
    row.add_child(water["root"])
    quick_water = water["count"]
    row.add_child(_hint_slot("I", "Инвентарь"))
    row.add_child(_hint_slot("M", "Карта"))
    row.add_child(_hint_slot("ESC", "Меню"))

func _build_notice() -> void:
    notice = Label.new()
    notice.name = "Notice"
    notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    notice.offset_left = -270.0
    notice.offset_top = -132.0
    notice.offset_right = 270.0
    notice.offset_bottom = -90.0
    notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    notice.add_theme_font_size_override("font_size", 14)
    notice.add_theme_stylebox_override("normal", _card_style(0.90))
    notice.visible = false
    add_child(notice)

func _vital_row(icon_texture: Texture2D, label_text: String) -> Dictionary:
    var root := HBoxContainer.new()
    root.custom_minimum_size.y = 25.0
    root.add_theme_constant_override("separation", 7)
    var icon := TextureRect.new()
    icon.texture = icon_texture
    icon.custom_minimum_size = Vector2(19, 19)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    root.add_child(icon)
    var label := Label.new()
    label.text = label_text
    label.custom_minimum_size.x = 92.0
    label.add_theme_font_size_override("font_size", 11)
    root.add_child(label)
    var bar := ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.show_percentage = false
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.custom_minimum_size = Vector2(94, 13)
    root.add_child(bar)
    var value := Label.new()
    value.custom_minimum_size.x = 42.0
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value.add_theme_font_size_override("font_size", 11)
    root.add_child(value)
    return {"root": root, "bar": bar, "value": value}

func _quick_slot(key: String, label_text: String) -> Dictionary:
    var root := VBoxContainer.new()
    root.custom_minimum_size = Vector2(78, 42)
    var label := Label.new()
    label.text = "%s  %s" % [key, label_text]
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 11)
    root.add_child(label)
    var count := Label.new()
    count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count.add_theme_font_size_override("font_size", 11)
    root.add_child(count)
    return {"root": root, "count": count}

func _hint_slot(key: String, label_text: String) -> Control:
    var label := Label.new()
    label.text = "%s  %s" % [key, label_text]
    label.custom_minimum_size = Vector2(92, 42)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 11)
    return label

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
    var hour := int(GameState.world_minutes / 60.0) % 24
    var minute := int(GameState.world_minutes) % 60
    clock_text.text = "%02d:%02d" % [hour, minute]
    quick_food.text = "×%d" % int(GameState.inventory.get("berries", 0))
    quick_water.text = "×%d" % int(GameState.inventory.get("water_flask", 0))

func _on_location_changed(_location: String) -> void:
    _refresh()

func _show_notice(message: String) -> void:
    if not is_instance_valid(notice):
        return
    notice.text = message
    notice.visible = true
    notice_timer = 4.0

func _card_style(alpha: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.025, 0.042, alpha)
    style.border_color = Color(0.16, 0.48, 0.68, 0.70)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    return style
