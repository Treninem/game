shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_albedo : source_color, filter_linear_mipmap;
uniform sampler2D base_normal : hint_normal, filter_linear_mipmap;
uniform vec4 snow_color : source_color = vec4(0.92, 0.96, 1.0, 1.0);
uniform float snow_amount : hint_range(0.0, 1.0) = 0.55;
uniform float snow_softness : hint_range(0.25, 8.0) = 2.0;
uniform float snow_roughness : hint_range(0.0, 1.0) = 0.72;
uniform float base_roughness : hint_range(0.0, 1.0) = 0.75;
uniform float melt : hint_range(0.0, 1.0) = 0.0;
uniform vec3 world_up = vec3(0.0, 1.0, 0.0);

void fragment() {
    vec3 base_col = texture(base_albedo, UV).rgb;
    vec3 normal_sample = texture(base_normal, UV).rgb;

    vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    float facing_up = clamp(dot(world_normal, normalize(world_up)), 0.0, 1.0);
    float coverage = pow(facing_up, snow_softness);
    coverage = smoothstep(1.0 - snow_amount, 1.0, coverage);
    coverage *= 1.0 - melt;

    ALBEDO = mix(base_col, snow_color.rgb, coverage);
    NORMAL_MAP = mix(normal_sample, vec3(0.5, 0.5, 1.0), coverage * 0.7);
    ROUGHNESS = mix(base_roughness, snow_roughness, coverage);
}
