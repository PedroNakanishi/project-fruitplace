class_name AmbientWalker
extends Node3D
## Pedestre de enfeite: anda por uma lista de pontos, para em alguns deles
## para "olhar a vitrine" e some no fim. Não interage com a feira.

const HUMANOID := preload("res://scenes/characters/humanoid.tscn")
const SHIRTS := [
	Color(0.92, 0.35, 0.3), Color(0.3, 0.6, 0.85), Color(0.95, 0.8, 0.3), Color(0.4, 0.75, 0.5),
	Color(0.85, 0.5, 0.75), Color(0.95, 0.95, 0.9), Color(0.5, 0.4, 0.75), Color(0.95, 0.6, 0.25),
]

var speed := 1.5
var _path: Array[Vector3] = []
var _pauses: Array[float] = []
var _i := 0
var _wait := 0.0
var _body: Humanoid


## `pauses[i]` = segundos parado ao chegar no ponto i (0 = não para).
func setup(path: Array[Vector3], pauses: Array[float], walk_speed: float, kid := false) -> void:
	_path = path
	_pauses = pauses
	speed = walk_speed
	position = path[0]
	_i = 1
	_body = HUMANOID.instantiate()
	add_child(_body)
	_body.randomize_look(SHIRTS.pick_random())
	if kid:
		_body.scale = Vector3.ONE * 0.78
		_body.hat = false
		_body.apply_look()
	_body.rotation.y = atan2(path[1].x - path[0].x, path[1].z - path[0].z)


func _process(delta: float) -> void:
	if TimeManager.night_pending:
		_body.walking = false
		return
	if _wait > 0.0:
		_wait -= delta
		_body.walking = false
		return
	var to := _path[_i] - position
	to.y = 0.0
	if to.length() > 0.08:
		_body.walking = true
		position += to.normalized() * minf(speed * delta, to.length())
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(to.x, to.z), minf(1.0, delta * 9.0))
		return
	_wait = _pauses[_i]
	if _wait > 0.0 and _i + 1 < _path.size():
		# vira para olhar para o lado da vitrine antes de seguir
		_body.rotation.y = atan2(_path[_i + 1].x - _path[_i].x, _path[_i + 1].z - _path[_i].z)
	_i += 1
	if _i >= _path.size():
		queue_free()
