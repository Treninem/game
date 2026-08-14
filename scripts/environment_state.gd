extends Node

signal weather_changed
signal season_changed(season: int)
signal underwater_changed(is_underwater: bool)
signal exposure_changed(exposure: float)

enum Season {
    SPRING,
    SUMMER,
    AUTUMN,
    WINTER
}

var season: Season = Season.SUMMER
var temperature_c: float = 18.0
var rain_intensity: float = 0.0
var snow_intensity: float = 0.0
var wetness: float = 0.0
var wind_strength: float = 0.15
var wind_direction: Vector3 = Vector3(1.0, 0.0, 0.0)
var fog_density: float = 0.0
var storm_intensity: float = 0.0
var frost_amount: float = 0.0
var dust_amount: float = 0.0
var snow_cover_amount: float = 0.0
var surface_freeze_amount: float = 0.0
var thaw_amount: float = 0.0
var local_exposure: float = 1.0
var is_underwater: bool = false

func set_weather(
        rain: float = rain_intensity,
        snow: float = snow_intensity,
        wind: float = wind_strength,
        storm: float = storm_intensity,
        fog: float = fog_density
    ) -> void:
    rain_intensity = clampf(rain, 0.0, 1.0)
    snow_intensity = clampf(snow, 0.0, 1.0)
    wind_strength = clampf(wind, 0.0, 1.0)
    storm_intensity = clampf(storm, 0.0, 1.0)
    fog_density = clampf(fog, 0.0, 1.0)
    wetness = clampf(max(wetness, rain_intensity * 0.9), 0.0, 1.0)
    weather_changed.emit()

func set_wind(direction: Vector3, strength: float) -> void:
    if direction.length_squared() > 0.0001:
        wind_direction = direction.normalized()
    wind_strength = clampf(strength, 0.0, 1.0)
    weather_changed.emit()

func set_temperature(value_c: float) -> void:
    temperature_c = value_c
    frost_amount = clampf((-temperature_c) / 12.0, 0.0, 1.0)
    if temperature_c > 2.0:
        snow_intensity = minf(snow_intensity, 0.2)
    weather_changed.emit()

func set_season(value: Season) -> void:
    if season == value:
        return
    season = value
    season_changed.emit(season)

func set_underwater(value: bool) -> void:
    if is_underwater == value:
        return
    is_underwater = value
    underwater_changed.emit(is_underwater)

func set_local_exposure(value: float) -> void:
    var resolved := clampf(value, 0.0, 1.0)
    if absf(local_exposure - resolved) < 0.002:
        return
    local_exposure = resolved
    exposure_changed.emit(local_exposure)

func effective_rain_intensity() -> float:
    return rain_intensity * local_exposure

func effective_snow_intensity() -> float:
    return snow_intensity * local_exposure

func tick_environment(delta: float) -> void:
    var drying_rate := 0.015
    if rain_intensity <= 0.01 and temperature_c > 0.0:
        wetness = move_toward(wetness, 0.0, delta * drying_rate * (1.0 + temperature_c / 25.0))
    elif rain_intensity > 0.01:
        wetness = move_toward(wetness, rain_intensity, delta * 0.12)

    if season == Season.SUMMER and rain_intensity < 0.05:
        dust_amount = move_toward(dust_amount, 0.75, delta * 0.01)
    else:
        dust_amount = move_toward(dust_amount, 0.0, delta * 0.03)

    _tick_snow_cover(delta)
    _tick_surface_freeze(delta)

func _tick_snow_cover(delta: float) -> void:
    if snow_intensity > 0.01 and temperature_c <= 1.5:
        var cold_bonus := clampf((-temperature_c) / 18.0, 0.0, 0.55)
        var accumulation_rate := 0.010 + cold_bonus * 0.010
        snow_cover_amount = clampf(snow_cover_amount + delta * snow_intensity * accumulation_rate, 0.0, 1.0)
        return

    if temperature_c > -0.5 or rain_intensity > 0.08:
        var warm_factor := clampf(maxf(temperature_c, 0.0) / 18.0, 0.0, 1.0)
        var melt_rate := 0.0025 + warm_factor * 0.018 + rain_intensity * 0.010
        snow_cover_amount = move_toward(snow_cover_amount, 0.0, delta * melt_rate)

func _tick_surface_freeze(delta: float) -> void:
    var freeze_drive := clampf((0.5 - temperature_c) / 10.0, 0.0, 1.0)
    var moisture_drive := clampf(maxf(wetness, snow_cover_amount * 0.7), 0.0, 1.0)

    if freeze_drive > 0.01 and moisture_drive > 0.08:
        var target_freeze := clampf(freeze_drive * (0.45 + moisture_drive * 0.55), 0.0, 1.0)
        var freeze_speed := 0.003 + freeze_drive * 0.014
        surface_freeze_amount = move_toward(surface_freeze_amount, target_freeze, delta * freeze_speed)
    elif temperature_c > 0.5:
        var thaw_speed := 0.004 + clampf((temperature_c - 0.5) / 16.0, 0.0, 1.0) * 0.020 + rain_intensity * 0.006
        surface_freeze_amount = move_toward(surface_freeze_amount, 0.0, delta * thaw_speed)

    thaw_amount = clampf((temperature_c - 0.5) / 8.0, 0.0, 1.0) * (1.0 - surface_freeze_amount)

func _process(delta: float) -> void:
    tick_environment(delta)

func apply_environment_material(material: ShaderMaterial) -> void:
    if material == null or material.shader == null:
        return

    var available := {}
    for uniform_info in material.shader.get_shader_uniform_list():
        available[StringName(uniform_info.get("name", ""))] = true

    _set_if_supported(material, available, &"wetness", wetness)
    _set_if_supported(material, available, &"dust", dust_amount)
    _set_if_supported(material, available, &"frost", frost_amount)
    _set_if_supported(material, available, &"winter", 1.0 if season == Season.WINTER else 0.0)
    _set_if_supported(material, available, &"autumn", 1.0 if season == Season.AUTUMN else 0.0)
    _set_if_supported(material, available, &"melt", thaw_amount)
    _set_if_supported(material, available, &"thaw_amount", thaw_amount)
    _set_if_supported(material, available, &"freeze_amount", surface_freeze_amount)
    _set_if_supported(material, available, &"snow_amount", maxf(snow_cover_amount, snow_intensity * 0.18))
    _set_if_supported(material, available, &"wind_strength", wind_strength)
    _set_if_supported(material, available, &"wind_direction", wind_direction)

func _set_if_supported(material: ShaderMaterial, available: Dictionary, parameter: StringName, value: Variant) -> void:
    if available.has(parameter):
        material.set_shader_parameter(parameter, value)
