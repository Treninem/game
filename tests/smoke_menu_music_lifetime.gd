extends SceneTree

const AUDIO_RETIREMENT = preload("res://tests/audio_retirement_probe.gd")

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(15).timeout.connect(func():push_error("Menu music lifetime timed out");quit(1))
    var script := load("res://scripts/menu_music.gd")
    for cycle in range(3):
        var music := script.new() as AudioStreamPlayer
        root.add_child(music)
        await create_timer(0.05).timeout
        assert(music.playing and music.call("uses_music_bus") and music.call("loop_enabled"))
        var retired: Array[WeakRef] = [AUDIO_RETIREMENT.stream_reference(music), AUDIO_RETIREMENT.playback_reference(music)]
        if cycle != 1:
            music.call("shutdown")
            assert(not music.playing and music.stream == null)
        # The middle cycle also verifies normal scene-node retirement.
        music.queue_free()
        var start := Time.get_ticks_msec()
        var released: bool = await AUDIO_RETIREMENT.wait_retired(self, retired)
        assert(released, "Retired menu retained its MP3 stream/playback")
        print("MENU_MUSIC_RETIRED cycle=", cycle, " elapsed_msec=", Time.get_ticks_msec() - start)
    print("MENU_MUSIC_LIFETIME_OK cycles=3 explicit_stop=true natural_exit=true streams_released=true")
    quit()
