extends Node

signal settings_changed
signal bindings_changed

const SETTINGS_PATH := "user://settings.cfg"
const QUALITY_PRESETS := [
    {"name": "Низкий", "scale": 0.70, "msaa": 0, "shadows": false, "shadow_distance": 0.0, "nature": 0.70},
    {"name": "Средний", "scale": 0.85, "msaa": 0, "shadows": true, "shadow_distance": 40.0, "nature": 0.85},
    {"name": "Высокий", "scale": 1.0, "msaa": 1, "shadows": true, "shadow_distance": 65.0, "nature": 1.0},
    {"name": "Ультра", "scale": 1.0, "msaa": 2, "shadows": true, "shadow_distance": 100.0, "nature": 1.35}
]

const DEFAULTS := {
    "graphics": {
        "fullscreen": false,
        "vsync": true,
        "resolution_width": 1280,
        "resolution_height": 720,
        "render_scale": 1.0,
        "quality_preset": 2,
        "ui_scale": 1.0
    },
    "audio": {
        "master_volume": 0.8,
        "music_volume": 0.7,
        "sfx_volume": 0.8,
        "muted": false
    },
    "gameplay": {
        "mouse_sensitivity": 0.0025,
        "compatible_mouse": true,
        "autosave_seconds": 60.0,
        "day_length_minutes": 48.0,
        "camera_fov": 75.0,
        "camera_distance": 5.5,
        "subtitles": true
    }
}

const DEFAULT_BINDINGS := {
    "move_forward": {"type": "key", "code": KEY_W},
    "move_back": {"type": "key", "code": KEY_S},
    "move_left": {"type": "key", "code": KEY_A},
    "move_right": {"type": "key", "code": KEY_D},
    "sprint": {"type": "key", "code": KEY_SHIFT},
    "jump": {"type": "key", "code": KEY_SPACE},
    "interact": {"type": "key", "code": KEY_E},
    "attack": {"type": "mouse", "code": MOUSE_BUTTON_LEFT},
    "cast_magic": {"type": "mouse", "code": MOUSE_BUTTON_RIGHT},
    "next_spell": {"type": "key", "code": KEY_Q},
    "use_food": {"type": "key", "code": KEY_1},
    "use_water": {"type": "key", "code": KEY_2},
    "open_inventory": {"type": "key", "code": KEY_I},
    "open_map": {"type": "key", "code": KEY_M},
    "open_journal": {"type": "key", "code": KEY_J},
    "open_crafting": {"type": "key", "code": KEY_K},
    "quick_save": {"type": "key", "code": KEY_F5},
    "quick_load": {"type": "key", "code": KEY_F9},
    "pause_menu": {"type": "key", "code": KEY_ESCAPE}
}

var config := ConfigFile.new()
var mouse_capture_frame := -10
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate(true)
var last_binding_conflict := ""

func _ready() -> void:
    load_settings()
    _ensure_audio_buses()
    apply_all()

func load_settings() -> void:
    config = ConfigFile.new()
    var err := config.load(SETTINGS_PATH)
    if err != OK:
        _write_defaults()
        save_settings()
    bindings = DEFAULT_BINDINGS.duplicate(true)
    var repaired := false
    for action in DEFAULT_BINDINGS:
        var saved = config.get_value("controls", action, DEFAULT_BINDINGS[action])
        if typeof(saved) == TYPE_DICTIONARY and _binding_is_valid(saved as Dictionary):
            bindings[action] = saved
        else:
            bindings[action] = DEFAULT_BINDINGS[action].duplicate(true)
            config.set_value("controls", action, bindings[action])
            repaired = true
    _remove_obsolete_actions()
    _apply_bindings()
    if repaired:
        save_settings()

func save_settings() -> void:
    for action in bindings:
        config.set_value("controls", action, bindings[action])
    config.save(SETTINGS_PATH)

func reset_defaults() -> void:
    config = ConfigFile.new()
    _write_defaults()
    bindings = DEFAULT_BINDINGS.duplicate(true)
    save_settings()
    _remove_obsolete_actions()
    _apply_bindings()
    apply_all()
    settings_changed.emit()
    bindings_changed.emit()

func get_value(section: String, key: String):
    var fallback = DEFAULTS.get(section, {}).get(key, null)
    return config.get_value(section, key, fallback)

func set_value(section: String, key: String, value) -> void:
    config.set_value(section, key, value)
    save_settings()
    apply_all()
    settings_changed.emit()

func set_camera_distance(value: float) -> void:
    # Zoom changes must not reapply window size, render quality or mouse mode.
    config.set_value("gameplay", "camera_distance", clampf(value, 2.0, 9.0))
    save_settings()
    settings_changed.emit()

func rebind_action(action: String, event: InputEvent) -> bool:
    last_binding_conflict = ""
    if not DEFAULT_BINDINGS.has(action):
        return false
    var encoded := {}
    if event is InputEventKey:
        if not event.pressed or event.echo:
            return false
        var key_event := event as InputEventKey
        var code := int(key_event.physical_keycode)
        if code <= 0:
            code = int(key_event.keycode)
        if code <= 0:
            return false
        encoded = {"type": "key", "code": code}
    elif event is InputEventMouseButton:
        if not event.pressed:
            return false
        var mouse_event := event as InputEventMouseButton
        if int(mouse_event.button_index) <= 0:
            return false
        encoded = {"type": "mouse", "code": mouse_event.button_index}
    else:
        return false
    for other: String in DEFAULT_BINDINGS:
        if other == action:
            continue
        var assigned: Dictionary = bindings.get(other, DEFAULT_BINDINGS[other])
        if assigned.get("type") == encoded.get("type") and int(assigned.get("code", 0)) == int(encoded.code):
            last_binding_conflict = other
            return false
    bindings[action] = encoded
    _apply_bindings()
    save_settings()
    bindings_changed.emit()
    return true

func binding_conflicts() -> Array:
    var groups := {}
    for action: String in DEFAULT_BINDINGS:
        var assigned: Dictionary = bindings.get(action, DEFAULT_BINDINGS[action])
        var key := "%s:%d" % [String(assigned.get("type", "key")), int(assigned.get("code", 0))]
        if not groups.has(key):
            groups[key] = []
        groups[key].append(action)
    var result: Array = []
    for actions: Array in groups.values():
        if actions.size() > 1:
            result.append(actions.duplicate())
    return result

func binding_text(action: String) -> String:
    var binding = bindings.get(action, DEFAULT_BINDINGS.get(action, {}))
    if binding.get("type", "key") == "mouse":
        var code := int(binding.get("code", MOUSE_BUTTON_LEFT))
        match code:
            MOUSE_BUTTON_LEFT: return "ЛКМ"
            MOUSE_BUTTON_RIGHT: return "ПКМ"
            MOUSE_BUTTON_MIDDLE: return "СКМ"
            _: return "Mouse %d" % code
    var label := OS.get_keycode_string(int(binding.get("code", 0)))
    return "%s / Tab" % label if action == "open_inventory" and has_default_inventory_alias() else label

func apply_all() -> void:
    var fullscreen := bool(get_value("graphics", "fullscreen"))
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
    if not fullscreen:
        DisplayServer.window_set_size(Vector2i(int(get_value("graphics", "resolution_width")), int(get_value("graphics", "resolution_height"))))
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_value("graphics", "vsync")) else DisplayServer.VSYNC_DISABLED)
    var viewport := get_viewport()
    if viewport != null:
        viewport.scaling_3d_scale = clampf(float(get_value("graphics", "render_scale")), 0.5, 1.5)
        viewport.msaa_3d = quality_profile()["msaa"]
    call_deferred("apply_world_quality")
    if get_tree() != null and get_tree().root != null:
        get_tree().root.content_scale_factor = clampf(float(get_value("graphics", "ui_scale")), 0.75, 1.5)
    _apply_volume("Master", float(get_value("audio", "master_volume")), bool(get_value("audio", "muted")))
    _apply_volume("Music", float(get_value("audio", "music_volume")), false)
    _apply_volume("SFX", float(get_value("audio", "sfx_volume")), false)

func day_length_minutes() -> float:
    var value:Variant=get_value("gameplay","day_length_minutes")
    var duration:=float(value) if (value is int or value is float) and is_finite(float(value)) else 48.0
    return clampf(duration,6.,120.)

func world_minutes_per_second() -> float:
    return 24.0/day_length_minutes()

func quality_profile() -> Dictionary:
    return QUALITY_PRESETS[clampi(int(get_value("graphics", "quality_preset")), 0, QUALITY_PRESETS.size() - 1)]

func uses_compatible_mouse() -> bool:
    return OS.get_name() == "Windows" and bool(get_value("gameplay", "compatible_mouse"))

func gameplay_mouse_mode() -> int:
    # Windows remote/absolute pointing devices can stop emitting WM_INPUT
    # entirely in CAPTURED mode (Godot #95501). Hidden confinement uses normal
    # mouse events; recentering below keeps unlimited camera rotation.
    return Input.MOUSE_MODE_CONFINED_HIDDEN if uses_compatible_mouse() else Input.MOUSE_MODE_CAPTURED

func capture_gameplay_mouse() -> void:
    mouse_capture_frame = Engine.get_process_frames()
    Input.mouse_mode = gameplay_mouse_mode()
    recenter_gameplay_mouse()

func ignore_recapture_motion() -> bool:
    # A menu click can leave cursor events buffered until after gameplay resumes.
    return Engine.get_process_frames() <= mouse_capture_frame + 1

func is_gameplay_mouse_captured() -> bool:
    return Input.mouse_mode == gameplay_mouse_mode()

func recenter_gameplay_mouse() -> void:
    if uses_compatible_mouse() and get_viewport() != null:
        get_viewport().warp_mouse(get_viewport().get_visible_rect().get_center())

func set_quality_preset(index: int) -> void:
    index = clampi(index, 0, QUALITY_PRESETS.size() - 1)
    config.set_value("graphics", "quality_preset", index)
    config.set_value("graphics", "render_scale", QUALITY_PRESETS[index]["scale"])
    save_settings()
    apply_all()
    settings_changed.emit()

func apply_world_quality() -> void:
    if get_tree() == null:
        return
    var profile := quality_profile()
    for light in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
        light.shadow_enabled = profile["shadows"]
        light.directional_shadow_max_distance = profile["shadow_distance"]
    for instance in get_tree().get_nodes_in_group("quality_nature"):
        apply_geometry_quality(instance)

func apply_geometry_quality(instance: GeometryInstance3D) -> void:
    var profile := quality_profile()
    # Scale both ends together so the transition between near and far LODs
    # remains continuous. Collision and gameplay streaming never change.
    instance.visibility_range_begin = float(instance.get_meta("quality_begin", 0.0)) * float(profile["nature"])
    instance.visibility_range_end = float(instance.get_meta("quality_end", 150.0)) * float(profile["nature"])
    instance.cast_shadow = int(instance.get_meta("quality_shadows", 0)) if bool(profile["shadows"]) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _write_defaults() -> void:
    for section in DEFAULTS:
        for key in DEFAULTS[section]:
            config.set_value(section, key, DEFAULTS[section][key])
    for action in DEFAULT_BINDINGS:
        config.set_value("controls", action, DEFAULT_BINDINGS[action])

func _remove_obsolete_actions() -> void:
    for action in ["craft", "build"]:
        if InputMap.has_action(action):
            InputMap.erase_action(action)

func _binding_is_valid(binding: Dictionary) -> bool:
    var kind := String(binding.get("type", ""))
    var code := int(binding.get("code", 0))
    if kind == "key":
        return code > 0
    if kind == "mouse":
        return code > 0
    return false

func has_default_inventory_alias() -> bool:
    var inventory: Dictionary = bindings.get("open_inventory", DEFAULT_BINDINGS.open_inventory)
    if inventory.get("type", "key") != "key" or int(inventory.get("code", 0)) != KEY_I:
        return false
    for action: String in bindings:
        if action == "open_inventory":
            continue
        var assigned: Dictionary = bindings[action]
        if assigned.get("type", "key") == "key" and int(assigned.get("code", 0)) == KEY_TAB:
            return false
    return true

func _apply_bindings() -> void:
    for action in bindings:
        _apply_binding(action, bindings[action])
    # Preserve the saved primary binding. Tab is only a default shortcut and
    # yields immediately to an explicit user assignment on another action.
    if has_default_inventory_alias():
        var alias := InputEventKey.new()
        alias.physical_keycode = KEY_TAB
        InputMap.action_add_event("open_inventory", alias)
        alias = InputEventKey.new()
        alias.keycode = KEY_TAB
        InputMap.action_add_event("open_inventory", alias)

func _apply_binding(action: String, binding: Dictionary) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    InputMap.action_erase_events(action)

    var effective := binding
    if not _binding_is_valid(effective):
        effective = DEFAULT_BINDINGS.get(action, {"type": "key", "code": KEY_UNKNOWN})

    if effective.get("type", "key") == "mouse":
        var mouse := InputEventMouseButton.new()
        mouse.button_index = int(effective.get("code", MOUSE_BUTTON_LEFT))
        InputMap.action_add_event(action, mouse)
        return

    var code := int(effective.get("code", 0))
    if code <= 0:
        code = int(DEFAULT_BINDINGS.get(action, {}).get("code", KEY_UNKNOWN))
    if code <= 0:
        return

    # Register both the physical scan-position and the logical keycode. Real
    # Windows key events contain both, but either field may be absent in remote,
    # accessibility or synthetic input paths. Keeping both prevents a valid key
    # from becoming inert after an upgrade or keyboard-layout change.
    var physical := InputEventKey.new()
    physical.physical_keycode = code
    InputMap.action_add_event(action, physical)

    var logical := InputEventKey.new()
    logical.keycode = code
    InputMap.action_add_event(action, logical)

func _ensure_audio_buses() -> void:
    for bus_name in ["Music", "SFX"]:
        if AudioServer.get_bus_index(bus_name) < 0:
            AudioServer.add_bus()
            AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func _apply_volume(bus_name: String, linear: float, muted: bool) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx < 0:
        return
    AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))
    AudioServer.set_bus_mute(idx, muted)
