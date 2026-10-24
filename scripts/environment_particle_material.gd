extends RefCounted

const SOFT := preload("res://assets/shaders/environment/soft_particle.gdshader")

static func soft(color: Color, glow: float = 0.0) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = SOFT
    material.set_shader_parameter("tint", color)
    material.set_shader_parameter("glow", glow)
    return material
