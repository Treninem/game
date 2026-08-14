extends Node

signal weather_changed
signal season_changed(season: int)
signal underwater_changed(is_underwater: bool)

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
    _set_if_supported(material, available, &"melt", clampf((temperature_c - 0.5) / 8.0, 0.0, 1.0))
    _set_if_supported(material, available, &"snow_amount", maxf(snow_intensity, 0.45 if season == Season.WINTER else 0.0))
    _set_if_supported(material, available, &"wind_strength", wind_strength)
    _set_if_supported(material, available, &"wind_direction", wind_direction)

func _set_if_supported(material: ShaderMaterial, available: Dictionary, parameter: StringName, value: Variant) -> void:
    if available.has(parameter):
        material.set_shader_parameter(parameter, value)
