shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled, depth_draw_opaque;

#include "wind_motion.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool black_key = false;
uniform float wind_speed = 2.5;
uniform float wind_strength = 0.045;
uniform float wave_frequency = 2.0;
uniform float gust_strength = 0.25;
uniform float gust_frequency = 0.8;
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);

void vertex() {
    VERTEX += environment_wind_motion(UV, TIME, clamp(UV.x, 0.0, 1.0), wind_direction, wind_strength, wave_frequency, wind_speed, gust_frequency, gust_strength);
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    if (tex.a < 0.35 || (black_key && max(tex.r, max(tex.g, tex.b)) < 0.10)) {
        discard;
    }
    // Foliage is opaque where a leaf exists. Avoid transparent sorting/overdraw.
    ALBEDO = tex.rgb;
    if (!FRONT_FACING) {
        NORMAL = -NORMAL;
    }
    ROUGHNESS = 0.95;
}
