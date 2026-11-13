class_name UiTheme
extends RefCounted
## Tema único da interface (botões, caixas de seleção, rótulos).

const BG := Color(0.16, 0.09, 0.2, 0.96)
const ACCENT := Color(1.0, 0.55, 0.2)
const GOLD := Color(1.0, 0.72, 0.3)


static func box(bg: Color, border: Color, border_w := 2, margin := 10, radius := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin + 4
	s.content_margin_right = margin + 4
	s.content_margin_top = margin - 3
	s.content_margin_bottom = margin - 3
	return s


static func make() -> Theme:
	var t := Theme.new()
	t.set_stylebox("normal", "Button", box(Color(0.26, 0.15, 0.31), Color(0.45, 0.28, 0.5)))
	t.set_stylebox("hover", "Button", box(Color(0.4, 0.22, 0.3), ACCENT))
	t.set_stylebox("pressed", "Button", box(Color(0.7, 0.35, 0.15), GOLD))
	t.set_stylebox("focus", "Button", box(Color(0.4, 0.22, 0.3), GOLD, 3))
	t.set_stylebox("disabled", "Button", box(Color(0.18, 0.12, 0.2), Color(0.28, 0.22, 0.3)))
	t.set_color("font_color", "Button", Color(0.96, 0.92, 0.98))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.6))
	t.set_stylebox("normal", "CheckBox", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("hover", "CheckBox", box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("pressed", "CheckBox", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("focus", "CheckBox", box(Color(1, 1, 1, 0.1), GOLD, 2, 6))
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	return t
