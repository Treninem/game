shader_type spatial;
render_mode cull_disabled;

uniform sampler2D hair_texture : source_color;
uniform vec4 hair_color : source_color = vec4(0.45, 0.25, 0.12, 1.0);

void fragment() {
    vec4 strands = texture(hair_texture, UV);
    float value = dot(strands.rgb, vec3(0.2126, 0.7152, 0.0722));
    ALBEDO = hair_color.rgb * clamp(value * 6.0 + 0.08, 0.1, 1.0);
    ALPHA = strands.a;
    ALPHA_SCISSOR_THRESHOLD = 0.30;
    ROUGHNESS = 0.86;
}
