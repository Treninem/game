shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_albedo : source_color, filter_linear_mipmap;
uniform sampler2D base_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D season_mask : filter_linear_mipmap;
uniform vec4 autumn_tint : source_color = vec4(0.78, 0.52, 0.24, 1.0);
uniform vec4 winter_tint : source_color = vec4(0.9, 0.94, 1.0, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float dust : hint_range(0.0, 1.0) = 0.0;
uniform float autumn : hint_range(0.0, 1.0) = 0.0;
uniform float winter : hint_range(0.0, 1.0) = 0.0;
uniform float frost : hint_range(0.0, 1.0) = 0.0;
uniform float base_roughness : hint_range(0.0, 1.0) = 0.72;

void fragment() {
    vec3 base_col = texture(base_albedo, UV).rgb;
    vec3 normal_sample = texture(base_normal, UV).rgb;
    float mask = texture(season_mask, UV).r;

    vec3 col = base_col;
    col = mix(col, col * vec3(0.82, 0.68, 0.50), dust * mask);
    col = mix(col, col * autumn_tint.rgb, autumn * mask);
    col = mix(col, winter_tint.rgb, winter * mask * 0.65);
    col = mix(col, vec3(0.93, 0.97, 1.0), frost * mask * 0.55);
    col *= mix(1.0, 0.72, wetness);

    ALBEDO = col;
    NORMAL_MAP = mix(normal_sample, vec3(0.5, 0.5, 1.0), frost * mask * 0.35);
    ROUGHNESS = clamp(base_roughness + dust * 0.16 - wetness * 0.48 + frost * 0.10, 0.05, 1.0);
    SPECULAR = mix(0.35, 0.75, wetness);
}
