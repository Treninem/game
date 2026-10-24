vec3 environment_wind_motion(vec2 uv, float clock, float anchor, vec3 direction, float strength, float frequency, float speed, float gust_frequency_value, float gust_strength_value) {
    float phase = uv.x * frequency + uv.y * frequency * 0.35 + clock * speed;
    float gust = sin(clock * gust_frequency_value * 6.2831853 + uv.y * 2.0) * gust_strength_value;
    float wave = sin(phase) * strength * (0.65 + gust);
    vec3 dir = normalize(vec3(direction.x, 0.0, direction.z) + vec3(0.0001, 0.0, 0.0));
    return dir * wave * anchor + vec3(0.0, cos(phase * 0.73) * strength * 0.18 * anchor, 0.0);
}
