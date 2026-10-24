extends Node

var world_environment: WorldEnvironment
var environment: Environment
var sky: Sky
var sky_material: ProceduralSkyMaterial
var lighting_elapsed := 0.0

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color(0.12, 0.22, 0.34, 1.0))
    _build_environment()
    SettingsManager.call_deferred("apply_world_quality")
    set_time_of_day(GameState.world_minutes)

func _process(delta: float) -> void:
    lighting_elapsed += delta
    if lighting_elapsed >= 0.25:
        lighting_elapsed = 0.0
        set_time_of_day(GameState.world_minutes)

func _build_environment() -> void:
    world_environment = WorldEnvironment.new()
    world_environment.name = "StableWorldEnvironment"

    environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.76, 0.82)
    environment.ambient_light_sky_contribution = 0.35
    environment.ambient_light_energy = 1.12
    environment.background_energy_multiplier = 1.0
    environment.fog_enabled = true
    environment.fog_density = 0.0015
    environment.fog_light_color = Color(0.65, 0.74, 0.72)
    environment.fog_sky_affect = 0.18

    sky_material = ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.075, 0.24, 0.48, 1.0)
    sky_material.sky_horizon_color = Color(0.64, 0.78, 0.92, 1.0)
    sky_material.ground_horizon_color = Color(0.48, 0.56, 0.58, 1.0)
    sky_material.ground_bottom_color = Color(0.10, 0.13, 0.15, 1.0)
    sky_material.sky_curve = 0.12
    sky_material.ground_curve = 0.10
    sky_material.sun_angle_max = 1.0
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
    var hour := fposmod(minutes / 60.0, 24.0)
    var daylight := clampf(sin((hour - 6.0) / 12.0 * PI), 0.0, 1.0)
    var horizon_distance := minf(absf(hour - 6.0), absf(hour - 18.0))
    var dusk := 1.0 - smoothstep(0.0, 2.0, horizon_distance)
    sky_material.sky_top_color = Color(0.018, 0.035, 0.09).lerp(Color(0.075, 0.24, 0.48), daylight).lerp(Color(0.20, 0.08, 0.13), dusk * 0.35)
    sky_material.sky_horizon_color = Color(0.10, 0.12, 0.20).lerp(Color(0.64, 0.78, 0.92), daylight).lerp(Color(0.95, 0.42, 0.20), dusk * 0.48)
    # A dark procedural sky erased skin/clothes in Compatibility shadows.
    # Keep a bounded cool night fill while preserving the day/night contrast.
    environment.ambient_light_color = Color(0.40, 0.47, 0.62).lerp(Color(0.72, 0.76, 0.82), daylight)
    environment.ambient_light_energy = lerpf(0.55, 0.75, daylight)
    environment.fog_light_color = Color(0.08, 0.11, 0.17).lerp(Color(0.65, 0.74, 0.72), daylight)
    environment.fog_density = 0.0015 + EnvironmentState.fog_density * 0.015
    var sun := get_parent().get_node_or_null("Sun") as DirectionalLight3D
    if sun != null:
        # Keep the solar orbit continuous below the horizon too. Night readability
        # comes from ambient fill; a fake overhead sun must not jump at dawn.
        sun.rotation_degrees.x = -(hour - 6.0) * 15.0
        sun.light_energy = 1.25 * daylight * smoothstep(0.0, 0.12, daylight)
        sun.light_color = Color(1.0, 0.64, 0.38).lerp(Color(1.0, 0.95, 0.85), daylight)
