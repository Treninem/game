shader_type spatial;

uniform sampler2D eye_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool brown_iris = true;

void fragment() {
    vec3 pigment = texture(eye_texture, UV).rgb;
    // Both source globes share this authored atlas. Correct its red-brown iris
    // locally; tinting the entire material would also dye the sclera/veins.
    float radius = min(distance(UV, vec2(0.256, 0.738)), distance(UV, vec2(0.714, 0.322)));
    float iris = 1.0 - smoothstep(0.112, 0.119, radius);
    vec3 brown = pigment * vec3(0.70, 1.10, 1.0);
    ALBEDO = brown_iris ? mix(pigment, brown, iris) : pigment;
    ROUGHNESS = 0.22;
    SPECULAR = 0.65;
}
