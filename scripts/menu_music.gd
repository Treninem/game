extends AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    bus = "Music"
    if stream != null:
        stream.set("loop", true)
    if not playing:
        play()

func uses_music_bus() -> bool:
    return bus == "Music"

func loop_enabled() -> bool:
    return stream != null and bool(stream.get("loop"))
