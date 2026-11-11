class_name Customer
extends Node3D
## Cliente da feira. Anda pela rua e para em frente a cada barraca para
## analisar ("?"). Depois de analisar, o mapa decide: entra na fila do
## jogador, compra na barraca vizinha ou segue para a próxima.

signal evaluated(customer: Customer, stall_id: StringName)
signal gave_up(customer: Customer)

enum State { WALKING, ANALYZING, BROWSING, TO_QUEUE, WAITING, LEAVING }

const SPEED := 2.2
const ANALYZE_SECONDS := Vector2(1.4, 2.4)
const BROWSE_SECONDS := 2.5

var profile: CustomerProfile
var state := State.WALKING
var mood := 0.5
var patience := 30.0
var being_served := false
var wants: StringName
var wants_qty := 1

## Barracas no caminho, na ordem: [{"id": StringName, "x": float}]
var _stops: Array = []
var _stop_index := 0
var _window_z := 0.5  ## Distância da calçada onde para para olhar.
var _timer := 0.0
var _target := Vector3.ZERO
var _exit := Vector3.ZERO

@onready var body: MeshInstance3D = $Body
@onready var label: Label3D = $Mood


## Chamar antes de adicionar à árvore.
func setup(p: CustomerProfile, from: Vector3, stops: Array, exit: Vector3) -> void:
	profile = p
	mood = p.start_mood
	patience = p.patience_seconds
	position = from
	_exit = exit
	_stops = stops
	_window_z = randf_range(0.2, 0.8)
	_walk_to_next()


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = profile.color
	body.material_override = m
	label.text = ""


func _process(delta: float) -> void:
	if TimeManager.night_pending:
		return
	match state:
		State.ANALYZING:
			_timer -= delta
			if _timer <= 0.0:
				var stop: Dictionary = _stops[_stop_index]
				_stop_index += 1
				label.text = ""
				evaluated.emit(self, stop.id)
				if state == State.ANALYZING:  # o mapa não decidiu nada
					pass_by()
			return
		State.BROWSING:
			_timer -= delta
			if _timer <= 0.0:
				leave(true)
			return
		State.TO_QUEUE, State.WAITING:
			if not being_served:
				patience -= delta
				label.text = "..." if patience < 8.0 else ""
				if patience <= 0.0:
					gave_up.emit(self)
					leave(false)
	_move(delta)


## Não gostou: segue para a próxima barraca.
func pass_by() -> void:
	state = State.WALKING
	_walk_to_next()


## Compra numa barraca vizinha e vai embora.
func browse() -> void:
	state = State.BROWSING
	_timer = BROWSE_SECONDS
	label.text = "$"
	label.modulate = Color(1.0, 0.9, 0.4)


func go_to_queue(spot: Vector3) -> void:
	state = State.TO_QUEUE
	_target = spot
	label.text = "!"
	label.modulate = Color(1.0, 0.85, 0.3)


func move_in_queue(spot: Vector3) -> void:
	_target = spot


func leave(happy: bool) -> void:
	state = State.LEAVING
	being_served = false
	_target = _exit
	label.text = ":)" if happy else ">:("
	label.modulate = Color(0.5, 1.0, 0.5) if happy else Color(1.0, 0.35, 0.3)


func mood_text() -> String:
	if mood >= 0.6:
		return "Feliz"
	if mood >= 0.3:
		return "Neutro"
	return "Irritado"


func _walk_to_next() -> void:
	if _stop_index < _stops.size():
		_target = Vector3(_stops[_stop_index].x, 0.0, _window_z)
	else:
		_target = _exit


func _move(delta: float) -> void:
	var to := _target - position
	to.y = 0.0
	if to.length() > 0.05:
		position += to.normalized() * minf(SPEED * delta, to.length())
		body.rotation.y = atan2(to.x, to.z)
		return
	match state:
		State.WALKING:
			if _stop_index < _stops.size():
				state = State.ANALYZING
				_timer = randf_range(ANALYZE_SECONDS.x, ANALYZE_SECONDS.y)
				body.rotation.y = PI  # de frente para a barraca
				label.text = "?"
				label.modulate = Color.WHITE
			else:
				queue_free()
		State.TO_QUEUE:
			state = State.WAITING
			label.text = ""
		State.LEAVING:
			queue_free()
