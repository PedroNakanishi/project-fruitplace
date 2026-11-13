class_name Cinematic
extends CanvasLayer
## Cinemática sobre o próprio jogo: barras de cinema, câmera que se afasta,
## legendas com efeito de máquina de escrever, vinheta/grão (shader) e título.
## Qualquer tecla de ação ou clique pula. Uso:
##     await Cinematic.play(self, Cinematic.INTRO, rig)

signal finished

const VIGNETTE := preload("res://assets/shaders/vignette.gdshader")
const BAR_HEIGHT := 70.0

## Roteiro da abertura (textos provisórios: edite à vontade).
## Cada cena: legenda e segundos que ela fica na tela depois de digitada.
const INTRO := {
	"shots": [
		{"text": "Uma casinha simples, um quintal e uma barraca na feira.", "hold": 1.6},
		{"text": "Plante. Colha. Venda.", "hold": 1.3},
		{"text": "Mas as contas não esperam ninguém.", "hold": 1.6},
	],
	"title": "FruitPlace",
	"subtitle": "A feira te espera",
}

var _timeline: Tween
var _cam_tween: Tween
var _done := false
var _was_running := true
var _rig: Node3D
var _cam_end := {}

var _black: ColorRect
var _vignette: ColorRect
var _top: ColorRect
var _bottom: ColorRect
var _caption: Label
var _title: Label
var _subtitle: Label
var _hint: Label
var _last_chars := 0


## Roda a cinemática e só volta quando ela termina (ou é pulada).
static func play(host: Node, script: Dictionary, rig: Node3D = null) -> void:
	var c := Cinematic.new()
	host.add_child(c)
	c.start(script, rig)
	await c.finished


func start(script: Dictionary, rig: Node3D) -> void:
	layer = 40
	_rig = rig
	EventBus.cinematic_active = true
	EventBus.interaction_prompt.emit("")
	_was_running = TimeManager.running
	TimeManager.running = false
	_build()
	_start_camera()

	var tw := create_tween()
	_timeline = tw
	tw.tween_callback(Sfx.play.bind(&"cine_sting", 0.0, 0.0))
	tw.tween_property(_black, "modulate:a", 0.0, 1.4)
	tw.parallel().tween_property(_top, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_bottom, "position:y", _screen().y - BAR_HEIGHT, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.4)
	for shot: Dictionary in script["shots"]:
		_queue_caption(tw, shot["text"], shot["hold"])
	tw.tween_callback(_show_title.bind(script["title"], script["subtitle"]))
	tw.tween_interval(3.0)
	tw.tween_callback(finish)


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var size := _screen()

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE
	_vignette.material = mat
	root.add_child(_vignette)

	_top = _bar(root, Vector2(0, -BAR_HEIGHT), size.x)
	_bottom = _bar(root, Vector2(0, size.y), size.x)

	_caption = Label.new()
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption.offset_left = -420
	_caption.offset_right = 420
	_caption.offset_bottom = -BAR_HEIGHT - 28
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 26)
	_caption.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 8)
	_caption.visible_ratio = 0.0
	root.add_child(_caption)

	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 84)
	_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
	_title.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.05))
	_title.add_theme_constant_override("outline_size", 16)
	_title.modulate.a = 0.0
	root.add_child(_title)

	_subtitle = Label.new()
	_subtitle.set_anchors_preset(Control.PRESET_FULL_RECT)
	_subtitle.offset_top = 80
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 24)
	_subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	_subtitle.add_theme_constant_override("outline_size", 6)
	_subtitle.modulate.a = 0.0
	root.add_child(_subtitle)

	_hint = Label.new()
	_hint.text = "[E] Pular"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -140
	_hint.offset_top = -40
	_hint.offset_right = -16
	_hint.offset_bottom = -14
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.modulate.a = 0.7
	root.add_child(_hint)

	_black = ColorRect.new()
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_black)


func _bar(parent: Control, pos: Vector2, width: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.position = pos
	r.size = Vector2(width, BAR_HEIGHT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


## Digita a legenda, segura, e apaga.
func _queue_caption(tw: Tween, text: String, hold: float) -> void:
	tw.tween_callback(func() -> void:
		_caption.text = text
		_caption.visible_characters = 0
		_caption.modulate.a = 1.0
		_last_chars = 0)
	tw.tween_method(_type, 0.0, float(text.length()), text.length() * 0.035)
	tw.tween_interval(hold)
	tw.tween_property(_caption, "modulate:a", 0.0, 0.4)
	tw.tween_interval(0.2)


func _type(chars: float) -> void:
	var n := int(chars)
	_caption.visible_characters = n
	if n != _last_chars and n % 2 == 0:
		Sfx.play(&"type", -6.0, 0.1)
	_last_chars = n


func _show_title(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_title.pivot_offset = _screen() / 2.0
	_title.scale = Vector2(1.25, 1.25)
	Sfx.play(&"new_day")
	var tw := create_tween().set_parallel()
	tw.tween_property(_title, "modulate:a", 1.0, 0.8)
	tw.tween_property(_title, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_subtitle, "modulate:a", 1.0, 0.8).set_delay(0.8)


# --- câmera ------------------------------------------------------------------

## A câmera começa fechada e girada e se afasta até o enquadramento do jogo.
func _start_camera() -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	var cam: Camera3D = _rig.get_node("Camera3D")
	_cam_end = {"size": cam.size, "yaw": _rig.rotation_degrees.y}
	cam.size = _cam_end["size"] * 0.5
	_rig.rotation_degrees.y = _cam_end["yaw"] - 35.0
	var secs := 1.4
	for shot: Dictionary in INTRO["shots"]:
		secs += shot["text"].length() * 0.035 + shot["hold"] + 0.6
	_cam_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(cam, "size", _cam_end["size"], secs)
	_cam_tween.tween_property(_rig, "rotation_degrees:y", _cam_end["yaw"], secs)


func _restore_camera() -> void:
	if _cam_tween:
		_cam_tween.kill()
	if _rig == null or not is_instance_valid(_rig) or _cam_end.is_empty():
		return
	var cam: Camera3D = _rig.get_node("Camera3D")
	cam.size = _cam_end["size"]
	_rig.rotation_degrees.y = _cam_end["yaw"]


# --- fim -----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel") \
			or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		finish()


func finish() -> void:
	if _done:
		return
	_done = true
	if _timeline:
		_timeline.kill()
	_restore_camera()
	var tw := create_tween().set_parallel()
	tw.tween_property(_top, "position:y", -BAR_HEIGHT, 0.5)
	tw.tween_property(_bottom, "position:y", _screen().y, 0.5)
	for n: CanvasItem in [_caption, _title, _subtitle, _hint, _vignette]:
		tw.tween_property(n, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(_cleanup)


func _cleanup() -> void:
	EventBus.cinematic_active = false
	TimeManager.running = _was_running
	finished.emit()
	EventBus.cinematic_finished.emit()
	queue_free()
