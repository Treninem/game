extends Node

signal settings_changed
signal bindings_changed

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULTS := {
    "graphics": {
        "fullscreen": false,
        "vsync": true,
        "resolution_width": 1280,
        "resolution_height": 720,
        "render_scale": 1.0,
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
        "autosave_seconds": 60.0,
        "camera_fov": 75.0,
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
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate(true)

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
    for action in DEFAULT_BINDINGS:
        var saved = config.get_value("controls", action, DEFAULT_BINDINGS[action])
        if typeof(saved) == TYPE_DICTIONARY:
            bindings[action] = saved
    _remove_obsolete_actions()
    _apply_bindings()

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

func rebind_action(action: String, event: InputEvent) -> bool:
    if not DEFAULT_BINDINGS.has(action):
        return false
    var encoded := {}
    if event is InputEventKey:
        if not event.pressed:
            return false
        encoded = {"type": "key", "code": event.physical_keycode}
    elif event is InputEventMouseButton:
        if not event.pressed:
            return false
        encoded = {"type": "mouse", "code": event.button_index}
    else:
        return false
    bindings[action] = encoded
    _apply_binding(action, encoded)
    save_settings()
    bindings_changed.emit()
    return true

func binding_text(action: String) -> String:
    var binding = bindings.get(action, DEFAULT_BINDINGS.get(action, {}))
    if binding.get("type", "key") == "mouse":
        var code := int(binding.get("code", MOUSE_BUTTON_LEFT))
        match code:
            MOUSE_BUTTON_LEFT: return "ЛКМ"
            MOUSE_BUTTON_RIGHT: return "ПКМ"
            MOUSE_BUTTON_MIDDLE: return "СКМ"
            _: return "Mouse %d" % code
    return OS.get_keycode_string(int(binding.get("code", 0)))

func apply_all() -> void:
    var fullscreen := bool(get_value("graphics", "fullscreen"))
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
    if not fullscreen:
        DisplayServer.window_set_size(Vector2i(int(get_value("graphics", "resolution_width")), int(get_value("graphics", "resolution_height"))))
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_value("graphics", "vsync")) else DisplayServer.VSYNC_DISABLED)
    var viewport := get_viewport()
    if viewport != null:
        viewport.scaling_3d_scale = clampf(float(get_value("graphics", "render_scale")), 0.5, 1.5)
    if get_tree() != null and get_tree().root != null:
        get_tree().root.content_scale_factor = clampf(float(get_value("graphics", "ui_scale")), 0.75, 1.5)
    _apply_volume("Master", float(get_value("audio", "master_volume")), bool(get_value("audio", "muted")))
    _apply_volume("Music", float(get_value("audio", "music_volume")), false)
    _apply_volume("SFX", float(get_value("audio", "sfx_volume")), false)

func _write_defaults() -> void:
    for section in DEFAULTS:
        for key in DEFAULTS[section]:
            config.set_value(section, key, DEFAULTS[section][key])
    for action in DEFAULT_BINDINGS:
        config.set_value("controls", action, DEFAULT_BINDINGS[action])

func _remove_obsolete_actions() -> void:
    # Stage 10 is world-first. Old prototype shortcuts C/B must not invoke
    # temporary shelter/crafting logic while locations are being authored.
    for action in ["craft", "build"]:
        if InputMap.has_action(action):
            InputMap.erase_action(action)

func _apply_bindings() -> void:
    for action in bindings:
        _apply_binding(action, bindings[action])

func _apply_binding(action: String, binding: Dictionary) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    InputMap.action_erase_events(action)
    var event: InputEvent
    if binding.get("type", "key") == "mouse":
        var mouse := InputEventMouseButton.new()
        mouse.button_index = int(binding.get("code", MOUSE_BUTTON_LEFT))
        event = mouse
    else:
        var key := InputEventKey.new()
        key.physical_keycode = int(binding.get("code", 0))
        event = key
    InputMap.action_add_event(action, event)

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
