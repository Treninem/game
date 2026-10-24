shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

#include "wind_motion.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float wind_speed : hint_range(0.0, 12.0) = 2.5;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.18;
uniform float wave_frequency : hint_range(0.1, 20.0) = 5.0;
uniform float gust_strength : hint_range(0.0, 1.0) = 0.25;
uniform float gust_frequency : hint_range(0.1, 8.0) = 0.8;
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.75;

void vertex() {
    float anchor = clamp(UV.x, 0.0, 1.0);
    VERTEX += environment_wind_motion(UV, TIME, anchor, wind_direction, wind_strength, wave_frequency, wind_speed, gust_frequency, gust_strength);
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.15;
    ROUGHNESS = roughness;
}
