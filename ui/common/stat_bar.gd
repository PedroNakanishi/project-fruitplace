class_name StatBar
extends Control
## Barra de status animada por shader (fome, energia, gasolina, água).
## `set_value()` anima o enchimento e dispara um flash; abaixo de `low_below`
## a barra pisca em vermelho. O texto no meio vem de `text`.

const SHADER := preload("res://assets/shaders/stat_bar.gdshader")

@export var bar_color := Color(1.0, 0.6, 0.2)
@export var low_below := 0.2
var max_value := 100.0
var text := "":
	set(v):
		text = v
		if _label:
			_label.text = v

var _value := -1.0
var _shown := 1.0
var _mat: ShaderMaterial
var _label: Label
var _tween: Tween
var _flash_tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(170, 18)
	size_flags_vertical = SIZE_SHRINK_CENTER


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("color", bar_color)
	material = _mat
	_label = Label.new()
	_label.set_anchors_preset(PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 4)
	_label.text = text
	add_child(_label)
	resized.connect(_on_resized)
	_on_resized()
	_apply()


func _draw() -> void:
	# O shader desenha tudo; o retângulo só dá a área.
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)


func _on_resized() -> void:
	if _mat:
		_mat.set_shader_parameter("size", size)


## Muda o valor com enchimento suave. A primeira chamada não anima.
func set_value(v: float, maximum := -1.0) -> void:
	var first := _value < 0.0
	var changed := not is_equal_approx(v, _value) or (maximum > 0.0 and not is_equal_approx(maximum, max_value))
	if not changed:
		return
	if maximum > 0.0:
		max_value = maximum
	_value = v
	if _tween:
		_tween.kill()
	if first or not is_inside_tree():
		_shown = _fraction()
		_apply()
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_shown, _shown, _fraction(), 0.5)
	if changed:
		_flash()


func _fraction() -> float:
	return clampf(_value / maxf(max_value, 0.001), 0.0, 1.0)


func _set_shown(f: float) -> void:
	_shown = f
	_apply()


func _apply() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("fill", _shown)
	_mat.set_shader_parameter("low", 1.0 if _fraction() < low_below else 0.0)


func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 0.6, 0.0, 0.4)
