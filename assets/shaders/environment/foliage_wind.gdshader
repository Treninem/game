shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled, depth_draw_opaque;

#include "wind_motion.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform bool black_key = false;
uniform bool authored_blade_color = false;
uniform vec4 vegetation_tint : source_color = vec4(1.0);
uniform bool height_anchor = false;
uniform float canopy_normal_blend : hint_range(0.0,1.0) = 0.0;
uniform vec3 canopy_center = vec3(0.0);
uniform vec3 canopy_radius = vec3(1.0);
varying float canopy_edge;
uniform float foliage_desaturate : hint_range(0.0,1.0) = 0.0;
uniform float variation_strength : hint_range(0.0,1.0) = 0.0;
varying float plant_variation;
uniform float wind_speed = 2.5;
uniform float wind_strength = 0.045;
uniform float wave_frequency = 2.0;
uniform float gust_strength = 0.25;
uniform float gust_frequency = 0.8;
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);

void vertex() {
    plant_variation = mix(1.0,0.75+0.5*fract(dot(MODEL_MATRIX[3].xz,vec2(0.137,0.193))),variation_strength);
    vec3 radial = (VERTEX-canopy_center)/max(canopy_radius,vec3(0.1));
    canopy_edge = clamp(length(radial.xz),0.0,1.0);
    if (canopy_normal_blend > 0.0) {
        vec3 crown_normal = normalize(radial+vec3(0.0,0.15,0.0));
        NORMAL = normalize(mix(NORMAL,crown_normal,canopy_normal_blend));
    }
    float anchor_weight = height_anchor ? clamp(VERTEX.y * 1.5, 0.0, 1.0) : clamp(UV.x, 0.0, 1.0);
    // Each actual instance has a stable phase. Repeated leaf UVs no longer
    // make every tree/grass clump swing as one rigid synchronized field.
    float instance_phase = fract(dot(MODEL_MATRIX[3].xz, vec2(0.173, 0.117))) * 6.2831853;
    VERTEX += environment_wind_motion(UV, TIME + instance_phase, anchor_weight, wind_direction, wind_strength, wave_frequency, wind_speed, gust_frequency, gust_strength);
}

void fragment() {
    vec4 tex = authored_blade_color ? COLOR : texture(albedo_texture, UV);
    // source_color sampling is linear: 0.10 removes real dark green leaves.
    // Keep alpha coverage and reject only a near-black backing (~0.07 sRGB).
    if (tex.a < 0.35 || (black_key && max(tex.r, max(tex.g, tex.b)) < 0.006)) {
        discard;
    }
    // Foliage is opaque where a leaf exists. Avoid transparent sorting/overdraw.
    vec3 pigment = mix(tex.rgb,vec3(dot(tex.rgb,vec3(0.2126,0.7152,0.0722))),foliage_desaturate);
    ALBEDO = pigment * vegetation_tint.rgb * plant_variation * mix(1.0,mix(0.76,1.0,canopy_edge),canopy_normal_blend);
    if (!FRONT_FACING && canopy_normal_blend < 0.5) {
        NORMAL = -NORMAL;
    }
    ROUGHNESS = 0.95;
}
