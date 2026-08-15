shader_type canvas_item;

uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.8;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.15;
uniform vec4 color : source_color = vec4(0.98, 0.92, 0.79, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float fade = smoothstep(0.8, 0.2, dist);
	float edge = smoothstep(0.5, 0.5 - edge_softness, dist);
	float pulse = 0.85 + 0.15 * sin(TIME * speed * 6.0);
	float final = fade * edge * glow_strength * pulse;
	COLOR = vec4(color.rgb * final, final);
}
