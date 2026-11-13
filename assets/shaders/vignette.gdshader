shader_type canvas_item;
// Vinheta escura nas bordas + grão de filme leve, para as cinemáticas.

uniform float strength : hint_range(0.0, 1.0) = 0.65;
uniform float grain : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.25, 0.85, length(d * vec2(1.0, 0.9)));
	float g = (hash(floor(UV * 480.0) + floor(TIME * 24.0)) - 0.5) * grain;
	COLOR = vec4(vec3(0.02, 0.0, 0.04) + g, v * strength);
}
