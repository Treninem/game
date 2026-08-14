extends Node

var world_environment: WorldEnvironment
var environment: Environment
var sky: Sky
var sky_material: ProceduralSkyMaterial

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color(0.12, 0.22, 0.34, 1.0))
    _build_environment()

func _build_environment() -> void:
    world_environment = WorldEnvironment.new()
    world_environment.name = "StableWorldEnvironment"

    environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_sky_contribution = 0.78
    environment.ambient_light_energy = 1.12
    environment.background_energy_multiplier = 1.0

    sky_material = ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.075, 0.24, 0.48, 1.0)
    sky_material.sky_horizon_color = Color(0.64, 0.78, 0.92, 1.0)
    sky_material.ground_horizon_color = Color(0.48, 0.56, 0.58, 1.0)
    sky_material.ground_bottom_color = Color(0.10, 0.13, 0.15, 1.0)
    sky_material.sky_curve = 0.12
    sky_material.ground_curve = 0.10
    sky_material.sun_angle_max = 14.0
    sky_material.sun_curve = 0.08
    sky_material.use_debanding = true

    sky = Sky.new()
    sky.sky_material = sky_material
    environment.sky = sky
    world_environment.environment = environment
    add_child(world_environment)

func set_time_of_day(minutes: float) -> void:
    if sky_material == null:
        return
    var hour := fmod(minutes / 60.0, 24.0)
    var daylight := clampf(sin((hour - 6.0) / 12.0 * PI), 0.0, 1.0)
    var dusk := clampf(1.0 - absf(hour - 18.0) / 4.0, 0.0, 1.0)
    sky_material.sky_top_color = Color(0.018, 0.035, 0.09).lerp(Color(0.075, 0.24, 0.48), daylight).lerp(Color(0.20, 0.08, 0.13), dusk * 0.35)
    sky_material.sky_horizon_color = Color(0.10, 0.12, 0.20).lerp(Color(0.64, 0.78, 0.92), daylight).lerp(Color(0.95, 0.42, 0.20), dusk * 0.48)
    environment.ambient_light_energy = lerpf(0.24, 1.12, daylight)
