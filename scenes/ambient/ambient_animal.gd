class_name AmbientAnimal
extends Node3D
## Bicho de enfeite que vagueia por uma área, fora das zonas proibidas.
## Pombo e galinha bicam o chão e fogem de quem chega perto; gato fica sentado.

enum Kind { CHICKEN, PIGEON, CAT }
enum State { IDLE, WALK, FLEE }

var kind := Kind.CHICKEN
var area := Rect2()
var blocked: Array[Rect2] = []
## Posições (Node3D) de quem assusta o bicho.
var threats: Array[Node3D] = []

var _state := State.IDLE
var _timer := 0.0
var _target := Vector3.ZERO
var _fly_from := Vector3.ZERO
var _fly_t := 0.0
var _scan := 0.0
var _model: Node3D
var _body: Node3D
var _time := randf() * 10.0


func setup(k: Kind, zone: Rect2, no_go: Array[Rect2], model: Node3D) -> void:
	kind = k
	area = zone
	blocked = no_go
	_model = model
	add_child(_model)
	_body = _model.get_node_or_null("Body") as Node3D
	position = _random_point()
	rotation.y = randf() * TAU
	_timer = randf_range(0.5, 3.0)


func _random_point() -> Vector3:
	for i in 24:
		var p := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if not _is_blocked(p):
			return Vector3(p.x, 0.0, p.y)
	return Vector3(area.get_center().x, 0.0, area.get_center().y)


func _is_blocked(p: Vector2) -> bool:
	for r in blocked:
		if r.has_point(p):
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.25
		if kind != Kind.CAT and _state != State.FLEE and _scared():
			_start_flee()
	match _state:
		State.IDLE:
			_idle(delta)
		State.WALK:
			_walk(delta)
		State.FLEE:
			_flee(delta)


func _scared() -> bool:
	for t in threats:
		if is_instance_valid(t) and t.global_position.distance_squared_to(global_position) < 2.2 * 2.2:
			return true
	return false


func _idle(delta: float) -> void:
	_timer -= delta
	var peck := kind != Kind.CAT
	if peck and _model:
		_model.rotation.x = maxf(0.0, sin(_time * 9.0)) * 0.35 if fmod(_time, 3.0) < 1.6 else 0.0
	elif _model:
		var tail := _model.get_node_or_null("Tail") as Node3D
		if tail:
			tail.rotation.y = sin(_time * 2.0) * 0.5
	if _timer <= 0.0:
		_target = _random_point()
		if kind == Kind.CAT and randf() < 0.65:
			_timer = randf_range(4.0, 9.0)  # gato prefere ficar quieto
			return
		_state = State.WALK


func _walk(delta: float) -> void:
	if _model:
		_model.rotation.x = 0.0
	var speed := 0.5 if kind == Kind.CAT else 0.9
	var to := _target - position
	to.y = 0.0
	if to.length() < 0.06:
		_state = State.IDLE
		_timer = randf_range(1.0, 4.5)
		return
	position += to.normalized() * minf(speed * delta, to.length())
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), minf(1.0, delta * 8.0))
	_model.position.y = absf(sin(_time * 10.0)) * 0.015


func _start_flee() -> void:
	_state = State.FLEE
	_fly_from = position
	_fly_t = 0.0
	var away := Vector3.ZERO
	for t in threats:
		if is_instance_valid(t):
			away += position - t.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(randf() - 0.5, 0, randf() - 0.5)
	var dest := position + away.normalized() * randf_range(3.0, 5.0)
	var p := Vector2(clampf(dest.x, area.position.x, area.end.x), clampf(dest.z, area.position.y, area.end.y))
	_target = Vector3(p.x, 0.0, p.y) if not _is_blocked(p) else _random_point()
	var d := _target - position
	rotation.y = atan2(d.x, d.z)


func _flee(delta: float) -> void:
	_fly_t += delta / (0.9 if kind == Kind.PIGEON else 0.6)
	var t := minf(_fly_t, 1.0)
	position = _fly_from.lerp(_target, t)
	var arc := 1.4 if kind == Kind.PIGEON else 0.35
	position.y = sin(t * PI) * arc
	_flap(true)
	if t >= 1.0:
		position.y = 0.0
		_flap(false)
		_state = State.IDLE
		_timer = randf_range(1.5, 4.0)


func _flap(on: bool) -> void:
	if _body == null:
		return
	var a := sin(_time * 40.0) * 0.9 if on else 0.0
	var l := _body.get_node_or_null("WingL") as Node3D
	var r := _body.get_node_or_null("WingR") as Node3D
	if l:
		l.rotation.z = -a
	if r:
		r.rotation.z = a
