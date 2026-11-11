class_name Customer
extends Node3D
## Cliente da feira: anda pela rua, pode parar na barraca, espera na fila
## com paciência limitada e vai embora feliz ou irritado.

signal reached_stall(customer: Customer)
signal gave_up(customer: Customer)

enum State { WALKING, TO_QUEUE, WAITING, LEAVING }

const SPEED := 2.2

var profile: CustomerProfile
var state := State.WALKING
var mood := 0.5
var patience := 30.0
var being_served := false
var wants_stop := false
var wants: StringName
var wants_qty := 1

var _target := Vector3.ZERO
var _exit := Vector3.ZERO
var _checked_stall := false

@onready var body: MeshInstance3D = $Body
@onready var label: Label3D = $Mood


## Chamar antes de adicionar à árvore.
func setup(p: CustomerProfile, from: Vector3, stall_x: float, exit: Vector3, stop: bool) -> void:
	profile = p
	mood = p.start_mood
	patience = p.patience_seconds
	position = from
	_exit = exit
	wants_stop = stop
	_target = Vector3(stall_x, from.y, from.z) if stop else exit


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = profile.color
	body.material_override = m
	label.text = ""


func _process(delta: float) -> void:
	if TimeManager.night_pending:
		return
	var to := _target - position
	to.y = 0.0
	if to.length() > 0.05:
		position += to.normalized() * minf(SPEED * delta, to.length())
		body.rotation.y = atan2(to.x, to.z)
	else:
		_arrived()
	if (state == State.TO_QUEUE or state == State.WAITING) and not being_served:
		patience -= delta
		label.text = "..." if patience < 8.0 else ""
		if patience <= 0.0:
			gave_up.emit(self)
			leave(false)


func go_to_queue(spot: Vector3) -> void:
	state = State.TO_QUEUE
	_target = spot


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


func _arrived() -> void:
	match state:
		State.WALKING:
			if wants_stop and not _checked_stall:
				_checked_stall = true
				reached_stall.emit(self)
				if state == State.WALKING:
					_target = _exit
			else:
				queue_free()
		State.TO_QUEUE:
			state = State.WAITING
		State.LEAVING:
			queue_free()
