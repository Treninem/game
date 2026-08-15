extends Node

const WORLD_AUDIO := preload("res://scripts/world_audio.gd")
const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const HYDROLOGY := preload("res://scripts/world_hydrology.gd")
const RIVER_AUDIO_PATH := "res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_loop_water_01.ogg"
const SOURCE_PATH := "res://assets/audio/world/oga_100_cc0_sfx_2/SOURCE.md"

func _ready() -> void:
    await get_tree().process_frame
    var failures: Array[String] = []

    if not ResourceLoader.exists(RIVER_AUDIO_PATH):
        failures.append("Promoted physical river audio asset is missing from production audio")
    else:
        var river_stream := load(RIVER_AUDIO_PATH)
        if not river_stream is AudioStream:
            failures.append("Promoted river asset does not import as an AudioStream")
        elif river_stream.resource_path.begins_with("res://assets/staging/"):
            failures.append("Runtime river audio still points at staging instead of production")

    if not FileAccess.file_exists(SOURCE_PATH):
        failures.append("Production world audio is missing source/license provenance")

    var stage_text := FileAccess.get_file_as_string("res://scenes/stage1.tscn")
    if not stage_text.contains("res://scripts/world_audio.gd") or not stage_text.contains("name=\"WorldAudio\""):
        failures.append("Main gameplay stage does not mount the world audio system")

    var world := Node3D.new()
    world.name = "AudioSmokeWorld"
    add_child(world)

    var player := Node3D.new()
    player.name = "Player"
    var spawn := GEOGRAPHY.START_SPAWN
    player.position = Vector3(spawn.x, WorldData.elevation_at(spawn) + 1.0, spawn.y)
    world.add_child(player)

    var audio := WORLD_AUDIO.new() as Node3D
    audio.name = "WorldAudio"
    world.add_child(audio)
    await get_tree().process_frame

    var emitter := audio.call("river_emitter") as AudioStreamPlayer3D
    if emitter == null:
        failures.append("World audio did not create a spatial river emitter")
    else:
        if emitter.stream == null:
            failures.append("Spatial river emitter has no real audio stream")
        if String(emitter.bus) != "SFX":
            failures.append("Spatial river emitter bypasses the existing SFX settings bus")
        if emitter.max_distance < float(audio.get("river_audible_radius")):
            failures.append("River emitter attenuation ends before the gameplay audible radius")

    if not bool(audio.call("river_audio_should_play_for", spawn)):
        failures.append("River ambience is not audible from the canonical forest-river spawn")
    var anchor := audio.call("river_audio_anchor_for", spawn) as Vector3
    var expected_x := GEOGRAPHY.start_river_x(spawn.y)
    if absf(anchor.x - expected_x) > 0.01 or absf(anchor.y - GEOGRAPHY.START_RIVER_WATER_LEVEL - 0.18) > 0.01:
        failures.append("River audio anchor is detached from physical river geometry")
    if bool(audio.call("river_audio_should_play_for", Vector2(5000.0, 5000.0))):
        failures.append("Start-river ambience leaks thousands of metres outside its physical region")

    if int(audio.call("footstep_pool_size")) < 3:
        failures.append("World audio does not pool enough 3D footstep emitters for overlapping steps")
    if String(audio.call("footstep_surface_at", HYDROLOGY.ROAD_BRIDGE_CENTER)) != "wood":
        failures.append("Physical bridge no longer resolves to wood footstep audio")
    var ford_probe := Vector2(GEOGRAPHY.start_river_x(HYDROLOGY.START_FORD_CENTER.y), HYDROLOGY.START_FORD_CENTER.y)
    if String(audio.call("footstep_surface_at", ford_probe)) != "wet":
        failures.append("Old Ford no longer resolves to wet footstep audio")
    if String(audio.call("footstep_surface_at", spawn)) != "ground":
        failures.append("Forest-bank spawn no longer resolves to ground footstep audio")

    audio.call("play_footstep", Vector3(HYDROLOGY.ROAD_BRIDGE_CENTER.x, 2.0, HYDROLOGY.ROAD_BRIDGE_CENTER.y), "", 0.9)
    if String(audio.get("last_footstep_surface")) != "wood" or not String(audio.get("last_footstep_stream_path")).contains("footstep_wood"):
        failures.append("Bridge footstep did not use a promoted wood sound")
    audio.call("play_footstep", Vector3(ford_probe.x, GEOGRAPHY.START_RIVER_WATER_LEVEL, ford_probe.y), "", 0.9)
    if String(audio.get("last_footstep_surface")) != "wet" or not String(audio.get("last_footstep_stream_path")).contains("footstep_wet"):
        failures.append("Ford footstep did not use a promoted wet sound")

    if failures.is_empty():
        print("WORLD_AUDIO_SMOKE_OK river=spatial footsteps=surface_aware production_audio=promoted")
        get_tree().quit(0)
        return

    for failure in failures:
        push_error(failure)
    get_tree().quit(1)
