extends Control
## HUD: relógio, dinheiro, fome, energia, buffs, recursos do dia,
## prompt de interação e avisos (toasts).

var _clock: Label
var _money: Label
var _hunger: ProgressBar
var _energy: ProgressBar
var _status: Label
var _prompt: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.06, 0.12, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	_clock = _label(vb, 22, Color(1.0, 0.85, 0.4))
	_money = _label(vb, 18, Color(0.55, 1.0, 0.55))
	_hunger = _bar(vb, "Fome", Color(1.0, 0.6, 0.2))
	_energy = _bar(vb, "Energia", Color(0.35, 0.8, 1.0))
	_status = _label(vb, 14, Color(0.85, 0.85, 0.9))

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -64
	_prompt.offset_bottom = -32
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	add_child(_prompt)

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	_toast.offset_top = 24
	_toast.offset_bottom = 60
	_toast.offset_left = -360
	_toast.offset_right = 360
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.modulate.a = 0.0
	add_child(_toast)

	EventBus.interaction_prompt.connect(func(t: String) -> void: _prompt.text = ("[E] " + t) if t != "" else "")
	EventBus.toast.connect(_show_toast)
	PlayerStats.hunger_changed.connect(func(v: float) -> void: _hunger.value = v)
	PlayerStats.energy_changed.connect(_on_energy)
	_on_energy(PlayerStats.energy, PlayerStats.max_energy)
	_hunger.value = PlayerStats.hunger


func _process(_delta: float) -> void:
	_clock.text = "Dia %d  ·  %s" % [TimeManager.day, TimeManager.clock_text()]
	_money.text = "R$ %d" % Economy.money
	var parts: PackedStringArray = []
	for b: StringName in PlayerStats.buffs:
		parts.append("★ " + PlayerStats.BUFF_NAMES.get(b, String(b)))
	parts.append("Gasolina: %d viagens  ·  Água: %d regas" % [Economy.fuel_trips, Economy.water_charges])
	if Economy.risk > 0:
		parts.append("⚠ Contas atrasadas! Mais uma noite assim = falência")
	_status.text = "\n".join(parts)


func _on_energy(value: float, max_value: float) -> void:
	_energy.max_value = max_value
	_energy.value = value


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _label(parent: Node, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _bar(parent: Node, title: String, color: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size.x = 72
	row.add_child(l)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(170, 16)
	bar.show_percentage = false
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	return bar
