extends Node3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const HYDROLOGY := preload("res://scripts/world_hydrology.gd")

const AUDIO_ROOT := "res://assets/audio/world/oga_100_cc0_sfx_2/"
const RIVER_LOOP := preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_loop_water_01.ogg")
const GROUND_STEPS := [
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_01.ogg"),
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_02.ogg"),
]
const WET_STEPS := [
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wet_01.ogg"),
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wet_02.ogg"),
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wet_03.ogg"),
]
const WOOD_STEPS := [
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wood_01.ogg"),
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wood_02.ogg"),
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wood_03.ogg"),
    preload("res://assets/audio/world/oga_100_cc0_sfx_2/sfx100v2_footstep_wood_04.ogg"),
]

const FOOTSTEP_POOL_SIZE := 4
const FOOTSTEP_MAX_DISTANCE := 42.0

@export var player_path := NodePath("../Player")
@export var river_audible_radius := 118.0
@export var river_update_interval := 0.18

var _player: Node3D
var _river_player: AudioStreamPlayer3D
var _footstep_players: Array[AudioStreamPlayer3D] = []
var _footstep_pool_cursor := 0
var _footstep_serial := 0
var _step_indices := {"ground": 0, "wet": 0, "wood": 0}
var _river_elapsed := 0.0
var _river_should_play := false

var last_footstep_surface := ""
var last_footstep_stream_path := ""

func _ready() -> void:
    add_to_group("world_audio")
    _create_river_player()
    _create_footstep_pool()
    _resolve_player()
    _update_river_ambience()

func _process(delta: float) -> void:
    if not is_instance_valid(_player):
        _resolve_player()
    _river_elapsed += delta
    if _river_elapsed < river_update_interval:
        return
    _river_elapsed = 0.0
    _update_river_ambience()

func _resolve_player() -> void:
    _player = get_node_or_null(player_path) as Node3D
    if _player == null:
        _player = get_tree().get_first_node_in_group("player") as Node3D

func _create_river_player() -> void:
    _river_player = AudioStreamPlayer3D.new()
    _river_player.name = "RiverAmbience"
    _river_player.stream = RIVER_LOOP
    _river_player.bus = &"SFX"
    _river_player.volume_db = -10.5
    _river_player.unit_size = 18.0
    _river_player.max_distance = river_audible_radius + 28.0
    add_child(_river_player)
    _river_player.finished.connect(_on_river_finished)

func _create_footstep_pool() -> void:
    for index in range(FOOTSTEP_POOL_SIZE):
        var step_player := AudioStreamPlayer3D.new()
        step_player.name = "Footstep_%02d" % index
        step_player.bus = &"SFX"
        step_player.unit_size = 5.5
        step_player.max_distance = FOOTSTEP_MAX_DISTANCE
        add_child(step_player)
        _footstep_players.append(step_player)

func river_audio_anchor_for(world_position: Vector2) -> Vector3:
    var river_x := GEOGRAPHY.start_river_x(world_position.y)
    return Vector3(river_x, GEOGRAPHY.START_RIVER_WATER_LEVEL + 0.18, world_position.y)

func river_audio_distance_for(world_position: Vector2) -> float:
    var anchor := river_audio_anchor_for(world_position)
    return world_position.distance_to(Vector2(anchor.x, anchor.z))

func river_audio_should_play_for(world_position: Vector2) -> bool:
    var anchor := river_audio_anchor_for(world_position)
    var anchor_xz := Vector2(anchor.x, anchor.z)
    if not GEOGRAPHY.in_start_region(anchor_xz):
        return false
    return world_position.distance_to(anchor_xz) <= river_audible_radius

func _update_river_ambience() -> void:
    if not is_instance_valid(_river_player):
        return
    if not is_instance_valid(_player):
        _river_should_play = false
        if _river_player.playing:
            _river_player.stop()
        return

    var player_xz := Vector2(_player.global_position.x, _player.global_position.z)
    var anchor := river_audio_anchor_for(player_xz)
    _river_player.global_position = anchor
    _river_should_play = river_audio_should_play_for(player_xz)
    if _river_should_play:
        if not _river_player.playing:
            _river_player.play()
    elif _river_player.playing:
        _river_player.stop()

func _on_river_finished() -> void:
    if _river_should_play and is_instance_valid(_river_player):
        _river_player.play()

func footstep_surface_at(world_position: Vector2) -> String:
    var crossing := HYDROLOGY.crossing_kind_at(world_position)
    if crossing == "bridge":
        return "wood"
    if crossing == "ford":
        return "wet"
    var water_kind := WorldData.water_kind_at(world_position)
    if water_kind in ["river", "lake", "sea"]:
        return "wet"
    return "ground"

func play_footstep(world_position: Vector3, surface_hint: String = "", intensity: float = 0.72) -> void:
    if _footstep_players.is_empty():
        return
    var surface := surface_hint if surface_hint in ["ground", "wet", "wood"] else footstep_surface_at(Vector2(world_position.x, world_position.z))
    var stream := _next_footstep_stream(surface)
    if stream == null:
        return

    var step_player := _footstep_players[_footstep_pool_cursor]
    _footstep_pool_cursor = (_footstep_pool_cursor + 1) % _footstep_players.size()
    _footstep_serial += 1
    step_player.stream = stream
    step_player.global_position = world_position + Vector3.UP * 0.10
    var strength := clampf(intensity, 0.0, 1.35) / 1.35
    step_player.volume_db = lerpf(-12.5, -5.0, strength)
    step_player.pitch_scale = 0.96 + float(_footstep_serial % 5) * 0.02
    step_player.play()

    last_footstep_surface = surface
    last_footstep_stream_path = stream.resource_path

func _next_footstep_stream(surface: String) -> AudioStream:
    var streams: Array
    match surface:
        "wet": streams = WET_STEPS
        "wood": streams = WOOD_STEPS
        _: streams = GROUND_STEPS
    if streams.is_empty():
        return null
    var index := int(_step_indices.get(surface, 0)) % streams.size()
    _step_indices[surface] = index + 1
    return streams[index] as AudioStream

func river_emitter() -> AudioStreamPlayer3D:
    return _river_player

func footstep_pool_size() -> int:
    return _footstep_players.size()
