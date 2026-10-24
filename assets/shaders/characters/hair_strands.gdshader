shader_type spatial;
render_mode cull_disabled, alpha_to_coverage;

uniform sampler2D hair_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 hair_color : source_color = vec4(0.45, 0.25, 0.12, 1.0);
uniform float strand_relief : hint_range(0.0, 1.0) = 0.45;
uniform float strand_contrast : hint_range(0.0, 1.0) = 0.85;
uniform bool eyebrows = false;

float strand_value(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
    vec4 strands = texture(hair_texture, UV);
    float value = strand_value(strands.rgb);
    float strand_detail = value / (value + 0.08);
    vec2 extent = vec2(textureSize(hair_texture, 0));
    float footprint = max(length(dFdx(UV) * extent), length(dFdy(UV) * extent));
    float blur_level = max(3.0, log2(max(footprint, 1.0)) + 2.0);
    float neighborhood = strand_value(textureLod(hair_texture, UV, blur_level).rgb);
    // Increase local strand separation without shifting the whole saved pigment.
    float separation = clamp(sqrt((value + 0.003) / (neighborhood + 0.003)), 0.45, 1.75);
    float close_detail = 1.0 - smoothstep(2.0, 8.0, footprint);
    ALBEDO = hair_color.rgb * (0.1 + 0.9 * strand_detail) * mix(1.0, separation, strand_contrast * close_detail);
    ALPHA = strands.a;
    ALPHA_SCISSOR_THRESHOLD = 0.30;
    ALPHA_ANTIALIASING_EDGE = 0.25;
    ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(hair_texture, 0));
    ROUGHNESS = eyebrows ? 0.90 : mix(0.80, 0.60, strand_detail);
    SPECULAR = eyebrows ? 0.15 : 0.35;
    // Finite differences follow the authored strand atlas, not a world-space noise.
    NORMAL_MAP = vec3(0.5, 0.5, 1.0);
    NORMAL_MAP_DEPTH = strand_relief * close_detail;
    if (!eyebrows && footprint < 8.0 && strand_relief > 0.0) {
        vec2 pixel = 1.0 / extent;
        float left = sqrt(strand_value(texture(hair_texture, UV - vec2(pixel.x, 0.0)).rgb));
        float right = sqrt(strand_value(texture(hair_texture, UV + vec2(pixel.x, 0.0)).rgb));
        float down = sqrt(strand_value(texture(hair_texture, UV - vec2(0.0, pixel.y)).rgb));
        float up = sqrt(strand_value(texture(hair_texture, UV + vec2(0.0, pixel.y)).rgb));
        NORMAL_MAP = normalize(vec3((left-right)*2.0, (up-down)*2.0, 1.0)) * 0.5 + 0.5;
    }
}
