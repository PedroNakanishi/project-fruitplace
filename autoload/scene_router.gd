extends Node
## Troca o mapa dentro do MapSlot da cena Main, com fade e custo de tempo.

signal map_changed(map_id: StringName)

const MAPS := {
	&"house": "res://scenes/maps/house/house.tscn",
	&"backyard": "res://scenes/maps/backyard/backyard.tscn",
	&"market": "res://scenes/maps/market/market.tscn",
}
const SHADER := preload("res://assets/shaders/transition.gdshader")
const FADE_SECONDS := 0.35

## Estilos do shader de transição.
enum Style { IRIS, PIXELS, BLINDS, FADE }

## Definido pela cena Main no _ready.
var map_slot: Node
var current_map: Node
var current_id: StringName
var busy := false
var _fade: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("progress", 0.0)
	_fade.material = _mat
	_fade.hide()
	layer.add_child(_fade)


## Vai para `map_id`, coloca o jogador em SpawnPoints/<spawn> e avança o relógio.
func go_to(map_id: StringName, spawn: StringName, minutes_cost := 0) -> void:
	if busy:
		return
	busy = true
	EventBus.interaction_prompt.emit("")
	# Ir ou voltar da feira é de caminhonete (dissolve em blocos); o resto é
	# pela porta (íris fechando no jogador).
	var truck := map_id == &"market" or current_id == &"market"
	Sfx.play(&"engine" if truck else &"door")
	Sfx.play(&"whoosh", -8.0)
	_setup(Style.PIXELS if truck else Style.IRIS)
	await _fade_to(1.0)
	if minutes_cost > 0:
		TimeManager.advance(minutes_cost)
	load_now(map_id, spawn)
	if not truck:
		await get_tree().process_frame  # a câmera do mapa novo precisa se posicionar
		_mat.set_shader_parameter("center", _player_uv())
	await _fade_to(0.0)
	_fade.hide()
	busy = false


## Troca imediata, sem transição nem custo de tempo.
func load_now(map_id: StringName, spawn: StringName) -> void:
	if current_map:
		map_slot.remove_child(current_map)
		current_map.queue_free()
	current_map = load(MAPS[map_id]).instantiate()
	current_id = map_id
	map_slot.add_child(current_map)
	var player := current_map.get_node_or_null("Player") as Node3D
	var marker := current_map.get_node_or_null(NodePath("SpawnPoints/" + String(spawn))) as Node3D
	if player and marker:
		player.global_position = marker.global_position
	map_changed.emit(map_id)


func player() -> Node3D:
	return current_map.get_node_or_null("Player") if current_map else null


func _setup(style: Style) -> void:
	_mat.set_shader_parameter("style", int(style))
	_mat.set_shader_parameter("center", _player_uv())
	var size := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", Vector2(size.x / size.y, 1.0))
	_mat.set_shader_parameter("progress", 0.0)
	_fade.show()


## Posição do jogador na tela, de 0 a 1 (centro da íris).
func _player_uv() -> Vector2:
	var p := player()
	if p == null:
		return Vector2(0.5, 0.5)
	var vp := p.get_viewport()
	var cam := vp.get_camera_3d()
	if cam == null:
		return Vector2(0.5, 0.5)
	var pos := cam.unproject_position(p.global_position + Vector3(0, 1.0, 0))
	return (pos / vp.get_visible_rect().size).clamp(Vector2.ZERO, Vector2.ONE)


func _fade_to(value: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("progress", v), 1.0 - value, value, FADE_SECONDS)
	await tw.finished
