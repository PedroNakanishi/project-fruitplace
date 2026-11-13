shader_type canvas_item;
// Transição entre mapas. `progress` 0 = tela livre, 1 = tela coberta.
// style 0: íris fechando no jogador; 1: dissolução em blocos (pixel art).

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int style = 0;
uniform vec2 center = vec2(0.5);
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec4 color : source_color = vec4(0.1, 0.05, 0.12, 1.0);
uniform float cells = 18.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float m = 0.0;
	if (style == 0) {
		float max_r = length(max(center, 1.0 - center) * aspect) * 1.05;
		float r = mix(max_r, -0.03, progress);
		float d = length((UV - center) * aspect);
		m = smoothstep(r - 0.012, r + 0.012, d);
	} else {
		vec2 cell = floor(UV * vec2(cells * aspect.x, cells));
		float diag = (cell.x / (cells * aspect.x) + cell.y / cells) * 0.5;
		float h = mix(hash(cell), diag, 0.55);
		m = 1.0 - step(progress * 1.02, h);
	}
	// Um leve vinco mais escuro na borda da íris/dissolução.
	COLOR = vec4(color.rgb, color.a * m);
}
