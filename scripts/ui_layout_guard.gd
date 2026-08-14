extends Node

# Final geometry authority for full-screen menus. Both legacy menu scripts build
# their controls dynamically and may recalculate offsets after resolution/UI-scale
# changes. This guard runs after those calculations and always centers the visible
# frame inside the *actual* viewport using top-left anchors, so no negative anchor
# math can accumulate drift.

const WATCH_GROUPS := ["game_menu", "gameplay_panels"]
const DEFAULT_MARGIN := 18.0
const COMPACT_MARGIN := 8.0

var watched: Dictionary = {}
var _reflow_queued := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    if get_tree().root != null:
        get_tree().root.size_changed.connect(_queue_reflow)
    SettingsManager.settings_changed.connect(_queue_reflow)
    call_deferred("_discover")

func _on_node_added(_node: Node) -> void:
    call_deferred("_discover")

func _discover() -> void:
    for group_name in WATCH_GROUPS:
        var control := get_tree().get_first_node_in_group(group_name) as Control
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

    var available := control.size
    if available.x <= 1.0 or available.y <= 1.0:
        available = get_tree().root.get_visible_rect().size
    if available.x <= 1.0 or available.y <= 1.0:
        return

    var is_game_menu := control.is_in_group("game_menu")
    var preferred := Vector2(1120.0, 760.0) if is_game_menu else Vector2(1220.0, 820.0)
    var minimum := Vector2(300.0, 280.0)
    var margin := COMPACT_MARGIN if available.x < 760.0 or available.y < 520.0 else DEFAULT_MARGIN
    var usable := Vector2(maxf(minimum.x, available.x - margin * 2.0), maxf(minimum.y, available.y - margin * 2.0))
    var target := Vector2(minf(preferred.x, usable.x), minf(preferred.y, usable.y))
    target.x = minf(target.x, available.x)
    target.y = minf(target.y, available.y)

    # Use an unambiguous coordinate system: top-left anchors + explicit centered
    # position. This remains correct after window resize, fullscreen changes and
    # root content_scale_factor changes.
    frame.anchor_left = 0.0
    frame.anchor_top = 0.0
    frame.anchor_right = 0.0
    frame.anchor_bottom = 0.0
    frame.size = target.floor()
    frame.position = ((available - frame.size) * 0.5).floor()

    if is_game_menu:
        _fit_game_menu(control, target)
    else:
        _fit_gameplay_panels(control, target)

func _fit_game_menu(control: Control, target: Vector2) -> void:
    var sidebar_variant = control.get("sidebar")
    if sidebar_variant is VBoxContainer:
        var sidebar := sidebar_variant as VBoxContainer
        var side_margin := sidebar.get_parent()
        if side_margin != null:
            var side_panel := side_margin.get_parent() as PanelContainer
            if side_panel != null:
                if target.x < 620.0:
                    side_panel.custom_minimum_size.x = 128.0
                elif target.x < 820.0:
                    side_panel.custom_minimum_size.x = 160.0
                else:
                    side_panel.custom_minimum_size.x = 210.0
    var nav_variant = control.get("nav_buttons")
    if nav_variant is Dictionary:
        var buttons: Dictionary = nav_variant
        for key in buttons:
            var button := buttons[key] as Button
            if button != null:
                button.add_theme_font_size_override("font_size", 10 if target.x < 620.0 else (11 if target.x < 820.0 else 13))
                button.custom_minimum_size.y = 34.0 if target.y < 520.0 else 40.0

func _fit_gameplay_panels(control: Control, target: Vector2) -> void:
    var tabs_variant = control.get("tab_buttons")
    if not (tabs_variant is Dictionary):
        return
    var buttons: Dictionary = tabs_variant
    for key in buttons:
        var button := buttons[key] as Button
        if button != null:
            button.add_theme_font_size_override("font_size", 10 if target.x < 620.0 else (11 if target.x < 820.0 else 13))
            button.custom_minimum_size.y = 36.0 if target.y < 520.0 else 42.0
