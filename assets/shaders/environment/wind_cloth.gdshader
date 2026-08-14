shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

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
    float phase = UV.x * wave_frequency + UV.y * wave_frequency * 0.35 + TIME * wind_speed;
    float gust = sin(TIME * gust_frequency * 6.2831853 + UV.y * 2.0) * gust_strength;
    float wave = sin(phase) * wind_strength * (0.65 + gust);
    vec3 dir = normalize(vec3(wind_direction.x, 0.0, wind_direction.z) + vec3(0.0001, 0.0, 0.0));
    VERTEX += dir * wave * anchor;
    VERTEX.y += cos(phase * 0.73) * wind_strength * 0.18 * anchor;
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.15;
    ROUGHNESS = roughness;
}
