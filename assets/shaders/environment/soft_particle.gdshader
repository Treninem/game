shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0);
uniform float glow = 0.0;

void vertex() {
    vec3 size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * size.x, INV_VIEW_MATRIX[1] * size.y, INV_VIEW_MATRIX[2] * size.z, MODEL_MATRIX[3]);
}

void fragment() {
    float coverage = 1.0 - smoothstep(0.04, 0.5, length(UV - vec2(0.5)));
    ALBEDO = tint.rgb * (1.0 + glow);
    ALPHA = tint.a * coverage;
}
