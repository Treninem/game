extends Control

const WORLD_SCENE := "res://scenes/stage1.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const BG_PREFIX := "res://assets/production/ui/loading_bg_small.webp.b64"
const BG_PARTS := 4
const SCENE_WEIGHT := 0.34
const EMBEDDED_TEXTURE := preload("res://scripts/embedded_ui_texture.gd")
const READINESS := preload("res://scripts/world_loading_readiness.gd")

var progress_bar: ProgressBar
var percent_label: Label
var stage_label: Label
var detail_label: Label
var error_panel: PanelContainer
var fade_rect: ColorRect

var load_requested := false
var failed := false
var finishing := false
var ready_frames := 0
var world_resource: PackedScene
var world_instance: Node
var player: CharacterBody3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_ui()
    call_deferred("_begin")

func _process(_delta: float) -> void:
    if failed or finishing:
        return
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if world_instance == null:
        _poll_scene_resource()
    else:
        _poll_prepared_world()

func _begin() -> void:
    _discard_world()
    failed = false
    finishing = false
    ready_frames = 0
    load_requested = false
    error_panel.visible = false
    _set_progress(0.0, "Подготовка загрузки", "Проверка обязательных ресурсов")
    for path in [WORLD_SCENE, "res://scripts/world_streamer.gd", "res://scripts/world_settlements.gd", "res://scripts/bootstrap.gd"]:
        if not ResourceLoader.exists(path):
            _fail("Отсутствует обязательный ресурс: %s" % path)
            return
    var err := ResourceLoader.load_threaded_request(WORLD_SCENE, "PackedScene", true)
    if err != OK:
        _fail("Не удалось начать фоновую загрузку мира. Код: %s" % err)
        return
    load_requested = true

func _poll_scene_resource() -> void:
    if not load_requested:
        return
    var progress: Array = []
    var status := ResourceLoader.load_threaded_get_status(WORLD_SCENE, progress)
    var real_ratio := clampf(float(progress[0]), 0.0, 1.0) if not progress.is_empty() else 0.0
    _set_progress(real_ratio * SCENE_WEIGHT, "Загрузка основной сцены", "Ресурсы сцены: %d%%" % roundi(real_ratio * 100.0))
    if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        _fail("Основная сцена мира не загрузилась. Проверьте целостность установленной версии.")
        return
    if status != ResourceLoader.THREAD_LOAD_LOADED:
        return
    var resource = ResourceLoader.load_threaded_get(WORLD_SCENE)
    if not (resource is PackedScene):
        _fail("Загруженный ресурс мира имеет неверный тип.")
        return
    world_resource = resource as PackedScene
    _instantiate_behind_loading_screen()

func _instantiate_behind_loading_screen() -> void:
    _set_progress(SCENE_WEIGHT, "Создание игрового мира", "Сцена создаётся за непрозрачным экраном загрузки")
    world_instance = world_resource.instantiate()
    if world_instance == null:
        _fail("Не удалось создать игровую сцену.")
        return
    world_instance.set_meta("loading_gate_active", true)
    world_instance.set_process(false)
    player = world_instance.get_node_or_null("World/Player") as CharacterBody3D
    if player != null:
        player.set_meta("loading_gate_active", true)
        player.set_process(false)
        player.set_physics_process(false)
        player.set_process_input(false)
        player.set_process_unhandled_input(false)
    var world_ui := world_instance.get_node_or_null("UI") as CanvasLayer
    if world_ui != null:
        world_ui.visible = false
    add_child(world_instance)
    move_child(world_instance, 0)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _poll_prepared_world() -> void:
    player = world_instance.get_node_or_null("World/Player") as CharacterBody3D
    var state := READINESS.snapshot(world_instance, player)
    var world_ratio := clampf(float(state.get("ratio", 0.0)), 0.0, 1.0)
    var total_ratio := SCENE_WEIGHT + (1.0 - SCENE_WEIGHT) * world_ratio
    var all_ready := bool(state.get("all_ready", false))
    var stage := String(state.get("stage", "Подготовка игрового мира"))
    var detail := String(state.get("detail", "Проверка обязательных систем"))

    if all_ready:
        ready_frames += 1
        stage = "Игровой мир готов"
        detail = "Финальная физическая проверка %d/2" % mini(ready_frames, 2)
    else:
        ready_frames = 0

    if ready_frames >= 2:
        _set_progress(1.0, "Игровой мир готов", "Земля, коллизии, окружение, объекты, NPC и камера подтверждены")
        _finish_into_world()
    else:
        _set_progress(minf(total_ratio, 0.995), stage, detail)

func _finish_into_world() -> void:
    if finishing or world_instance == null:
        return
    finishing = true
    fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    var to_black := create_tween()
    to_black.tween_property(fade_rect, "color:a", 1.0, 0.18)
    await to_black.finished

    var prepared := world_instance
    world_instance = null
    prepared.set_meta("loading_gate_active", false)
    prepared.set_process(true)
    player = prepared.get_node_or_null("World/Player") as CharacterBody3D
    if player != null:
        player.set_meta("loading_gate_active", false)
        player.set_process(true)
        player.set_physics_process(true)
        player.set_process_input(true)
        player.set_process_unhandled_input(true)
    var world_ui := prepared.get_node_or_null("UI") as CanvasLayer
    if world_ui != null:
        world_ui.visible = true

    prepared.reparent(get_tree().root)
    get_tree().current_scene = prepared
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    var fade_layer := CanvasLayer.new()
    fade_layer.layer = 4095
    prepared.add_child(fade_layer)
    var world_fade := ColorRect.new()
    world_fade.color = Color(0, 0, 0, 1)
    world_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    world_fade.mouse_filter = Control.MOUSE_FILTER_STOP
    fade_layer.add_child(world_fade)
    var reveal := prepared.create_tween()
    reveal.tween_property(world_fade, "color:a", 0.0, 0.22)
    reveal.finished.connect(fade_layer.queue_free)
    queue_free()

func _retry() -> void:
    _begin()

func _return_to_menu() -> void:
    _discard_world()
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _discard_world() -> void:
    if world_instance != null and is_instance_valid(world_instance):
        world_instance.queue_free()
    world_instance = null
    world_resource = null
    player = null

func _fail(message: String) -> void:
    failed = true
    load_requested = false
    stage_label.text = "Не удалось загрузить мир"
    detail_label.text = message
    error_panel.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _set_progress(ratio: float, stage: String, detail: String) -> void:
    var safe := clampf(ratio, 0.0, 1.0)
    progress_bar.value = safe * 100.0
    percent_label.text = "%d%%" % roundi(safe * 100.0)
    stage_label.text = stage
    detail_label.text = detail

func _build_ui() -> void:
    var background := TextureRect.new()
    background.texture = EMBEDDED_TEXTURE.load_webp_parts(BG_PREFIX, BG_PARTS)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var shade := ColorRect.new()
    shade.color = Color(0.01, 0.015, 0.025, 0.10)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

    var texts := VBoxContainer.new()
    texts.anchor_left = 0.20
    texts.anchor_top = 0.705
    texts.anchor_right = 0.80
    texts.anchor_bottom = 0.825
    texts.alignment = BoxContainer.ALIGNMENT_END
    texts.add_theme_constant_override("separation", 2)
    add_child(texts)

    stage_label = Label.new()
    stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stage_label.add_theme_font_size_override("font_size", 22)
    stage_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.68))
    stage_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.95))
    stage_label.add_theme_constant_override("shadow_offset_x", 2)
    stage_label.add_theme_constant_override("shadow_offset_y", 2)
    texts.add_child(stage_label)

    detail_label = Label.new()
    detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_label.add_theme_font_size_override("font_size", 14)
    detail_label.add_theme_color_override("font_color", Color(0.82, 0.81, 0.78))
    detail_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.95))
    texts.add_child(detail_label)

    var bar_holder := Control.new()
    bar_holder.anchor_left = 0.235
    bar_holder.anchor_top = 0.833
    bar_holder.anchor_right = 0.765
    bar_holder.anchor_bottom = 0.902
    add_child(bar_holder)

    progress_bar = ProgressBar.new()
    progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    progress_bar.offset_left = 34
    progress_bar.offset_right = -34
    progress_bar.offset_top = 18
    progress_bar.offset_bottom = -18
    progress_bar.min_value = 0
    progress_bar.max_value = 100
    progress_bar.show_percentage = false
    var empty := StyleBoxFlat.new()
    empty.bg_color = Color(0.015, 0.012, 0.012, 0.70)
    empty.set_corner_radius_all(3)
    progress_bar.add_theme_stylebox_override("background", empty)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color(0.72, 0.46, 0.18, 0.96)
    fill.border_color = Color(0.96, 0.75, 0.34, 0.95)
    fill.set_border_width_all(1)
    fill.set_corner_radius_all(3)
    progress_bar.add_theme_stylebox_override("fill", fill)
    bar_holder.add_child(progress_bar)

    percent_label = Label.new()
    percent_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    percent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    percent_label.add_theme_font_size_override("font_size", 15)
    percent_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.72))
    percent_label.add_theme_color_override("font_shadow_color", Color(0,0,0,1))
    percent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar_holder.add_child(percent_label)

    error_panel = PanelContainer.new()
    error_panel.anchor_left = 0.5
    error_panel.anchor_top = 0.5
    error_panel.anchor_right = 0.5
    error_panel.anchor_bottom = 0.5
    error_panel.offset_left = -270
    error_panel.offset_top = -110
    error_panel.offset_right = 270
    error_panel.offset_bottom = 110
    var error_style := StyleBoxFlat.new()
    error_style.bg_color = Color(0.035, 0.025, 0.025, 0.97)
    error_style.border_color = Color(0.62, 0.35, 0.20, 0.95)
    error_style.set_border_width_all(2)
    error_style.set_corner_radius_all(8)
    error_panel.add_theme_stylebox_override("panel", error_style)
    add_child(error_panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    error_panel.add_child(margin)
    var error_stack := VBoxContainer.new()
    error_stack.add_theme_constant_override("separation", 10)
    margin.add_child(error_stack)
    var error_title := Label.new()
    error_title.text = "Загрузка остановлена"
    error_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    error_title.add_theme_font_size_override("font_size", 20)
    error_stack.add_child(error_title)
    var retry := Button.new()
    retry.text = "Повторить загрузку"
    retry.custom_minimum_size.y = 42
    retry.pressed.connect(_retry)
    error_stack.add_child(retry)
    var menu := Button.new()
    menu.text = "Вернуться в главное меню"
    menu.custom_minimum_size.y = 42
    menu.pressed.connect(_return_to_menu)
    error_stack.add_child(menu)
    error_panel.visible = false

    fade_rect = ColorRect.new()
    fade_rect.color = Color(0, 0, 0, 0)
    fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fade_rect)
