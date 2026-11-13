shader_type canvas_item;
// Faixa de título dos menus: degradê que se move, listras diagonais suaves,
// brilho que varre da esquerda para a direita e linha de luz embaixo.

uniform vec4 color_a : source_color = vec4(0.95, 0.45, 0.15, 1.0);
uniform vec4 color_b : source_color = vec4(0.55, 0.2, 0.55, 1.0);
uniform float speed = 0.35;

void fragment() {
	float t = UV.x + sin(TIME * speed * 2.0 + UV.y * 2.0) * 0.08 - TIME * speed;
	vec3 col = mix(color_a.rgb, color_b.rgb, 0.5 + 0.5 * sin(t * 6.2832));
	float stripes = sin((UV.x * 90.0 + UV.y * 30.0) - TIME * 2.0) * 0.5 + 0.5;
	col += stripes * 0.05;
	// brilho varrendo
	float sweep = fract(TIME * 0.25) * 1.6 - 0.3;
	float shine = smoothstep(0.12, 0.0, abs(UV.x - UV.y * 0.3 - sweep));
	col += shine * 0.35;
	// luz na parte de baixo e leve escurecimento no topo
	col += smoothstep(0.85, 1.0, UV.y) * 0.25;
	col *= mix(0.85, 1.0, UV.y);
	COLOR = vec4(col, 1.0);
}
