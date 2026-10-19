extends Control

var box: PanelContainer
var speaker_label: Label
var text_label: Label
var options_box: VBoxContainer
var content_scroll: ScrollContainer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    get_viewport().size_changed.connect(_fit_dialogue)
    DialogueManager.dialogue_opened.connect(_show_dialogue)
    DialogueManager.dialogue_closed.connect(_hide_dialogue)
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("pause_menu"):
        DialogueManager.close_dialogue()
        get_viewport().set_input_as_handled()

func _build() -> void:
    box = PanelContainer.new()
    box.set_anchors_preset(Control.PRESET_TOP_LEFT)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.025, 0.045, 0.97)
    style.border_color = Color(0.22, 0.68, 0.92, 0.82)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 16
    style.corner_radius_top_right = 16
    style.corner_radius_bottom_left = 16
    style.corner_radius_bottom_right = 16
    box.add_theme_stylebox_override("panel", style)
    add_child(box)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    box.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)

    speaker_label = Label.new()
    speaker_label.add_theme_font_size_override("font_size", 22)
    speaker_label.modulate = Color(0.4, 0.85, 1.0)
    speaker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(speaker_label)

    content_scroll = ScrollContainer.new()
    content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    content_scroll.follow_focus = true
    content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(content_scroll)
    var body := VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 10)
    content_scroll.add_child(body)

    text_label = Label.new()
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.add_theme_font_size_override("font_size", 17)
    text_label.custom_minimum_size.y = 70
    body.add_child(text_label)

    options_box = VBoxContainer.new()
    options_box.add_theme_constant_override("separation", 6)
    body.add_child(options_box)

func _fit_dialogue() -> void:
    if box == null:
        return
    var area := get_viewport_rect().size
    var width := maxf(1.0, minf(760.0, area.x - 32.0))
    var available := maxf(1.0, minf(560.0, area.y - 32.0))
    var height := minf(available, maxf(220.0, 164.0 + float(options_box.get_child_count()) * 44.0))
    box.size = Vector2(width, height)
    box.position = Vector2((area.x - width) * 0.5, area.y - height - 16.0)

func _show_dialogue(speaker: String, text: String, options: Array) -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    speaker_label.text = speaker
    text_label.text = text
    for child in options_box.get_children():
        options_box.remove_child(child)
        child.queue_free()
    if options.is_empty():
        options = [{"text": "Закрыть", "action": "close"}]
    for i in range(options.size()):
        var option = options[i]
        var button := Button.new()
        button.text = String(option.get("text", "Продолжить")) if typeof(option) == TYPE_DICTIONARY else "Продолжить"
        button.custom_minimum_size.y = 38
        button.clip_text = true
        button.pressed.connect(Callable(DialogueManager, "choose").bind(i))
        options_box.add_child(button)
    content_scroll.scroll_vertical = 0
    _fit_dialogue()

func _hide_dialogue() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    get_tree().paused = false
    SettingsManager.capture_gameplay_mouse()
