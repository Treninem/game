shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform vec4 mark_color : source_color = vec4(0.12, 0.09, 0.06, 0.72);
uniform int mark_kind : hint_range(0, 6) = 0;
uniform float mark_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.001, 0.25) = 0.05;

float circle_mask(vec2 p, vec2 c, float r) {
    float d = distance(p, c);
    return 1.0 - smoothstep(r - edge_softness, r + edge_softness, d);
}

float ellipse_mask(vec2 p, vec2 c, vec2 r) {
    vec2 q = (p - c) / max(r, vec2(0.001));
    float d = length(q);
    return 1.0 - smoothstep(1.0 - edge_softness * 3.0, 1.0 + edge_softness * 3.0, d);
}

float footprint(vec2 uv) {
    float sole = ellipse_mask(uv, vec2(0.50, 0.52), vec2(0.19, 0.33));
    float heel = ellipse_mask(uv, vec2(0.50, 0.78), vec2(0.15, 0.13));
    float toe1 = circle_mask(uv, vec2(0.39, 0.20), 0.070);
    float toe2 = circle_mask(uv, vec2(0.47, 0.16), 0.075);
    float toe3 = circle_mask(uv, vec2(0.56, 0.16), 0.070);
    float toe4 = circle_mask(uv, vec2(0.64, 0.20), 0.058);
    return clamp(max(sole, heel) + max(max(toe1, toe2), max(toe3, toe4)), 0.0, 1.0);
}

float tire(vec2 uv) {
    float left_band = 1.0 - smoothstep(0.075, 0.10, abs(uv.x - 0.34));
    float right_band = 1.0 - smoothstep(0.075, 0.10, abs(uv.x - 0.66));
    float tread = step(0.42, fract(uv.y * 8.0 + uv.x * 2.0));
    float center = step(0.47, fract(uv.y * 12.0));
    return clamp((left_band + right_band) * mix(0.45, 1.0, tread) + center * 0.12, 0.0, 1.0);
}

float mud(vec2 uv) {
    float m = ellipse_mask(uv, vec2(0.50, 0.54), vec2(0.34, 0.28));
    m += circle_mask(uv, vec2(0.22, 0.35), 0.10);
    m += circle_mask(uv, vec2(0.76, 0.30), 0.08);
    m += circle_mask(uv, vec2(0.70, 0.75), 0.06);
    m *= 0.72 + 0.28 * sin((uv.x * 23.0 + uv.y * 31.0) * 3.14159);
    return clamp(m, 0.0, 1.0);
}

float scorch(vec2 uv) {
    vec2 p = uv - vec2(0.5);
    float a = atan(p.y, p.x);
    float radius = 0.34 + sin(a * 7.0) * 0.035 + sin(a * 13.0) * 0.02;
    float d = length(p);
    float outer = 1.0 - smoothstep(radius - 0.05, radius + 0.04, d);
    float center = smoothstep(0.04, 0.20, d);
    return clamp(outer * (0.45 + center * 0.55), 0.0, 1.0);
}

float spill(vec2 uv) {
    float main_blob = ellipse_mask(uv, vec2(0.50, 0.52), vec2(0.33, 0.25));
    float drips = circle_mask(uv, vec2(0.24, 0.64), 0.07) + circle_mask(uv, vec2(0.77, 0.40), 0.055);
    return clamp(main_blob + drips, 0.0, 1.0);
}

float paw(vec2 uv) {
    float pad = ellipse_mask(uv, vec2(0.50, 0.62), vec2(0.20, 0.16));
    float toe1 = circle_mask(uv, vec2(0.32, 0.36), 0.090);
    float toe2 = circle_mask(uv, vec2(0.44, 0.28), 0.095);
    float toe3 = circle_mask(uv, vec2(0.57, 0.28), 0.095);
    float toe4 = circle_mask(uv, vec2(0.69, 0.36), 0.085);
    return clamp(max(pad, max(max(toe1, toe2), max(toe3, toe4))), 0.0, 1.0);
}

float hoof(vec2 uv) {
    float left = ellipse_mask(uv, vec2(0.41, 0.49), vec2(0.13, 0.30));
    float right = ellipse_mask(uv, vec2(0.59, 0.49), vec2(0.13, 0.30));
    float cut = ellipse_mask(uv, vec2(0.50, 0.54), vec2(0.055, 0.25));
    return clamp(max(left, right) * (1.0 - cut * 0.78), 0.0, 1.0);
}

void fragment() {
    float mask = footprint(UV);
    if (mark_kind == 1) {
        mask = tire(UV);
    } else if (mark_kind == 2) {
        mask = mud(UV);
    } else if (mark_kind == 3) {
        mask = scorch(UV);
    } else if (mark_kind == 4) {
        mask = spill(UV);
    } else if (mark_kind == 5) {
        mask = paw(UV);
    } else if (mark_kind == 6) {
        mask = hoof(UV);
    }

    ALBEDO = mark_color.rgb;
    ALPHA = clamp(mask * mark_color.a * mark_alpha, 0.0, 1.0);
}
