extends Node
## Troca o mapa dentro do MapSlot da cena Main, com fade e custo de tempo.

signal map_changed(map_id: StringName)

const MAPS := {
	&"house": "res://scenes/maps/house/house.tscn",
	&"backyard": "res://scenes/maps/backyard/backyard.tscn",
	&"market": "res://scenes/maps/market/market.tscn",
}
const FADE_SECONDS := 0.25

## Definido pela cena Main no _ready.
var map_slot: Node
var current_map: Node
var current_id: StringName
var busy := false
var _fade: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.1, 0.05, 0.12)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)


## Vai para `map_id`, coloca o jogador em SpawnPoints/<spawn> e avança o relógio.
func go_to(map_id: StringName, spawn: StringName, minutes_cost := 0) -> void:
	if busy:
		return
	busy = true
	EventBus.interaction_prompt.emit("")
	await _fade_to(1.0)
	if minutes_cost > 0:
		TimeManager.advance(minutes_cost)
	load_now(map_id, spawn)
	await _fade_to(0.0)
	busy = false


## Troca imediata, sem fade nem custo de tempo.
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


func _fade_to(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tw.finished
