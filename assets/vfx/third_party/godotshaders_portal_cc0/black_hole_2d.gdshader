shader_type canvas_item;

uniform bool _ShowDebugColors = false;
uniform sampler2D _ScreenTex : source_color, hint_screen_texture, repeat_disable;
uniform float _DistortionStrenght = 0.9;
uniform float _Attenuation = 10.0;

void fragment() {
	vec2 dir = UV - vec2(0.5);
	float dist = length(dir);
	dir *= pow(dist, -_DistortionStrenght);
	dir *= pow(1.0 - dist, _Attenuation);
	COLOR = vec4(texture(_ScreenTex, SCREEN_UV - dir).rgb, 1.0);

	if (_ShowDebugColors) {
		COLOR = vec4(UV - vec2(0.5), 0.0, 1.0);
	}
}
