extends AudioStreamPlayer

const MENU_MUSIC_PATH := "res://assets/audio/music/production/impuls_menu_slow_down.mp3"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_audio_buses()
    bus = "Music"
    _load_menu_music_if_available()

func _load_menu_music_if_available() -> void:
    if not ResourceLoader.exists(MENU_MUSIC_PATH, "AudioStream"):
        push_warning("Menu music is unavailable or invalid: %s" % MENU_MUSIC_PATH)
        stream = null
        return

    var loaded_stream := load(MENU_MUSIC_PATH) as AudioStream
    if loaded_stream == null:
        push_warning("Failed to load menu music: %s" % MENU_MUSIC_PATH)
        stream = null
        return

    stream = loaded_stream
    stream.set("loop", true)
    if not playing:
        play()

func _ensure_audio_buses() -> void:
    _ensure_bus("Music")
    _ensure_bus("SFX")

func _ensure_bus(bus_name: String) -> void:
    var index := AudioServer.get_bus_index(bus_name)
    if index >= 0:
        return
    AudioServer.add_bus()
    AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func uses_music_bus() -> bool:
    return bus == "Music"

func loop_enabled() -> bool:
    return stream != null and bool(stream.get("loop"))
