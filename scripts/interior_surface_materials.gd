extends RefCounted

const ROOT := "res://assets/production/medieval/quaternius_city_core/"
const PLASTER := preload("res://assets/production/interiors/materials/lime_plaster/albedo.jpg")
const PLASTER_NORMAL := preload("res://assets/production/interiors/materials/lime_plaster/normal.png")
const PLASTER_ORM := preload("res://assets/production/interiors/materials/lime_plaster/orm.png")
const WOOD := preload("res://assets/production/interiors/materials/wood_planks.jpg")

static func _base(tint: Color, tiles_per_metre: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.uv1_triplanar = true
    material.uv1_world_triplanar = true
    material.uv1_scale = Vector3.ONE * tiles_per_metre
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    return material

static func plaster(tint: Color) -> StandardMaterial3D:
    var material := _base(tint, 0.5)
    material.albedo_texture = PLASTER
    material.normal_enabled = true
    material.normal_texture = PLASTER_NORMAL
    material.normal_scale = 0.35
    material.roughness = 1.0
    material.roughness_texture = PLASTER_ORM
    material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
    material.ao_enabled = true
    material.ao_texture = PLASTER_ORM
    material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
    material.ao_light_affect = 0.1
    return material

static func wood(tint: Color) -> StandardMaterial3D:
    var material := _base(tint, 0.5)
    material.albedo_texture = WOOD
    material.roughness = 0.9
    return material
