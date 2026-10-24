shader_type spatial;
render_mode cull_disabled;

uniform sampler2D hair_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 hair_color : source_color = vec4(0.45, 0.25, 0.12, 1.0);

void fragment() {
    vec4 strands = texture(hair_texture, UV);
    float value = dot(strands.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Compress authored strand highlights smoothly; a hard gain/clamp erases them.
    float strand_detail = value / (value + 0.08);
    ALBEDO = hair_color.rgb * (0.1 + 0.9 * strand_detail);
    ALPHA = strands.a;
    ALPHA_SCISSOR_THRESHOLD = 0.30;
    ROUGHNESS = 0.86;
}
