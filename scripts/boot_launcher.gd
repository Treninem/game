extends Control

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

var requested := false
var menu_resource: PackedScene
var status_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_boot_ui()
    call_deferred("_begin")

func _process(_delta: float) -> void:
    if not requested:
        return
    var progress: Array = []
    var state := ResourceLoader.load_threaded_get_status(MAIN_MENU_SCENE, progress)
    if state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        status_label.text = "Не удалось загрузить главное меню. Проверьте установку ImPuls."
        requested = false
        return
    if state == ResourceLoader.THREAD_LOAD_LOADED:
        var resource := ResourceLoader.load_threaded_get(MAIN_MENU_SCENE)
        if resource is PackedScene:
            menu_resource = resource
            requested = false
            _open_menu()
        else:
            status_label.text = "Главное меню имеет неверный формат."
            requested = false

func _begin() -> void:
    status_label.text = "Запуск ImPuls…"
    await get_tree().process_frame
    var err := ResourceLoader.load_threaded_request(MAIN_MENU_SCENE, "PackedScene", true)
    if err != OK:
        status_label.text = "Не удалось начать загрузку главного меню. Код: %s" % err
        return
    requested = true

func _open_menu() -> void:
    var menu := menu_resource.instantiate()
    if menu == null:
        status_label.text = "Не удалось создать главное меню."
        return
    get_tree().root.add_child(menu)
    get_tree().current_scene = menu
    queue_free()

func _build_boot_ui() -> void:
    var background := ColorRect.new()
    background.color = Color(0.012, 0.016, 0.022, 1.0)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var center := VBoxContainer.new()
    center.anchor_left = 0.5
    center.anchor_top = 0.5
    center.anchor_right = 0.5
    center.anchor_bottom = 0.5
    center.offset_left = -260
    center.offset_top = -70
    center.offset_right = 260
    center.offset_bottom = 70
    center.alignment = BoxContainer.ALIGNMENT_CENTER
    center.add_theme_constant_override("separation", 10)
    add_child(center)

    var title := Label.new()
    title.text = "ImPuls"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color(0.95, 0.84, 0.62))
    center.add_child(title)

    status_label = Label.new()
    status_label.text = "Запуск…"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.71))
    center.add_child(status_label)
