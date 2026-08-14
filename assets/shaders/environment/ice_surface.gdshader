shader_type spatial;
render_mode cull_disabled;

uniform vec4 water_color : source_color = vec4(0.10, 0.30, 0.42, 0.72);
uniform vec4 ice_color : source_color = vec4(0.52, 0.76, 0.88, 0.84);
uniform vec4 frost_color : source_color = vec4(0.92, 0.97, 1.0, 1.0);
uniform float freeze_amount : hint_range(0.0, 1.0) = 1.0;
uniform float crack_amount : hint_range(0.0, 1.0) = 0.15;
uniform float frost : hint_range(0.0, 1.0) = 0.08;
uniform float thaw_amount : hint_range(0.0, 1.0) = 0.0;
uniform float wave_strength : hint_range(0.0, 0.2) = 0.035;
uniform float pattern_scale : hint_range(0.1, 8.0) = 2.4;
uniform float crack_scale : hint_range(1.0, 24.0) = 9.0;

varying vec3 world_pos;

float crack_pattern(vec2 p) {
    float a = abs(sin(p.x * 1.13 + sin(p.y * 0.71)));
    float b = abs(sin(p.y * 1.37 - cos(p.x * 0.83)));
    float c = abs(sin((p.x + p.y) * 0.91 + sin(p.x * 0.42)));
    float ridge = min(a, min(b, c));
    return 1.0 - smoothstep(0.025, 0.095, ridge);
}

float frost_pattern(vec2 p) {
    float f1 = sin(p.x * 2.1 + sin(p.y * 1.4));
    float f2 = cos(p.y * 2.5 - cos(p.x * 1.7));
    return smoothstep(0.10, 0.95, abs(f1 * f2));
}

void vertex() {
    float liquid = 1.0 - freeze_amount;
    VERTEX.y += (sin(VERTEX.x * 1.6 + TIME * 1.4) + cos(VERTEX.z * 1.25 - TIME * 1.1)) * wave_strength * liquid;
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 p = world_pos.xz * pattern_scale;
    float cracks = crack_pattern(p * crack_scale * 0.1) * crack_amount * freeze_amount;
    float frost_noise = frost_pattern(p * 1.7) * frost * freeze_amount;

    vec3 base = mix(water_color.rgb, ice_color.rgb, freeze_amount);
    base = mix(base, frost_color.rgb, clamp(frost_noise, 0.0, 0.82));
    base *= mix(1.0, 0.80, thaw_amount * 0.45);
    base = mix(base, vec3(0.72, 0.90, 1.0), cracks * 0.70);

    ALBEDO = base;
    ROUGHNESS = clamp(mix(0.09, 0.28, freeze_amount) + frost * 0.30 - thaw_amount * 0.12, 0.04, 0.72);
    SPECULAR = 0.88;
    METALLIC = 0.0;
    EMISSION = vec3(0.14, 0.26, 0.34) * cracks * 0.10;
    ALPHA = mix(water_color.a, ice_color.a, freeze_amount);
}
