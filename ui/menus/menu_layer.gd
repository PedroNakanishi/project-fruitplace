class_name MenuLayer
extends Control
## Painel de menus genérico. `choose()` e `bills()` são aguardáveis:
##     var i := await MenuLayer.current.choose("Geladeira", "", ["A", "B"])
## O relógio continua correndo com o menu aberto (só o jogador fica parado).

signal _picked(index: int)

const CARD_SIZE := Vector2(150, 200)
const CARD_COLUMNS := 3
const CARD_GAP := 10
const WINDOW_MARGIN := 18

static var current: MenuLayer

var is_open := false
var _cancellable := true
var _center: CenterContainer
var _dim: ColorRect
var _panel: PanelContainer
var _anim: Tween
var _title: Label
var _body: Label
var _content: VBoxContainer


func _ready() -> void:
	current = self
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = UiTheme.make()

	_dim = ColorRect.new()
	_dim.set_anchors_preset(PRESET_FULL_RECT)
	_dim.color = Color(0.05, 0.02, 0.08, 0.5)
	_dim.mouse_filter = MOUSE_FILTER_IGNORE
	_dim.modulate.a = 0.0
	_dim.hide()
	add_child(_dim)

	_center = CenterContainer.new()
	_center.set_anchors_preset(PRESET_FULL_RECT)
	_center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(460, 0)
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size / 2.0)
	_center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)

	var header := UiTheme.header("")
	vb.add_child(header)
	_title = header.get_child(0)

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
		UiFx.hook(b)
		b.pressed.connect(func() -> void:
			Sfx.play(&"ui_select")
			_picked.emit(i))
		_content.add_child(b)
	_focus_first()
	var result: int = await _picked
	_close()
	return result


## Menu de itens em cartões: cada item é um dict com `name`, `icon` (Texture2D),
## e, opcionalmente, `desc`, `price` (>= 0 mostra "R$ n"), `note` e `disabled`.
## Devolve o índice do item, `items.size()` para "Voltar" ou -1 se fechado (Esc).
func choose_items(title: String, body: String, items: Array, back_label := "Voltar") -> int:
	if is_open and not _cancellable:
		return -1
	_open(title, body, true)
	var cols := mini(items.size(), CARD_COLUMNS)
	_panel.custom_minimum_size.x = CARD_SIZE.x * cols + CARD_GAP * (cols - 1) + WINDOW_MARGIN * 2.0
	var grid := GridContainer.new()
	grid.columns = CARD_COLUMNS
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content.add_child(grid)
	for i in items.size():
		var card := _make_card(items[i])
		card.pressed.connect(func() -> void:
			Sfx.play(&"ui_select")
			_picked.emit(i))
		grid.add_child(card)
	var back := Button.new()
	back.text = back_label
	UiFx.hook(back)
	back.pressed.connect(func() -> void:
		Sfx.play(&"ui_cancel")
		_picked.emit(items.size()))
	_content.add_child(back)
	_focus_first()
	var result: int = await _picked
	_close()
	return result


## Cartão: [nome] [imagem] [descrição, se houver] [preço, se houver].
func _make_card(item: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.disabled = item.get("disabled", false)
	card.clip_contents = true
	UiFx.hook(card)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	card.add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)

	col.add_child(_card_label(item.get("name", ""), 15, UiTheme.GOLD, true))
	var pic := TextureRect.new()
	pic.texture = item.get("icon")
	pic.custom_minimum_size = Vector2(0, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(pic)
	var desc: String = item.get("desc", "")
	if desc != "":
		var d := _card_label(desc, 12, Color(0.85, 0.82, 0.9), true)
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(d)
	else:
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(spacer)
	var note: String = item.get("note", "")
	if note != "":
		col.add_child(_card_label(note, 12, Color(0.7, 0.8, 1.0), true))
	var price: int = item.get("price", -1)
	if price >= 0:
		col.add_child(_card_label("R$ %d" % price, 16, Color(0.55, 1.0, 0.55), true))
	return card


func _card_label(text: String, size: int, color: Color, center: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


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
		UiFx.hook(cb)
		cb.toggled.connect(func(_on: bool) -> void:
			Sfx.play(&"ui_select")
			refresh.call())
		checks[b.id] = cb
		_content.add_child(cb)
	_content.add_child(total_label)
	confirm.text = "Confirmar e dormir"
	UiFx.hook(confirm)
	confirm.pressed.connect(func() -> void:
		Sfx.play(&"ui_select")
		_picked.emit(0))
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
		Sfx.play(&"ui_cancel")
		close()


func _open(title: String, body: String, cancellable: bool) -> void:
	close()  # um menu por vez
	_clear()
	_title.text = title
	_body.text = body
	_body.visible = body != ""
	_cancellable = cancellable
	_panel.custom_minimum_size.x = 460.0
	_center.show()
	_dim.show()
	is_open = true
	EventBus.ui_blocking = true
	EventBus.interaction_prompt.emit("")
	Sfx.play(&"ui_open")
	UiFx.quiet()


func _close() -> void:
	is_open = false
	EventBus.ui_blocking = false
	# Os botões ficam na tela só durante a animação de saída, sem responder.
	for c in _content.get_children():
		if c is BaseButton:
			c.disabled = true
			c.release_focus()
	_animate_out()


## Entrada: painel cresce com um leve "pulo", o fundo escurece e as opções
## deslizam uma após a outra.
func _animate_in() -> void:
	if _anim:
		_anim.kill()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.85, 0.85)
	_dim.modulate.a = 0.0
	_anim = create_tween().set_parallel()
	_anim.tween_property(_dim, "modulate:a", 1.0, 0.2)
	_anim.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_anim.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var i := 0
	for c in _content.get_children():
		if c is Control:
			c.modulate.a = 0.0
			_anim.tween_property(c, "modulate:a", 1.0, 0.18).set_delay(0.06 + i * 0.04)
			i += 1


func _animate_out() -> void:
	if _anim:
		_anim.kill()
	_anim = create_tween().set_parallel()
	_anim.tween_property(_dim, "modulate:a", 0.0, 0.15)
	_anim.tween_property(_panel, "modulate:a", 0.0, 0.14)
	_anim.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.14).set_trans(Tween.TRANS_SINE)
	_anim.chain().tween_callback(func() -> void:
		_center.hide()
		_dim.hide()
		_clear())


func _clear() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()


## Chamado depois que as opções foram criadas: anima a entrada e foca a primeira.
func _focus_first() -> void:
	_animate_in()
	for c in _content.get_children():
		if c is BaseButton and not c.disabled:
			c.grab_focus()
			return
