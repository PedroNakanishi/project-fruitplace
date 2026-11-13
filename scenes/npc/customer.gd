class_name Customer
extends Node3D
## Cliente da feira. Anda pela rua e para em frente a cada barraca para
## analisar ("?"). Depois de analisar, o mapa decide: entra na fila do
## jogador, compra na barraca vizinha ou segue para a próxima.

signal evaluated(customer: Customer, stall_id: StringName)
signal gave_up(customer: Customer)

enum State { WALKING, ANALYZING, BROWSING, TO_QUEUE, WAITING, LEAVING }
## Em ordem: melhorar o humor é subir um degrau, piorar é descer.
enum Mood { RAIVA, TRISTE, NORMAL, FELIZ }

const MOOD_NAMES := {Mood.RAIVA: "Raiva", Mood.TRISTE: "Triste", Mood.NORMAL: "Normal", Mood.FELIZ: "Feliz"}
const MOOD_COLORS := {
	Mood.RAIVA: Color(1.0, 0.35, 0.3), Mood.TRISTE: Color(0.5, 0.7, 1.0),
	Mood.NORMAL: Color(0.95, 0.95, 0.9), Mood.FELIZ: Color(0.5, 1.0, 0.5),
}
const MOOD_ICONS := {
	Mood.RAIVA: preload("res://assets/textures/mood_raiva.png"), Mood.TRISTE: preload("res://assets/textures/mood_triste.png"),
	Mood.NORMAL: preload("res://assets/textures/mood_normal.png"), Mood.FELIZ: preload("res://assets/textures/mood_feliz.png"),
}
const LABEL_Y := 2.2  ## Altura do balão ("?", "!", "$") em cima da cabeça.
## Chance de cada humor quando o cliente chega na feira.
const MOOD_WEIGHTS := {Mood.NORMAL: 0.4, Mood.FELIZ: 0.25, Mood.TRISTE: 0.2, Mood.RAIVA: 0.15}

const SPEED := 2.2
const ANALYZE_SECONDS := Vector2(1.4, 2.4)
const BROWSE_SECONDS := 2.5

var profile: CustomerProfile
var state := State.WALKING
var mood: Mood = Mood.NORMAL
var patience := 30.0
var being_served := false
## Conversar só vale uma vez por cliente.
var talked := false
var wants: StringName
var wants_qty := 1

## Barracas no caminho, na ordem: [{"id": StringName, "x": float}]
var _stops: Array = []
var _stop_index := 0
var _window_z := 0.5  ## Distância da calçada onde para para olhar.
var _timer := 0.0
var _target := Vector3.ZERO
var _exit := Vector3.ZERO

@onready var body: Humanoid = $Body
@onready var label: Label3D = $Mood
@onready var mood_icon: Sprite3D = $MoodIcon


## Chamar antes de adicionar à árvore.
func setup(p: CustomerProfile, from: Vector3, stops: Array, exit: Vector3) -> void:
	profile = p
	mood = random_mood()
	patience = p.patience_seconds
	position = from
	_exit = exit
	_stops = stops
	_window_z = randf_range(0.2, 0.8)
	_walk_to_next()


func _ready() -> void:
	body.randomize_look(profile.color)
	_say("")


func _process(delta: float) -> void:
	if TimeManager.night_pending:
		return
	match state:
		State.ANALYZING:
			_timer -= delta
			if _timer <= 0.0:
				var stop: Dictionary = _stops[_stop_index]
				_stop_index += 1
				_say("")
				evaluated.emit(self, stop.id)
				if state == State.ANALYZING:  # o mapa não decidiu nada
					pass_by()
			return
		State.BROWSING:
			_timer -= delta
			if _timer <= 0.0:
				leave()
			return
		State.TO_QUEUE, State.WAITING:
			if not being_served:
				patience -= delta
				if patience <= 0.0:
					mood = Mood.RAIVA
					gave_up.emit(self)
					leave()
				elif state == State.WAITING:
					_show_mood("..." if patience < 8.0 else "")
	_move(delta)


## Não gostou: segue para a próxima barraca.
func pass_by() -> void:
	state = State.WALKING
	_walk_to_next()


## Compra numa barraca vizinha e vai embora.
func browse() -> void:
	state = State.BROWSING
	_timer = BROWSE_SECONDS
	_say("$", Color(1.0, 0.9, 0.4))


func go_to_queue(spot: Vector3) -> void:
	state = State.TO_QUEUE
	_target = spot
	_say("!", Color(1.0, 0.85, 0.3))


func move_in_queue(spot: Vector3) -> void:
	_target = spot


## Vai embora mostrando o humor com que saiu.
func leave() -> void:
	state = State.LEAVING
	being_served = false
	_target = _exit
	_show_mood()


func mood_text() -> String:
	return MOOD_NAMES[mood]


## Sobe (+) ou desce (−) degraus de humor, sem passar de Raiva/Feliz.
func shift_mood(steps: int) -> void:
	mood = clampi(mood + steps, Mood.RAIVA, Mood.FELIZ) as Mood
	_show_mood()


static func random_mood() -> Mood:
	var r := randf()
	for m: Mood in MOOD_WEIGHTS:
		r -= MOOD_WEIGHTS[m]
		if r <= 0.0:
			return m
	return Mood.NORMAL


## Mostra a carinha do humor em cima da cabeça; `extra` vai num balão acima
## dela ("..." = perdendo a paciência).
func _show_mood(extra := "") -> void:
	mood_icon.texture = MOOD_ICONS[mood]
	mood_icon.visible = true
	label.text = extra
	label.modulate = MOOD_COLORS[mood]
	label.position.y = LABEL_Y + 0.6


## Balão de texto simples, sem a carinha.
func _say(text: String, color := Color.WHITE) -> void:
	mood_icon.visible = false
	label.text = text
	label.modulate = color
	label.position.y = LABEL_Y


func _walk_to_next() -> void:
	if _stop_index < _stops.size():
		_target = Vector3(_stops[_stop_index].x, 0.0, _window_z)
	else:
		_target = _exit


func _move(delta: float) -> void:
	var to := _target - position
	to.y = 0.0
	body.walking = to.length() > 0.05
	if body.walking:
		position += to.normalized() * minf(SPEED * delta, to.length())
		body.rotation.y = atan2(to.x, to.z)
		return
	match state:
		State.WALKING:
			if _stop_index < _stops.size():
				state = State.ANALYZING
				_timer = randf_range(ANALYZE_SECONDS.x, ANALYZE_SECONDS.y)
				body.rotation.y = PI  # de frente para a barraca
				_say("?")
			else:
				queue_free()
		State.TO_QUEUE:
			state = State.WAITING
			_show_mood()
		State.LEAVING:
			queue_free()
