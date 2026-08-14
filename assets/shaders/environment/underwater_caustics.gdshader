shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec3 caustic_color : source_color = vec3(0.42, 0.78, 0.92);
uniform float intensity : hint_range(0.0, 2.0) = 0.55;
uniform float scale : hint_range(0.05, 6.0) = 1.35;
uniform float speed : hint_range(0.0, 3.0) = 0.55;
uniform float breakup : hint_range(0.1, 4.0) = 1.3;
uniform float opacity : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_pos;

float caustic_layer(vec2 p, float t) {
    float a = sin(p.x * 1.7 + t * 1.1 + sin(p.y * 1.3 - t * 0.7));
    float b = cos(p.y * 1.9 - t * 0.8 + cos(p.x * 1.1 + t * 0.9));
    float c = sin((p.x + p.y) * 1.25 + t * 0.55);
    float lines = abs(a * b * c);
    return pow(clamp(lines, 0.0, 1.0), 2.25);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 p = world_pos.xz * scale;
    float t = TIME * speed;
    float c1 = caustic_layer(p, t);
    float c2 = caustic_layer(p * breakup + vec2(2.7, -1.4), -t * 0.73);
    float caustic = clamp(c1 * 0.72 + c2 * 0.48, 0.0, 1.0);
    caustic = smoothstep(0.28, 0.82, caustic);

    ALBEDO = caustic_color * caustic * intensity;
    EMISSION = caustic_color * caustic * intensity;
    ALPHA = caustic * opacity;
}
