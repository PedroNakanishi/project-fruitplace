class_name InventoryUI
extends Control
## Tela própria do inventário (tecla I ou Tab): abas Mochila / Caminhonete /
## Barraca, grade de espaços com ícone e quantidade, painel de detalhes do
## item selecionado e barra de capacidade. Abre e fecha com animação.

const HEADER_SHADER := preload("res://assets/shaders/menu_header.gdshader")
const COLUMNS := 6
const MIN_SLOTS := 24
const SLOT_SIZE := Vector2(76, 76)
const TABS := [
	{"id": Inventory.BACKPACK, "name": "Mochila"},
	{"id": Inventory.TRUCK, "name": "Caminhonete"},
	{"id": Inventory.STALL, "name": "Barraca"},
]

var is_open := false

var _dim: ColorRect
var _panel: PanelContainer
var _tab_buttons: Array[Button] = []
var _grid: GridContainer
var _capacity: StatBar
var _empty: Label
var _detail_name: Label
var _detail_icon: TextureRect
var _detail_kind: Label
var _detail_desc: Label
var _detail_value: Label
var _detail_qty: Label
var _tab := 0
var _selected: StringName = &""
var _anim: Tween
var _opened_frame := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = UiTheme.make()
	hide()
	_build()
	Inventory.changed.connect(func(_c: StringName) -> void:
		if is_open:
			_refresh())


func _build() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_dim.color = Color(0.05, 0.02, 0.08, 0.6)
	_dim.mouse_filter = MOUSE_FILTER_STOP
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, UiTheme.ACCENT, 3, 18, 8))
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size / 2.0)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_panel.add_child(root)

	var header := ColorRect.new()
	header.custom_minimum_size = Vector2(0, 46)
	var hmat := ShaderMaterial.new()
	hmat.shader = HEADER_SHADER
	header.material = hmat
	root.add_child(header)
	var title := Label.new()
	title.text = "Inventário"
	title.set_anchors_preset(PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.12))
	title.add_theme_constant_override("outline_size", 8)
	header.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	var group := ButtonGroup.new()
	for i in TABS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		UiFx.hook(b)
		b.pressed.connect(_on_tab.bind(i))
		tabs.add_child(b)
		_tab_buttons.append(b)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	# Grade de espaços.
	var left := VBoxContainer.new()
	body.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(COLUMNS * (SLOT_SIZE.x + 6) + 8, 4 * (SLOT_SIZE.y + 6) + 4)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_grid)

	# Detalhes.
	var detail := PanelContainer.new()
	detail.custom_minimum_size = Vector2(230, 0)
	detail.add_theme_stylebox_override("panel", UiTheme.box(Color(0.1, 0.05, 0.14, 0.9), Color(0.45, 0.28, 0.5), 2, 12, 6))
	body.add_child(detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	detail.add_child(dv)
	_detail_name = _label(dv, 20, UiTheme.GOLD)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(0, 96)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dv.add_child(_detail_icon)
	_detail_kind = _label(dv, 13, Color(0.7, 0.8, 1.0))
	_detail_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_desc = _label(dv, 14, Color(0.9, 0.88, 0.95))
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.size_flags_vertical = SIZE_EXPAND_FILL
	_detail_value = _label(dv, 16, Color(0.55, 1.0, 0.55))
	_detail_qty = _label(dv, 16, Color.WHITE)

	# Rodapé: capacidade e dica.
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	root.add_child(foot)
	_label(foot, 14, Color(0.85, 0.85, 0.95)).text = "Capacidade"
	_capacity = StatBar.new()
	_capacity.bar_color = Color(0.4, 0.75, 0.95)
	_capacity.low_below = -1.0
	_capacity.size_flags_horizontal = SIZE_EXPAND_FILL
	foot.add_child(_capacity)
	var close_btn := Button.new()
	close_btn.text = "Fechar  [I]"
	UiFx.hook(close_btn)
	close_btn.pressed.connect(func() -> void:
		Sfx.play(&"ui_cancel")
		close())
	foot.add_child(close_btn)

	_empty = _label(left, 14, Color(1, 1, 1, 0.5))
	_empty.text = ""


func _label(parent: Node, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


# --- abrir / fechar ----------------------------------------------------------

func open(tab := 0) -> void:
	if is_open or MenuLayer.current.is_open:
		return
	is_open = true
	_opened_frame = Engine.get_process_frames()
	EventBus.ui_blocking = true
	EventBus.interaction_prompt.emit("")
	_tab = tab
	_selected = &""
	show()
	_refresh()
	Sfx.play(&"ui_open")
	UiFx.quiet()
	_tab_buttons[_tab].button_pressed = true
	if _anim:
		_anim.kill()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.88, 0.88)
	_dim.modulate.a = 0.0
	_anim = create_tween().set_parallel()
	_anim.tween_property(_dim, "modulate:a", 1.0, 0.2)
	_anim.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_anim.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_focus_first_slot()


func close() -> void:
	if not is_open:
		return
	is_open = false
	EventBus.ui_blocking = false
	if _anim:
		_anim.kill()
	_anim = create_tween().set_parallel()
	_anim.tween_property(_dim, "modulate:a", 0.0, 0.15)
	_anim.tween_property(_panel, "modulate:a", 0.0, 0.14)
	_anim.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.14)
	_anim.chain().tween_callback(hide)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed(&"inventory") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Sfx.play(&"ui_cancel")
		close()
	elif event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.physical_keycode - KEY_1
		if n >= 0 and n < TABS.size():
			get_viewport().set_input_as_handled()
			_tab_buttons[n].button_pressed = true
			_on_tab(n)


func _on_tab(i: int) -> void:
	if i == _tab and _grid.get_child_count() > 0:
		return
	_tab = i
	_selected = &""
	Sfx.play(&"ui_select", -3.0)
	_refresh()
	_focus_first_slot()


# --- conteúdo ------------------------------------------------------------------

func _refresh() -> void:
	var container: StringName = TABS[_tab]["id"]
	for i in TABS.size():
		var c: StringName = TABS[i]["id"]
		_tab_buttons[i].text = "%s  (%d)" % [TABS[i]["name"], Inventory.total(c)]

	var entries := Inventory.entries(container)
	if _selected == &"" and not entries.is_empty():
		_selected = entries[0]["id"]
	elif Inventory.count(container, _selected) <= 0:
		_selected = entries[0]["id"] if not entries.is_empty() else &""

	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var slots := maxi(MIN_SLOTS, int(ceil(entries.size() / float(COLUMNS))) * COLUMNS)
	for i in slots:
		_grid.add_child(_make_slot(entries[i] if i < entries.size() else {}))
	_empty.text = "Vazio por aqui." if entries.is_empty() else ""

	var cap: int = Inventory.CAPACITY[container]
	if container == Inventory.BACKPACK:
		_capacity.set_value(0.0, 1.0)
		_capacity.text = "%d itens (sem limite)" % Inventory.total(container)
	else:
		_capacity.set_value(Inventory.total(container), cap)
		_capacity.text = "%d / %d" % [Inventory.total(container), cap]
	_show_detail(_selected, container)


func _make_slot(entry: Dictionary) -> Control:
	var slot := Button.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.focus_mode = Control.FOCUS_ALL if not entry.is_empty() else Control.FOCUS_NONE
	if entry.is_empty():
		slot.disabled = true
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return slot
	UiFx.hook(slot)
	var id: StringName = entry["id"]
	var pic := TextureRect.new()
	pic.texture = Catalog.icon(id)
	pic.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		pic.set("offset_" + side, 10.0 if side in ["left", "top"] else -10.0)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(pic)
	var qty := Label.new()
	qty.text = "×%d" % entry["qty"]
	qty.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	qty.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	qty.grow_vertical = Control.GROW_DIRECTION_BEGIN
	qty.offset_right = -5
	qty.offset_bottom = -2
	qty.add_theme_font_size_override("font_size", 14)
	qty.add_theme_color_override("font_outline_color", Color.BLACK)
	qty.add_theme_constant_override("outline_size", 5)
	qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(qty)
	slot.focus_entered.connect(_select.bind(id))
	slot.mouse_entered.connect(_select.bind(id))
	if id == _selected:
		slot.set_meta(&"selected", true)
	return slot


func _select(id: StringName) -> void:
	if id == _selected:
		return
	_selected = id
	_show_detail(id, TABS[_tab]["id"])


func _show_detail(id: StringName, container: StringName) -> void:
	if id == &"":
		_detail_name.text = "—"
		_detail_icon.texture = null
		_detail_kind.text = ""
		_detail_desc.text = "Nada selecionado."
		_detail_value.text = ""
		_detail_qty.text = ""
		return
	_detail_name.text = Catalog.item_name(id)
	_detail_icon.texture = Catalog.icon(id)
	_detail_kind.text = Catalog.kind(id)
	_detail_desc.text = Catalog.description(id)
	var price := Catalog.price(id)
	var label := "Valor de venda" if Catalog.is_produce(id) else "Preço de compra"
	_detail_value.text = "%s: R$ %d" % [label, price] if price >= 0 else ""
	_detail_qty.text = "Quantidade: %d" % Inventory.count(container, id)
	var tw := _detail_icon.create_tween()
	_detail_icon.pivot_offset = _detail_icon.size / 2.0
	_detail_icon.scale = Vector2(0.8, 0.8)
	tw.tween_property(_detail_icon, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _focus_first_slot() -> void:
	await get_tree().process_frame
	for c in _grid.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			return
	_tab_buttons[_tab].grab_focus()
