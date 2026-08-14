extends Node

# Single geometry authority for full-screen menus. Dynamic menu scripts can
# rebuild their controls at runtime, so this guard always performs the final
# compaction + centering after resolution/fullscreen/UI-scale changes.
#
# Important: geometry is enforced from the frame loop, not from item_rect_changed.
# Reacting to item_rect_changed by changing the same rect can recursively re-enter
# Control layout on some Windows/Godot configurations. One-frame correction is
# visually instantaneous and cannot recurse.

const WATCH_GROUPS := ["game_menu", "gameplay_panels"]
const MIN_SAFE_MARGIN := 8.0
const MAX_SAFE_MARGIN := 24.0
const GEOMETRY_EPSILON := 0.5

var watched: Dictionary = {}
var _reflow_queued := false
var _last_viewport_size := Vector2.ZERO
var _last_ui_scale := -1.0
var _geometry_lock: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    var viewport := get_viewport()
    if viewport != null:
        viewport.size_changed.connect(_queue_reflow)
    SettingsManager.settings_changed.connect(_queue_reflow)
    call_deferred("_discover")

func _process(_delta: float) -> void:
    var viewport := get_viewport()
    if viewport == null:
        return
    var viewport_size: Vector2 = viewport.get_visible_rect().size
    var ui_scale: float = _ui_scale()
    if viewport_size != _last_viewport_size or not is_equal_approx(ui_scale, _last_ui_scale):
        _queue_reflow()

    var stale: Array[int] = []
    for instance_id in watched:
        var ref: WeakRef = watched[instance_id]
        var control := ref.get_ref() as Control
        if control == null or not is_instance_valid(control):
            stale.append(int(instance_id))
            continue
        if control.visible:
            _enforce_frame_geometry(control)
    for instance_id in stale:
        watched.erase(instance_id)

func _on_node_added(_node: Node) -> void:
    call_deferred("_discover")

func _discover() -> void:
    for group_name in WATCH_GROUPS:
        for candidate in get_tree().get_nodes_in_group(group_name):
            var control := candidate as Control
            if control == null or watched.has(control.get_instance_id()):
                continue
            watched[control.get_instance_id()] = weakref(control)
            control.resized.connect(Callable(self, "_on_control_changed").bind(control))
            control.visibility_changed.connect(Callable(self, "_on_control_changed").bind(control))
            call_deferred("_fit_control", control)
    _queue_reflow()

func _on_control_changed(control: Control) -> void:
    call_deferred("_fit_control", control)

func _queue_reflow() -> void:
    if _reflow_queued:
        return
    _reflow_queued = true
    call_deferred("_reflow_all")

func _reflow_all() -> void:
    _reflow_queued = false
    var viewport := get_viewport()
    if viewport != null:
        _last_viewport_size = viewport.get_visible_rect().size
    _last_ui_scale = _ui_scale()

    var stale: Array[int] = []
    for instance_id in watched:
        var ref: WeakRef = watched[instance_id]
        var control := ref.get_ref() as Control
        if control == null or not is_instance_valid(control):
            stale.append(int(instance_id))
            continue
        _fit_control(control)
    for instance_id in stale:
        watched.erase(instance_id)

func _fit_control(control: Control) -> void:
    if control == null or not is_instance_valid(control):
        return
    var frame_variant = control.get("frame")
    if not (frame_variant is Control):
        return
    var frame := frame_variant as Control
    if not is_instance_valid(frame):
        return

    control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var available: Vector2 = _available_size(control)
    if available.x <= 1.0 or available.y <= 1.0:
        return

    # Existing menu scripts remain responsible for internal font/button sizing.
    # The outer frame geometry is overwritten here afterwards and on every visible
    # frame, so legacy centering math can never accumulate drift.
    if control.has_method("_apply_responsive_layout"):
        control.call("_apply_responsive_layout")

    if control.is_in_group("game_menu"):
        _fit_game_menu(control, available)
    else:
        _fit_gameplay_panels(control, available)

    _enforce_frame_geometry(control, true)

func _available_size(control: Control) -> Vector2:
    var available: Vector2 = control.size
    if available.x <= 1.0 or available.y <= 1.0:
        var viewport := get_viewport()
        if viewport != null:
            available = viewport.get_visible_rect().size
    return available

func _desired_frame_geometry(control: Control, available: Vector2) -> Dictionary:
    var is_game_menu: bool = control.is_in_group("game_menu")
    var preferred: Vector2 = Vector2(1120.0, 760.0) if is_game_menu else Vector2(1220.0, 820.0)
    var margin: float = clampf(minf(available.x, available.y) * 0.025, MIN_SAFE_MARGIN, MAX_SAFE_MARGIN)
    var usable := Vector2(maxf(1.0, available.x - margin * 2.0), maxf(1.0, available.y - margin * 2.0))
    var target: Vector2 = Vector2(minf(preferred.x, usable.x), minf(preferred.y, usable.y)).floor()
    var position: Vector2 = ((available - target) * 0.5).floor()
    return {"size": target, "position": position}

func _enforce_frame_geometry(control: Control, force: bool = false) -> void:
    if control == null or not is_instance_valid(control):
        return
    var control_id: int = control.get_instance_id()
    if _geometry_lock.has(control_id):
        return
    var frame_variant = control.get("frame")
    if not (frame_variant is Control):
        return
    var frame := frame_variant as Control
    if not is_instance_valid(frame):
        return

    var available: Vector2 = _available_size(control)
    if available.x <= 1.0 or available.y <= 1.0:
        return
    var desired: Dictionary = _desired_frame_geometry(control, available)
    var target: Vector2 = desired["size"]
    var target_position: Vector2 = desired["position"]
    var anchors_wrong: bool = (
        not is_zero_approx(frame.anchor_left)
        or not is_zero_approx(frame.anchor_top)
        or not is_zero_approx(frame.anchor_right)
        or not is_zero_approx(frame.anchor_bottom)
    )
    var size_wrong: bool = frame.size.distance_to(target) > GEOMETRY_EPSILON
    var position_wrong: bool = frame.position.distance_to(target_position) > GEOMETRY_EPSILON
    if not force and not anchors_wrong and not size_wrong and not position_wrong:
        return

    _geometry_lock[control_id] = true
    frame.custom_minimum_size = Vector2.ZERO
    frame.clip_contents = true
    frame.anchor_left = 0.0
    frame.anchor_top = 0.0
    frame.anchor_right = 0.0
    frame.anchor_bottom = 0.0
    frame.size = target
    frame.position = target_position
    _geometry_lock.erase(control_id)

func _fit_game_menu(control: Control, available: Vector2) -> void:
    var scale: float = _ui_scale()
    var compact: bool = available.x < 900.0 or available.y < 650.0 or scale > 1.10
    var tight: bool = available.x < 760.0 or available.y < 540.0 or scale >= 1.35

    var sidebar_variant = control.get("sidebar")
    if sidebar_variant is VBoxContainer:
        var sidebar := sidebar_variant as VBoxContainer
        sidebar.add_theme_constant_override("separation", 3 if tight else (5 if compact else 7))
        var side_margin := sidebar.get_parent() as MarginContainer
        if side_margin != null:
            var h_margin: int = 7 if tight else (9 if compact else 12)
            var v_margin: int = 7 if tight else (9 if compact else 14)
            side_margin.add_theme_constant_override("margin_left", h_margin)
            side_margin.add_theme_constant_override("margin_right", h_margin)
            side_margin.add_theme_constant_override("margin_top", v_margin)
            side_margin.add_theme_constant_override("margin_bottom", v_margin)
            var side_panel := side_margin.get_parent() as PanelContainer
            if side_panel != null:
                side_panel.custom_minimum_size.x = 142.0 if tight else (168.0 if compact else 210.0)

        for child in sidebar.get_children():
            if child is Button:
                var button := child as Button
                var is_close: bool = button.text == "Вернуться в игру"
                button.custom_minimum_size.y = 32.0 if tight else (36.0 if compact else (44.0 if is_close else 40.0))
                button.add_theme_font_size_override("font_size", 10 if tight else (11 if compact else (14 if is_close else 13)))
            elif child is Label:
                var label := child as Label
                if label.text == "ImPuls":
                    label.add_theme_font_size_override("font_size", 22 if tight else (25 if compact else 30))
                elif label.text == "OFFLINE WORLD":
                    label.add_theme_font_size_override("font_size", 8 if tight else (9 if compact else 10))

    var nav_variant = control.get("nav_buttons")
    if nav_variant is Dictionary:
        var buttons: Dictionary = nav_variant
        for key in buttons:
            var button := buttons[key] as Button
            if button != null:
                button.custom_minimum_size.y = 32.0 if tight else (36.0 if compact else 40.0)
                button.add_theme_font_size_override("font_size", 10 if tight else (11 if compact else 13))

    var title_variant = control.get("title_label")
    if title_variant is Label:
        var title := title_variant as Label
        title.add_theme_font_size_override("font_size", 21 if tight else (24 if compact else 27))
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var content_variant = control.get("content")
    if content_variant is VBoxContainer:
        var content := content_variant as VBoxContainer
        content.add_theme_constant_override("separation", 7 if tight else (8 if compact else 10))

func _fit_gameplay_panels(control: Control, available: Vector2) -> void:
    var scale: float = _ui_scale()
    var compact: bool = available.x < 900.0 or available.y < 620.0 or scale > 1.10
    var tight: bool = available.x < 720.0 or available.y < 500.0 or scale >= 1.35

    var tabs_variant = control.get("tab_buttons")
    if tabs_variant is Dictionary:
        var buttons: Dictionary = tabs_variant
        for key in buttons:
            var button := buttons[key] as Button
            if button != null:
                button.custom_minimum_size.y = 32.0 if tight else (36.0 if compact else 42.0)
                button.add_theme_font_size_override("font_size", 10 if tight else (11 if compact else 13))

    var title_variant = control.get("title_label")
    if title_variant is Label:
        var title := title_variant as Label
        title.add_theme_font_size_override("font_size", 21 if tight else (24 if compact else 28))
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var context_variant = control.get("context_label")
    if context_variant is Label:
        var context := context_variant as Label
        context.add_theme_font_size_override("font_size", 9 if tight else (10 if compact else 11))
        context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var content_variant = control.get("content")
    if content_variant is VBoxContainer:
        var content := content_variant as VBoxContainer
        content.add_theme_constant_override("separation", 7 if tight else (9 if compact else 11))

func _ui_scale() -> float:
    return clampf(float(SettingsManager.get_value("graphics", "ui_scale")), 0.75, 1.5)
