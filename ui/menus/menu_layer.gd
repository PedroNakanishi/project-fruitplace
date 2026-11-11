class_name MenuLayer
extends Control
## Painel de menus genérico. `choose()` e `bills()` são aguardáveis:
##     var i := await MenuLayer.current.choose("Geladeira", "", ["A", "B"])
## O relógio continua correndo com o menu aberto (só o jogador fica parado).

signal _picked(index: int)

static var current: MenuLayer

var is_open := false
var _cancellable := true
var _center: CenterContainer
var _title: Label
var _body: Label
var _content: VBoxContainer


func _ready() -> void:
	current = self
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	_center = CenterContainer.new()
	_center.set_anchors_preset(PRESET_FULL_RECT)
	_center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	_center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
	vb.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = 420
	vb.add_child(_body)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	vb.add_child(_content)

	_center.hide()


## Mostra opções e devolve o índice escolhido, ou -1 se fechado (Esc).
## Durante a tela de contas, qualquer outro menu devolve -1 na hora.
func choose(title: String, body: String, options: Array) -> int:
	if is_open and not _cancellable:
		return -1
	_open(title, body, true)
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: _picked.emit(i))
		_content.add_child(b)
	_focus_first()
	var result: int = await _picked
	_close()
	return result


## Tela de contas: uma caixa por conta. Devolve id -> pago (bool).
func bills(lines: Array, money: int, note: String) -> Dictionary:
	_open("Contas da noite", note, false)
	var checks := {}
	var total_label := Label.new()
	var confirm := Button.new()
	var refresh := func() -> void:
		var t := 0
		for id: StringName in checks:
			if checks[id].button_pressed:
				t += int(checks[id].get_meta("cost"))
		total_label.text = "Total: R$ %d   ·   Saldo: R$ %d" % [t, money]
		confirm.disabled = t > money

	var budget := money
	for b: Dictionary in lines:
		var cb := CheckBox.new()
		cb.text = "%s — R$ %d (%s)" % [b.name, b.cost, b.effect]
		cb.set_meta("cost", b.cost)
		cb.button_pressed = budget >= b.cost  # marca o que dá para pagar, em ordem
		if cb.button_pressed:
			budget -= b.cost
		cb.toggled.connect(func(_on: bool) -> void: refresh.call())
		checks[b.id] = cb
		_content.add_child(cb)
	_content.add_child(total_label)
	confirm.text = "Confirmar e dormir"
	confirm.pressed.connect(func() -> void: _picked.emit(0))
	_content.add_child(confirm)
	refresh.call()
	_focus_first()

	await _picked
	var paid := {}
	for id: StringName in checks:
		paid[id] = checks[id].button_pressed
	_close()
	return paid


## Fecha o menu aberto; quem estava aguardando recebe -1.
func close() -> void:
	if is_open:
		_picked.emit(-1)


func _unhandled_input(event: InputEvent) -> void:
	if is_open and _cancellable and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _open(title: String, body: String, cancellable: bool) -> void:
	close()  # um menu por vez
	_clear()
	_title.text = title
	_body.text = body
	_body.visible = body != ""
	_cancellable = cancellable
	_center.show()
	is_open = true
	EventBus.ui_blocking = true
	EventBus.interaction_prompt.emit("")


func _close() -> void:
	_clear()
	_center.hide()
	is_open = false
	EventBus.ui_blocking = false


func _clear() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()


func _focus_first() -> void:
	for c in _content.get_children():
		if c is BaseButton and not c.disabled:
			c.grab_focus()
			return


func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.09, 0.2, 0.96)
	s.border_color = Color(1.0, 0.55, 0.2)
	s.set_border_width_all(3)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(18)
	return s
