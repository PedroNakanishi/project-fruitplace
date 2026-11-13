extends Control
## HUD: relógio dia/noite, dinheiro, fome, energia, buffs, recursos, semente
## selecionada, marcador sobre o objeto interativo em foco, prompt de interação
## com tecla e avisos (toasts) empilhados. Tudo animado.

const PANEL_BG := Color(0.1, 0.06, 0.12, 0.82)
const MONEY_GREEN := Color(0.55, 1.0, 0.55)

var _card: PanelContainer
var _clock: Label
var _day: Label
var _money: Label
var _money_shown := 0.0
var _money_target := 0
var _money_tween: Tween
var _hunger: StatBar
var _energy: StatBar
var _fuel: StatBar
var _water: StatBar
var _status: VBoxContainer
var _status_text := ""
var _seed_panel: PanelContainer
var _seed_label: Label
var _seed_key := ""
var _prompt_box: PanelContainer
var _prompt_label: Label
var _prompt_tween: Tween
var _toasts: VBoxContainer
var _marker: Control
var _focus: Node3D


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = UiTheme.make()

	_build_status_card()
	_build_seed_panel()
	_build_prompt()
	_build_marker()

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	_toasts.offset_top = 20
	_toasts.offset_left = -300
	_toasts.offset_right = 300
	_toasts.mouse_filter = MOUSE_FILTER_IGNORE
	_toasts.add_theme_constant_override("separation", 6)
	add_child(_toasts)

	var hint := Label.new()
	hint.text = "[%s] Inventário    [%s] Trocar semente" % [EventBus.key_label(&"inventory"), EventBus.key_label(&"cycle_seed")]
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	hint.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	hint.offset_left = -280
	hint.offset_top = -30
	hint.offset_right = -12
	hint.offset_bottom = -8
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)

	EventBus.interaction_prompt.connect(_on_prompt)
	EventBus.interaction_focus.connect(func(t: Node3D) -> void: _focus = t)
	EventBus.toast.connect(_show_toast)
	PlayerStats.hunger_changed.connect(_on_hunger)
	PlayerStats.energy_changed.connect(_on_energy)
	_on_energy(PlayerStats.energy, PlayerStats.max_energy)
	_on_hunger(PlayerStats.hunger)
	_money_target = Economy.money
	_money_shown = float(Economy.money)

	# Os textos só são refeitos quando o dado muda.
	TimeManager.minute_passed.connect(func(_m: int) -> void:
		_refresh_clock()
		_refresh_status())
	TimeManager.day_started.connect(func(_d: int) -> void:
		_refresh_clock()
		_refresh_status())
	Economy.money_changed.connect(_on_money)
	Economy.risk_changed.connect(func(_r: int) -> void: _refresh_status())
	Economy.resources_changed.connect(_refresh_resources)
	PlayerStats.buffs_changed.connect(func(_b: Array[StringName]) -> void: _refresh_status())
	GardenState.seed_changed.connect(func(_s: StringName) -> void: _refresh_seed())
	Inventory.changed.connect(func(_c: StringName) -> void: _refresh_seed())
	_refresh_clock()
	_refresh_status()
	_refresh_seed()
	_refresh_resources()

	# Entrada do HUD: os cartões deslizam da esquerda.
	_slide_in.call_deferred(_card, Vector2(-40, 0))
	_slide_in.call_deferred(_seed_panel, Vector2(-40, 0), 0.1)


# --- construção -------------------------------------------------------------

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.box(PANEL_BG, Color(0, 0, 0, 0), 0, 12, 8))
	return panel


func _build_status_card() -> void:
	_card = _panel()
	_card.position = Vector2(12, 12)
	add_child(_card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	_card.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	vb.add_child(top)
	top.add_child(DayDial.new())
	var times := VBoxContainer.new()
	times.add_theme_constant_override("separation", -2)
	top.add_child(times)
	_clock = UiTheme.label(times, 24, UiTheme.GOLD)
	_day = UiTheme.label(times, 13, Color(0.85, 0.85, 0.95))

	_money = UiTheme.label(vb, 20, MONEY_GREEN)
	_money.pivot_offset = Vector2(0, 12)
	_hunger = _bar(vb, "Fome", Color(1.0, 0.6, 0.2))
	_energy = _bar(vb, "Energia", Color(0.7, 0.9, 0.25))
	_fuel = _bar(vb, "Gasolina", Color(0.95, 0.3, 0.25))
	_water = _bar(vb, "Água", Color(0.3, 0.65, 1.0))
	_status = VBoxContainer.new()
	_status.add_theme_constant_override("separation", 3)
	vb.add_child(_status)


func _build_seed_panel() -> void:
	_seed_panel = _panel()
	_seed_panel.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	_seed_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_seed_panel.offset_left = 12
	_seed_panel.offset_bottom = -12
	add_child(_seed_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_seed_panel.add_child(row)
	row.add_child(_keycap(EventBus.key_label(&"cycle_seed")))
	_seed_label = UiTheme.label(row, 16, Color(0.9, 1.0, 0.8))


func _build_prompt() -> void:
	_prompt_box = _panel()
	_prompt_box.add_theme_stylebox_override("panel", UiTheme.box(Color(0.1, 0.06, 0.12, 0.9), Color(1.0, 0.72, 0.3, 0.9), 2, 12, 20))
	_prompt_box.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
	_prompt_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_box.offset_bottom = -34
	_prompt_box.modulate.a = 0.0
	_prompt_box.hide()
	_prompt_box.resized.connect(func() -> void: _prompt_box.pivot_offset = _prompt_box.size / 2.0)
	add_child(_prompt_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_prompt_box.add_child(row)
	row.add_child(_keycap(EventBus.key_label(&"interact")))
	_prompt_label = UiTheme.label(row, 19, Color.WHITE)


func _build_marker() -> void:
	_marker = Control.new()
	_marker.mouse_filter = MOUSE_FILTER_IGNORE
	_marker.hide()
	_marker.draw.connect(_draw_marker)
	add_child(_marker)


func _draw_marker() -> void:
	_marker.draw_colored_polygon(PackedVector2Array([Vector2(-9, -9), Vector2(9, -9), Vector2(0, 5)]), Color(0, 0, 0, 0.55))
	_marker.draw_colored_polygon(PackedVector2Array([Vector2(-6, -7.5), Vector2(6, -7.5), Vector2(0, 2)]), UiTheme.GOLD)


func _keycap(text: String) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.mouse_filter = MOUSE_FILTER_IGNORE
	cap.add_theme_stylebox_override("panel", UiTheme.box(Color(0.95, 0.9, 0.8), Color(0.55, 0.4, 0.25), 2, 6, 5))
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.2, 0.1, 0.1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 14
	cap.add_child(l)
	cap.size_flags_vertical = SIZE_SHRINK_CENTER
	return cap


# --- atualização -------------------------------------------------------------

func _process(delta: float) -> void:
	# Some durante cinemáticas.
	var want := 0.0 if EventBus.cinematic_active else 1.0
	modulate.a = move_toward(modulate.a, want, delta * 3.0)
	visible = modulate.a > 0.01
	_money.text = "R$ %d" % roundi(_money_shown)
	_update_marker()


func _refresh_clock() -> void:
	_clock.text = TimeManager.clock_text()
	_day.text = "Dia %d  ·  %s" % [TimeManager.day, TimeManager.weekday_name()]


func _refresh_resources() -> void:
	_fuel.set_value(Economy.fuel_trips, Economy.TRIPS_PER_TANK)
	_fuel.text = "%d/%d viagens" % [Economy.fuel_trips, Economy.TRIPS_PER_TANK]
	_water.set_value(Economy.water_charges, Economy.WATER_CHARGES_PER_DAY)
	_water.text = "%d/%d regas" % [Economy.water_charges, Economy.WATER_CHARGES_PER_DAY]


func _refresh_status() -> void:
	var lines: Array[String] = []
	for b: StringName in PlayerStats.buffs:
		lines.append("★ " + PlayerStats.BUFF_NAMES.get(b, String(b)))
	var auction := Economy.auction_today()
	if auction >= 0 and TimeManager.minutes < auction:
		lines.append("Leilão de lojas hoje às %02d:%02d" % [auction / 60, auction % 60])
	lines.append("Contas hoje à noite: R$ %d" % Economy.bills_total())
	if Economy.risk > 0:
		lines.append("⚠ Contas atrasadas! Mais uma noite assim = falência")
	var joined := "\n".join(lines)
	if joined == _status_text:
		return
	_status_text = joined
	for c in _status.get_children():
		_status.remove_child(c)
		c.queue_free()
	for line in lines:
		var color := Color(0.85, 0.85, 0.9)
		if line.begins_with("⚠"):
			color = Color(1.0, 0.5, 0.45)
		elif line.begins_with("★"):
			color = UiTheme.GOLD
		UiTheme.label(_status, 14, color).text = line


func _refresh_seed() -> void:
	var seed := GardenState.selected_crop()
	var text := "Sem sementes"
	if seed:
		text = "%s  ×%d" % [seed.display_name, Inventory.count(Inventory.BACKPACK, seed.seed_id())]
	if text != _seed_key:
		var first := _seed_key == ""
		_seed_key = text
		_seed_label.text = text
		if not first:
			_pop(_seed_panel)


func _on_money(value: int) -> void:
	var delta := value - _money_target
	_money_target = value
	if _money_tween:
		_money_tween.kill()
	var flash := MONEY_GREEN if delta > 0 else Color(1.0, 0.45, 0.4)
	_money_tween = create_tween().set_parallel()
	_money_tween.tween_property(self, "_money_shown", float(value), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_money_tween.tween_method(func(v: float) -> void:
		_money.add_theme_color_override("font_color", flash.lightened(0.5).lerp(MONEY_GREEN, v)), 0.0, 1.0, 0.6)
	_pop(_money)
	_float_text(("+R$ %d" if delta > 0 else "-R$ %d") % absi(delta), flash)


func _float_text(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.position = Vector2(170, 94)
	add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", 64.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


func _on_energy(value: float, max_value: float) -> void:
	_energy.set_value(value, max_value)
	_energy.text = "%d/%d" % [roundi(value), roundi(max_value)]


func _on_hunger(value: float) -> void:
	_hunger.set_value(value, 100.0)
	_hunger.text = "%d/100" % roundi(value)


# --- prompt, marcador e avisos -------------------------------------------------

func _on_prompt(text: String) -> void:
	if _prompt_tween:
		_prompt_tween.kill()
	_prompt_tween = create_tween().set_parallel()
	if text == "":
		_focus = null
		_prompt_tween.tween_property(_prompt_box, "modulate:a", 0.0, 0.12)
		_prompt_tween.chain().tween_callback(_prompt_box.hide)
		return
	var was_hidden := not _prompt_box.visible or _prompt_box.modulate.a < 0.05
	_prompt_label.text = text
	_prompt_box.show()
	if was_hidden:
		_prompt_box.scale = Vector2(0.85, 0.85)
	_prompt_tween.tween_property(_prompt_box, "modulate:a", 1.0, 0.15)
	_prompt_tween.tween_property(_prompt_box, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Setinha que quica sobre o objeto interativo em foco.
func _update_marker() -> void:
	if _focus == null or not is_instance_valid(_focus) or not _focus.is_inside_tree():
		_marker.hide()
		return
	var vp := _focus.get_viewport()
	var cam := vp.get_camera_3d() if vp else null
	if cam == null:
		_marker.hide()
		return
	var p := cam.unproject_position(_focus.global_position + Vector3(0, 1.8, 0))
	p = p / vp.get_visible_rect().size * get_viewport_rect().size
	_marker.position = p + Vector2(0, sin(Time.get_ticks_msec() / 220.0) * 4.0)
	_marker.show()
	_marker.queue_redraw()


func _show_toast(text: String) -> void:
	var pill := _panel()
	pill.add_theme_stylebox_override("panel", UiTheme.box(Color(0.1, 0.06, 0.12, 0.88), Color(1.0, 0.72, 0.3, 0.7), 2, 10, 14))
	pill.size_flags_horizontal = SIZE_SHRINK_CENTER
	pill.modulate.a = 0.0
	var l := UiTheme.label(pill, 20, Color(1.0, 0.92, 0.6))
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toasts.add_child(pill)
	while _toasts.get_child_count() > 4:
		var old := _toasts.get_child(0)
		_toasts.remove_child(old)
		old.queue_free()
	var tw := pill.create_tween()
	tw.tween_property(pill, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.3)
	tw.tween_property(pill, "modulate:a", 0.0, 0.5)
	tw.tween_callback(pill.queue_free)


# --- utilidades ---------------------------------------------------------------

func _slide_in(node: Control, from: Vector2, delay := 0.0) -> void:
	var target := node.position
	node.position = target + from
	node.modulate.a = 0.0
	var tw := node.create_tween().set_parallel()
	tw.tween_property(node, "position", target, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, 0.3).set_delay(delay)


func _pop(node: Control) -> void:
	if node is PanelContainer:
		node.pivot_offset = node.size / 2.0
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.12, 1.12), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _bar(parent: Node, title: String, color: Color) -> StatBar:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 14)
	l.custom_minimum_size.x = 72
	row.add_child(l)
	var bar := StatBar.new()
	bar.bar_color = color
	row.add_child(bar)
	return bar
