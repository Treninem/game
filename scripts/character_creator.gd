extends Control

const APPEARANCE := preload("res://scripts/character_appearance.gd")
const HUMANOID := preload("res://scripts/humanoid_visual.gd")
var profile: Dictionary = APPEARANCE.preset(0)
var selected_slot := 1
var actor: CharacterBody3D
var visual: Node3D
var camera: Camera3D
var viewport: SubViewport
var preview: SubViewportContainer
var name_edit: LineEdit
var sex_edit: OptionButton
var preset_edit: OptionButton
var status: Label
var traits: VBoxContainer
var rebuilding := false
var zoom := 3.4
var camera_height := 1.0
var trait_category := "face"
var advanced_mode := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    selected_slot = SaveManager.current_slot
    _style()
    _build()
    _refresh()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color(0.025, 0.036, 0.035)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 20)
    add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    margin.add_child(stack)
    var title := Label.new()
    title.text = "СОЗДАНИЕ ПЕРСОНАЖА"
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color(0.87, 0.77, 0.57))
    stack.add_child(title)
    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 16)
    stack.add_child(columns)
    var identity_scroll := ScrollContainer.new()
    identity_scroll.custom_minimum_size.x = 190
    identity_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    columns.add_child(identity_scroll)
    var identity := VBoxContainer.new()
    identity.custom_minimum_size.x = 190
    identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity_scroll.add_child(identity)
    _text(identity, "Ваше имя")
    name_edit = LineEdit.new()
    name_edit.name = "CharacterName"
    name_edit.max_length = 32
    name_edit.text_changed.connect(func(text: String): profile.name = text)
    identity.add_child(name_edit)
    _text(identity, "Основа")
    sex_edit = _choice(identity, ["Мужчина", "Женщина"], func(index: int):
        if not rebuilding:
            select_preset(index * 5))
    sex_edit.name = "SexSelection"
    _text(identity, "Готовый образ")
    preset_edit = _choice(identity, ["Образ I", "Образ II", "Образ III", "Образ IV", "Образ V"], func(index: int):
        if not rebuilding:
            select_preset(index + (5 if profile.sex == "female" else 0)))
    preset_edit.name = "PresetSelection"
    _text(identity, "Осмотрите лицо, одежду и движения перед началом путешествия.")
    _text(identity, "Настройки образа")
    _button(identity, "Лицо", func(): select_trait_category("face"))
    _button(identity, "Внешность и одежда", func(): select_trait_category("appearance"))
    _button(identity, "Телосложение", func(): select_trait_category("body"))
    var advanced := CheckButton.new()
    advanced.name = "AdvancedAppearance"
    advanced.text = "Подробно"
    advanced.toggled.connect(func(enabled: bool): advanced_mode = enabled; _refresh())
    identity.add_child(advanced)
    _button(identity, "В полный рост", func(): camera_height = 1.0; zoom = 3.4; _camera())
    _text(identity, "Движение для осмотра")
    var movement := _choice(identity, ["Покой", "Ходьба", "Бег", "Безоружный удар", "Топор", "Лук: натяжение", "Лук: выстрел"], select_preview_motion)
    movement.name = "PreviewMotion"
    _text(identity, "Оружие здесь только для осмотра. В начальный инвентарь оно не добавляется.")
    _text(identity, "Зажмите левую кнопку мыши, чтобы повернуть модель. Колесо — приближение.")
    preview = SubViewportContainer.new()
    preview.name = "CharacterPreview"
    preview.stretch = true
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.custom_minimum_size = Vector2(260, 260)
    columns.add_child(preview)
    viewport = SubViewport.new()
    viewport.own_world_3d = true
    viewport.msaa_3d = Viewport.MSAA_4X
    viewport.size = Vector2i(480, 580)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    preview.add_child(viewport)
    preview.gui_input.connect(_preview_input)
    var world := Node3D.new()
    viewport.add_child(world)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.07, 0.09, 0.095)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.78, 0.83, 0.88)
    environment.environment.ambient_light_energy = 0.55
    world.add_child(environment)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-35, -25, 0)
    key.light_energy = 1.5
    world.add_child(key)
    var fill := OmniLight3D.new()
    fill.position = Vector3(1.5, 2, -2)
    fill.omni_range = 6
    fill.light_energy = 1.3
    world.add_child(fill)
    camera = Camera3D.new()
    camera.fov = 37
    world.add_child(camera)
    _camera()
    actor = CharacterBody3D.new()
    actor.name = "AppearancePreview"
    actor.set_meta("preview_animation", "Idle")
    world.add_child(actor)
    visual = HUMANOID.new()
    visual.name = "Visual"
    visual.set("appearance_profile", profile)
    actor.add_child(visual)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size.x = 250
    columns.add_child(scroll)
    traits = VBoxContainer.new()
    traits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    traits.add_theme_constant_override("separation", 9)
    scroll.add_child(traits)
    status = Label.new()
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.custom_minimum_size.y = 30
    stack.add_child(status)
    var actions := HFlowContainer.new()
    actions.add_theme_constant_override("h_separation", 10)
    stack.add_child(actions)
    _button(actions, "Назад", func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    _button(actions, "Случайный образ", randomize_profile)
    _button(actions, "Сохранить образ", func():
        profile.name = name_edit.text
        status.text = "Образ сохранён." if APPEARANCE.save_look(profile) == OK else "Не удалось сохранить образ.")
    _button(actions, "Загрузить образ", func():
        var saved := APPEARANCE.load_look()
        if saved.is_empty(): status.text = "Сохранённого образа пока нет."
        else: profile = saved; _refresh(); status.text = "Образ загружен.")
    _button(actions, "Начать путешествие", start_journey).name = "StartJourney"

func _refresh() -> void:
    rebuilding = true
    profile = APPEARANCE.normalized(profile)
    name_edit.text = profile.name
    sex_edit.select(1 if profile.sex == "female" else 0)
    preset_edit.select(int(profile.preset) % 5)
    for child in traits.get_children():
        traits.remove_child(child)
        child.queue_free()
    _text(traits, {"face": "Лицо и голова", "appearance": "Внешность и одежда", "body": "Телосложение"}[trait_category])
    var appearance_choices := [["hair", "Причёска", ["Короткая", "Хвост"]], ["hair_color", "Волосы", ["Каштановые", "Тёмные", "Светлые", "Рыжие", "Седые"]], ["eye_color", "Цвет глаз", ["Карие", "Голубые", "Зелёные", "Серые", "Светло-голубые"]], ["skin", "Оттенок кожи", ["Светлый", "Смуглый", "Тёмный"]], ["cloth", "Одежда", ["Охра", "Зелёная", "Синяя", "Красная", "Льняная"]]]
    for pair in appearance_choices:
        if trait_category != "appearance":
            continue
        _text(traits, pair[1])
        var key: String = pair[0]
        var choice := _choice(traits, pair[2], func(index: int):
            profile[key] = index
            _apply_preview()
            if key == "eye_color":
                camera_height = 1.60
                zoom = 0.65
                _camera())
        choice.select(int(profile[key]))
        choice.name = key
    if trait_category == "body":
        var height_caption := Label.new()
        height_caption.text = "Рост: %d см" % int(profile.height_cm)
        traits.add_child(height_caption)
        var height_slider := HSlider.new()
        height_slider.name = "height_cm"
        height_slider.min_value = APPEARANCE.MIN_HEIGHT_CM
        height_slider.max_value = APPEARANCE.MAX_HEIGHT_CM
        height_slider.step = 1.0
        height_slider.value = float(profile.height_cm)
        height_slider.custom_minimum_size.y = 28
        height_slider.value_changed.connect(func(value: float):
            profile.height_cm = value
            height_caption.text = "Рост: %d см" % int(value)
            _apply_preview())
        traits.add_child(height_slider)
    for pair in [["HeadSize", "Размер головы"], ["FaceWidth", "Ширина лица"], ["FaceHeight", "Высота лица"], ["FaceDepth", "Глубина головы"], ["Nose", "Выступ носа"], ["NoseWidth", "Ширина носа"], ["NoseHeight", "Высота носа"], ["Jaw", "Подбородок"], ["Build", "Телосложение"]]:
        var key: String = pair[0]
        if trait_category == "appearance" or (trait_category == "body") != (key == "Build"):
            continue
        if not advanced_mode and key in ["FaceHeight", "FaceDepth", "NoseWidth", "NoseHeight"]:
            continue
        var line := HBoxContainer.new()
        traits.add_child(line)
        var caption := Label.new()
        caption.text = pair[1]
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(caption)
        var reset := Button.new()
        reset.text = "Сброс"
        reset.tooltip_text = "Вернуть исходную форму"
        line.add_child(reset)
        var slider := HSlider.new()
        slider.name = key
        slider.min_value = -0.5
        slider.max_value = 0.5
        slider.step = 0.01
        slider.value = float(profile[key])
        slider.custom_minimum_size.y = 28
        slider.value_changed.connect(func(value: float): profile[key] = value; _apply_preview())
        reset.pressed.connect(func(): slider.value = 0.0)
        if key != "Build":
            slider.drag_started.connect(func(): camera_height = 1.60; zoom = 0.85; _camera())
        traits.add_child(slider)
    rebuilding = false
    _apply_preview()

func select_trait_category(category: String) -> void:
    if category not in ["face", "appearance", "body"]:
        return
    trait_category = category
    camera_height = 1.60 if category == "face" else 1.0
    zoom = 0.85 if category == "face" else 3.4
    _camera()
    _refresh()

func select_preview_motion(index: int) -> void:
    index = clampi(index, 0, 6)
    var selector := find_child("PreviewMotion", true, false) as OptionButton
    if selector != null:
        selector.select(index)
    if index >= 4:
        camera_height = 1.1
        zoom = maxf(zoom, 3.9)
        _camera()
    actor.set_meta("preview_animation", ["Idle", "Walk", "Run", "Punch", "Axe_Chop", "Bow_Attack_Draw", "Bow_Attack_Shoot"][index])
    actor.set_meta("preview_item", ["", "", "", "", "starter_axe", "short_bow", "short_bow"][index])
    visual.call("_refresh_weapon")

func _apply_preview() -> void:
    if is_instance_valid(visual) and visual.has_method("apply_appearance"):
        visual.call("apply_appearance", profile)
        _camera()

func randomize_profile() -> void:
    var entered_name := name_edit.text.strip_edges()
    profile = APPEARANCE.preset(randi_range(0, 9))
    if entered_name not in ["", "Странник", "Странница"]:
        profile.name = entered_name
    for key in APPEARANCE.SHAPES:
        profile[key] = randf_range(-0.4, 0.4)
    profile.hair = randi_range(0, 1)
    profile.eye_color = randi_range(0, 4)
    profile.height_cm = randi_range(int(APPEARANCE.MIN_HEIGHT_CM), int(APPEARANCE.MAX_HEIGHT_CM))
    _refresh()

func select_preset(index: int) -> void:
    var entered_name := name_edit.text.strip_edges()
    profile = APPEARANCE.preset(index)
    if entered_name not in ["", "Странник", "Странница"]:
        profile.name = entered_name
    _refresh()

func _style() -> void:
    var creator_theme := Theme.new()
    creator_theme.default_font_size = 16
    for type: String in ["Button", "OptionButton", "LineEdit"]:
        for state: String in ["normal", "hover", "pressed", "focus"]:
            var panel := StyleBoxFlat.new()
            panel.bg_color = Color(0.075, 0.10, 0.09) if state == "normal" else Color(0.13, 0.17, 0.14)
            panel.border_color = Color(0.55, 0.49, 0.32) if state == "focus" else Color(0.25, 0.29, 0.25)
            panel.set_border_width_all(1)
            panel.set_corner_radius_all(6)
            panel.content_margin_left = 10
            panel.content_margin_right = 10
            panel.content_margin_top = 7
            panel.content_margin_bottom = 7
            creator_theme.set_stylebox(state, type, panel)
        creator_theme.set_color("font_color", type, Color(0.89, 0.89, 0.83))
    theme = creator_theme

func start_journey() -> void:
    profile.name = name_edit.text
    SaveManager.prepare_new_game(selected_slot, APPEARANCE.normalized(profile))
    var error := get_tree().change_scene_to_file("res://scenes/world_loading.tscn")
    if error != OK:
        status.text = "Не удалось начать путешествие. Код: %d" % error

func _camera() -> void:
    var ratio := float(profile.height_cm) / APPEARANCE.DEFAULT_HEIGHT_CM
    var head_clearance := 1.0 + maxf(float(profile.HeadSize), 0.0) * 0.28 if zoom < 1.5 else 1.0
    camera.position = Vector3(0, camera_height * ratio, -zoom * head_clearance)
    camera.look_at(Vector3(0, camera_height * ratio, 0))

func _preview_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
        actor.rotation.y += event.relative.x * 0.01
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom = maxf(0.65, zoom - 0.18)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom = minf(5, zoom + 0.18)
        _camera()

func _text(parent: Node, text: String) -> void:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 40
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _choice(parent: Node, items: Array, callback: Callable) -> OptionButton:
    var choice := OptionButton.new()
    choice.custom_minimum_size.y = 36
    for text in items:
        choice.add_item(text)
    choice.item_selected.connect(callback)
    parent.add_child(choice)
    return choice
