extends CanvasLayer

var root: PanelContainer
var spell_label: Label
var mana_bar: ProgressBar
var mana_value: Label
var shield_label: Label
var cooldown_label: Label

func _ready() -> void:
    layer = 12
    _build()
    GameState.survival_changed.connect(_refresh)
    MagicSystem.selected_spell_changed.connect(_on_spell_changed)
    _refresh()

func _process(_delta: float) -> void:
    if not is_instance_valid(root):
        return
    root.visible = get_tree().get_first_node_in_group("player") != null
    if not root.visible:
        return
    var spell_id := MagicSystem.selected_spell_id()
    var left := MagicSystem.cooldown_left(spell_id)
    cooldown_label.text = "Готово" if left <= 0.0 else "Кулдаун %.1f с" % left

func _build() -> void:
    root = PanelContainer.new()
    root.name = "MagicHUD"
    root.position = Vector2(22, 20)
    root.custom_minimum_size = Vector2(290, 112)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_theme_stylebox_override("panel", _panel_style())
    add_child(root)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_bottom", 9)
    root.add_child(margin)

    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 4)
    margin.add_child(stack)

    var title_row := HBoxContainer.new()
    stack.add_child(title_row)
    spell_label = Label.new()
    spell_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spell_label.add_theme_font_size_override("font_size", 14)
    spell_label.modulate = Color(0.70, 0.88, 1.0)
    title_row.add_child(spell_label)
    cooldown_label = Label.new()
    cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    cooldown_label.add_theme_font_size_override("font_size", 10)
    cooldown_label.modulate = Color(0.70, 0.76, 0.84)
    title_row.add_child(cooldown_label)

    var mana_header := HBoxContainer.new()
    stack.add_child(mana_header)
    var mana_text := Label.new()
    mana_text.text = "Мана"
    mana_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mana_text.add_theme_font_size_override("font_size", 10)
    mana_text.modulate = Color(0.62, 0.78, 1.0)
    mana_header.add_child(mana_text)
    mana_value = Label.new()
    mana_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    mana_value.add_theme_font_size_override("font_size", 10)
    mana_header.add_child(mana_value)

    mana_bar = ProgressBar.new()
    mana_bar.custom_minimum_size.y = 9
    mana_bar.show_percentage = false
    mana_bar.max_value = 100.0
    mana_bar.add_theme_stylebox_override("background", _bar_style(Color(0.06, 0.08, 0.13, 0.92)))
    mana_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.18, 0.48, 0.96, 0.95)))
    stack.add_child(mana_bar)

    shield_label = Label.new()
    shield_label.add_theme_font_size_override("font_size", 10)
    shield_label.modulate = Color(0.42, 0.78, 1.0)
    stack.add_child(shield_label)

    var hint := Label.new()
    hint.text = "ПКМ — применить   •   Q — следующее заклинание"
    hint.add_theme_font_size_override("font_size", 9)
    hint.modulate = Color(0.55, 0.61, 0.70)
    stack.add_child(hint)

func _refresh() -> void:
    if not is_instance_valid(root):
        return
    spell_label.text = "✦ %s" % MagicSystem.selected_spell_label()
    mana_bar.max_value = GameState.max_mana
    mana_bar.value = GameState.mana
    mana_value.text = "%d/%d" % [roundi(GameState.mana), roundi(GameState.max_mana)]
    shield_label.text = "Щит: %.0f" % GameState.magic_shield if GameState.magic_shield > 0.0 else "Щит: —"

func _on_spell_changed(_spell_id: String, _label: String) -> void:
    _refresh()

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.030, 0.055, 0.86)
    style.border_color = Color(0.16, 0.42, 0.70, 0.80)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 9
    style.corner_radius_top_right = 9
    style.corner_radius_bottom_left = 9
    style.corner_radius_bottom_right = 9
    return style

func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    return style
