shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D leaf_mask : filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.32, 0.40, 0.11, 0.65);

void vertex() {
    vec3 size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * size.x, INV_VIEW_MATRIX[1] * size.y, INV_VIEW_MATRIX[2] * size.z, MODEL_MATRIX[3]);
    float angle = INSTANCE_CUSTOM.x;
    VERTEX.xy = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * VERTEX.xy;
}

void fragment() {
    // One existing leaf silhouette from the staged CC0 atlas, rather than a rectangle.
    vec2 uv = vec2(0.13, 0.05) + UV * vec2(0.18, 0.24);
    float mask = texture(leaf_mask, uv).r;
    ALBEDO = tint.rgb;
    ALPHA = mask * tint.a;
}
