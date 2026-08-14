extends Control

var box: PanelContainer
var speaker_label: Label
var text_label: Label
var options_box: VBoxContainer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    DialogueManager.dialogue_opened.connect(_show_dialogue)
    DialogueManager.dialogue_closed.connect(_hide_dialogue)
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("pause_menu"):
        DialogueManager.close_dialogue()
        get_viewport().set_input_as_handled()

func _build() -> void:
    box = PanelContainer.new()
    box.custom_minimum_size = Vector2(760, 220)
    box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    box.position = Vector2(-380, -260)
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
    root.add_child(speaker_label)

    text_label = Label.new()
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.add_theme_font_size_override("font_size", 17)
    text_label.custom_minimum_size.y = 70
    root.add_child(text_label)

    options_box = VBoxContainer.new()
    options_box.add_theme_constant_override("separation", 6)
    root.add_child(options_box)

func _show_dialogue(speaker: String, text: String, options: Array) -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    speaker_label.text = speaker
    text_label.text = text
    for child in options_box.get_children():
        child.queue_free()
    if options.is_empty():
        options = [{"text": "Закрыть", "action": "close"}]
    for i in range(options.size()):
        var option = options[i]
        var button := Button.new()
        button.text = String(option.get("text", "Продолжить")) if typeof(option) == TYPE_DICTIONARY else "Продолжить"
        button.custom_minimum_size.y = 38
        button.pressed.connect(Callable(DialogueManager, "choose").bind(i))
        options_box.add_child(button)

func _hide_dialogue() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
