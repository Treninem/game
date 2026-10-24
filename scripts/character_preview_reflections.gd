extends RefCounted

# A small static reflection environment complements the existing portrait
# lights. The plain editor backdrop and diffuse face lighting stay independent.
static func configure(environment: Environment) -> void:
    var material:=ProceduralSkyMaterial.new()
    material.sky_top_color=Color(.22,.29,.40)
    material.sky_horizon_color=Color(.62,.64,.66)
    material.ground_horizon_color=Color(.38,.35,.31)
    material.ground_bottom_color=Color(.10,.085,.07)
    material.sky_energy_multiplier=.65
    material.ground_energy_multiplier=.45
    var sky:=Sky.new()
    sky.radiance_size=Sky.RADIANCE_SIZE_64
    sky.process_mode=Sky.PROCESS_MODE_QUALITY
    sky.sky_material=material
    environment.sky=sky
    environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
