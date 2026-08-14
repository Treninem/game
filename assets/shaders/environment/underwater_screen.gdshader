shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 water_tint : source_color = vec4(0.04, 0.28, 0.38, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.45;
uniform float distortion_strength : hint_range(0.0, 0.03) = 0.006;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.1;
uniform float distortion_scale : hint_range(1.0, 40.0) = 11.0;
uniform float depth_darkening : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.18;

void fragment() {
    vec2 uv = SCREEN_UV;
    float wave_a = sin(uv.y * distortion_scale + TIME * distortion_speed);
    float wave_b = cos(uv.x * (distortion_scale * 0.83) - TIME * distortion_speed * 0.77);
    uv += vec2(wave_a, wave_b) * distortion_strength;

    vec3 scene = texture(screen_texture, uv).rgb;
    vec3 tinted = mix(scene, scene * water_tint.rgb, tint_strength);

    float radial = distance(SCREEN_UV, vec2(0.5));
    float vignette = smoothstep(0.2, 0.75, radial) * vignette_strength;
    float vertical_depth = smoothstep(0.0, 1.0, SCREEN_UV.y) * depth_darkening;

    tinted *= 1.0 - vignette - vertical_depth;
    COLOR = vec4(tinted, 1.0);
}
