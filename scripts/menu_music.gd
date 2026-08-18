extends AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_audio_buses()
    bus = "Music"
    if stream != null:
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
