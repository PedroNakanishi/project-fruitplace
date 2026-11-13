shader_type canvas_item;
// Barra de status animada: líquido com onda na borda, listras que correm,
// brilho de vidro, pisca vermelho quando está baixa e flash ao mudar.

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform vec4 color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform vec4 back : source_color = vec4(0.0, 0.0, 0.0, 0.55);
uniform float low : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec2 size = vec2(170.0, 18.0);
uniform float radius = 5.0;

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float d = rounded_box(p, size * 0.5, radius);
	float shape = 1.0 - smoothstep(-1.0, 0.0, d);
	float border = smoothstep(-2.0, -1.0, d);

	float wave = sin(UV.y * 14.0 + TIME * 4.0) * 0.012 + sin(UV.y * 5.0 - TIME * 2.5) * 0.008;
	float edge = fill + wave * step(0.001, fill) * step(fill, 0.99);
	float inside = 1.0 - step(edge, UV.x);

	vec3 col = back.rgb;
	float alpha = back.a;
	if (inside > 0.5) {
		float stripes = sin((UV.x * size.x + UV.y * size.y) * 0.4 - TIME * 5.0) * 0.5 + 0.5;
		col = color.rgb * (0.82 + 0.18 * stripes);
		col += smoothstep(0.45, 0.0, UV.y) * 0.22;          // brilho de vidro
		col -= smoothstep(0.7, 1.0, UV.y) * 0.18;           // sombra embaixo
		col += smoothstep(0.04, 0.0, edge - UV.x) * 0.35;   // borda do líquido brilha
		alpha = 1.0;
	}
	float pulse = 0.5 + 0.5 * sin(TIME * 9.0);
	col = mix(col, vec3(1.0, 0.25, 0.2), low * pulse * 0.55 * inside);
	col += flash * 0.5;
	col = mix(col, vec3(0.05, 0.03, 0.07), border * 0.8);
	COLOR = vec4(col, alpha * shape);
}
