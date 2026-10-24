shader_type spatial;
uniform sampler2D eye_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool brown_iris = true;
void fragment() {
    vec3 pigment = texture(eye_texture, UV).rgb;
    // Measured pupil centroids in the unchanged 1024px brown atlas. The old
    // approximate centers left a red crescent outside the correction circle.
    float radius = min(distance(UV, vec2(0.28959326, 0.71127206)), distance(UV, vec2(0.70542749, 0.29916668)));
    float saturation = (max(pigment.r, max(pigment.g, pigment.b)) - min(pigment.r, min(pigment.g, pigment.b))) / max(max(pigment.r, max(pigment.g, pigment.b)), 0.001);
    float iris = (1.0 - smoothstep(0.120, 0.123, radius)) * smoothstep(0.10, 0.25, saturation);
    float fibers = dot(pigment, vec3(0.2126, 0.7152, 0.0722));
    vec3 brown = vec3(0.30, 0.19, 0.085) * fibers / (fibers + 0.04);
    ALBEDO = brown_iris ? mix(pigment, brown, iris) : pigment;
    ROUGHNESS = 0.22;
    SPECULAR = 0.65;
}
