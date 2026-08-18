extends Control

const WORLD_SCENE := "res://scenes/stage1.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const BG_PREFIX := "res://assets/production/ui/loading_bg_small.webp.b64"
const BG_PARTS := 4
const SCENE_WEIGHT := 0.34
const POLL_INTERVAL := 0.10
const REQUIRED_READY_FRAMES := 2
const EMBEDDED_TEXTURE := preload("res://scripts/embedded_ui_texture.gd")
const READINESS := preload("res://scripts/world_loading_readiness.gd")

var stage_label: Label
var detail_label: Label
var error_panel: PanelContainer
var fade_rect: ColorRect

var load_requested := false
var failed := false
var finishing := false
var ready_frames := 0
var poll_elapsed := 0.0
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

func _process(delta: float) -> void:
    if failed or finishing:
        return
    poll_elapsed += maxf(delta, 0.0)
    if poll_elapsed < POLL_INTERVAL:
        return
    poll_elapsed = 0.0
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if world_instance == null or not is_instance_valid(world_instance):
        _poll_scene_resource()
    else:
        _poll_prepared_world()

func _begin() -> void:
    _discard_world()
    failed = false
    finishing = false
    ready_frames = 0
    poll_elapsed = POLL_INTERVAL
    load_requested = false
    error_panel.visible = false
    _set_progress(0.0, "Подготовка мира", "")
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
    var real_ratio := 0.0
    if not progress.is_empty():
        var value: Variant = progress[0]
        if value is int or value is float:
            var numeric := float(value)
            if is_finite(numeric):
                real_ratio = clampf(numeric, 0.0, 1.0)
    _set_progress(real_ratio * SCENE_WEIGHT, "Загрузка мира", "" if real_ratio < 1.0 else "")
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
    _set_progress(SCENE_WEIGHT, "Создание игрового мира", "")
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
    if world_instance == null or not is_instance_valid(world_instance):
        ready_frames = 0
        return
    player = world_instance.get_node_or_null("World/Player") as CharacterBody3D
    if player == null or not is_instance_valid(player) or not player.is_inside_tree():
        ready_frames = 0
        _set_progress(SCENE_WEIGHT, "Подготовка игрока", "Создание игрока и стартовой области")
        return

    var state: Dictionary = READINESS.snapshot(world_instance, player)
    var world_ratio := _safe_ratio(state.get("ratio", 0.0))
    var total_ratio := SCENE_WEIGHT + (1.0 - SCENE_WEIGHT) * world_ratio
    var all_ready := bool(state.get("all_ready", false))
    var stage := String(state.get("stage", "Подготовка игрового мира"))
    var detail := String(state.get("detail", "Проверка обязательных систем"))

    if all_ready:
        ready_frames += 1
        stage = "Игровой мир готов"
        detail = "Финальная проверка"
    else:
        ready_frames = 0

    if ready_frames >= REQUIRED_READY_FRAMES:
        _set_progress(1.0, "Игровой мир готов", "")
        _finish_into_world()
    else:
        _set_progress(minf(total_ratio, 0.995), stage, detail)

func _finish_into_world() -> void:
    if finishing or world_instance == null or not is_instance_valid(world_instance):
        return
    var tree := get_tree()
    if tree == null or not is_inside_tree():
        return
    finishing = true
    fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    var to_black := create_tween()
    to_black.tween_property(fade_rect, "color:a", 1.0, 0.18)
    await to_black.finished
    if not is_inside_tree() or tree.current_scene == null:
        finishing = false
        return

    var prepared := world_instance
    world_instance = null
    prepared.set_meta("loading_gate_active", false)
    prepared.set_process(true)
    player = prepared.get_node_or_null("World/Player") as CharacterBody3D
    if player != null and is_instance_valid(player):
        player.set_meta("loading_gate_active", false)
        player.set_process(true)
        player.set_physics_process(true)
        player.set_process_input(true)
        player.set_process_unhandled_input(true)
    var world_ui := prepared.get_node_or_null("UI") as CanvasLayer
    if world_ui != null:
        world_ui.visible = true

    prepared.reparent(tree.root)
    tree.current_scene = prepared
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

func _safe_ratio(value: Variant) -> float:
    if value is int or value is float:
        var numeric := float(value)
        if is_finite(numeric):
            return clampf(numeric, 0.0, 1.0)
        return 0.0
    if value is String:
        var text := String(value).strip_edges()
        if text.is_valid_float():
            var numeric := text.to_float()
            if is_finite(numeric):
                return clampf(numeric, 0.0, 1.0)
    return 0.0

func _set_progress(_ratio: float, stage: String, detail: String) -> void:
    stage_label.text = stage
    detail_label.text = detail
    detail_label.visible = not detail.is_empty()

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
    texts.anchor_top = 0.735
    texts.anchor_right = 0.80
    texts.anchor_bottom = 0.835
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
