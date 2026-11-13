class_name AmbientMover
extends Node3D
## Anda em linha reta (carro, pássaro) e some ao passar de `limit_x`.

var velocity := Vector3.ZERO
var limit_x := 24.0
var flap := false
var bob := 0.0
var _t := randf() * 10.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	if TimeManager.night_pending:
		return
	_t += delta
	position += velocity * delta
	if bob > 0.0:
		position.y = _base_y + sin(_t * 2.2) * bob
	if flap:
		var a := sin(_t * 22.0) * 0.8
		for wing: Node3D in get_child(0).get_children():
			if wing.name == &"WingL":
				wing.rotation.z = -a
			elif wing.name == &"WingR":
				wing.rotation.z = a
	if absf(position.x) > limit_x:
		queue_free()
