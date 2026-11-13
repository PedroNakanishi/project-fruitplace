class_name UiFx
extends RefCounted
## Efeitos de botão: realce ao passar/focar, "aperto" ao clicar e sons.

static var _quiet_until := 0


## Silencia o som de foco por um instante (ao abrir um menu, o primeiro
## botão ganha foco e já tem o som de abertura).
static func quiet(ms := 200) -> void:
	_quiet_until = Time.get_ticks_msec() + ms


static func hook(b: BaseButton) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(_hover.bind(b))
	b.focus_entered.connect(_hover.bind(b))
	b.mouse_exited.connect(_rest.bind(b))
	b.focus_exited.connect(_rest.bind(b))
	b.button_down.connect(_press.bind(b))


static func _tween(b: Control, scale: Vector2, secs: float, trans := Tween.TRANS_BACK) -> void:
	if not b.is_inside_tree():
		return
	var tw := b.create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", scale, secs)
	b.set_meta(&"fx_tween", tw)


static func _hover(b: BaseButton) -> void:
	if b.disabled:
		return
	if Time.get_ticks_msec() > _quiet_until:
		Sfx.play(&"ui_hover", -4.0, 0.03)
	_tween(b, Vector2(1.04, 1.04), 0.12)


static func _rest(b: BaseButton) -> void:
	if b.has_focus() or b.is_hovered():
		return
	_tween(b, Vector2.ONE, 0.12)


static func _press(b: BaseButton) -> void:
	if b.disabled or not b.is_inside_tree():
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(0.95, 0.95), 0.05)
	tw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
