extends Node
## Relógio do jogo. `minutes` conta desde a meia-noite do dia atual e passa
## de 1440 depois da meia-noite (01:00 = 1500), até o desmaio às 02:55.

signal minute_passed(minutes: int)
signal hour_passed(hour: int)
signal day_started(day: int)
signal faint_time_reached

const DAY_START := 7 * 60 + 30  ## 07:30
const SLEEP_FROM := 19 * 60 + 30  ## 19:30
const FAINT_AT := 24 * 60 + 2 * 60 + 55  ## 02:55 do dia seguinte
const NIGHT_FROM := 19 * 60  ## Anoitece às 19:00...
const NIGHT_UNTIL := 5 * 60 + 30  ## ...e clareia às 05:30.

## Segundos reais por minuto de jogo (0.5 s = ~10 min reais por dia).
@export var seconds_per_minute := 0.5

var day := 1
var minutes := DAY_START
var running := true
## Verdadeiro do desmaio/sono até o novo dia começar.
var night_pending := false
var _acc := 0.0


func reset() -> void:
	day = 1
	minutes = DAY_START
	running = true
	night_pending = false
	_acc = 0.0
	day_started.emit(day)


func _process(delta: float) -> void:
	if not running or night_pending:
		return
	_acc += delta
	while _acc >= seconds_per_minute and not night_pending:
		_acc -= seconds_per_minute
		advance(1)


## Avança o relógio minuto a minuto (crescimento, fome e energia acompanham).
func advance(amount: int) -> void:
	for i in amount:
		if night_pending:
			return
		minutes += 1
		minute_passed.emit(minutes)
		if minutes % 60 == 0:
			hour_passed.emit((minutes / 60) % 24)
		if minutes >= FAINT_AT:
			faint_time_reached.emit()
			return


## Escuro lá fora (para o som ambiente).
func is_night() -> bool:
	var m := minutes % (24 * 60)
	return m >= NIGHT_FROM or m < NIGHT_UNTIL


func can_sleep() -> bool:
	return minutes >= SLEEP_FROM


## Minutos entre agora e as 07:30 do dia seguinte.
func minutes_until_morning() -> int:
	return 24 * 60 + DAY_START - minutes


func start_new_day() -> void:
	day += 1
	minutes = DAY_START
	_acc = 0.0
	night_pending = false
	running = true
	day_started.emit(day)


const WEEKDAYS := ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]


## 0 = segunda. O dia 1 é uma segunda-feira.
func weekday() -> int:
	return (day - 1) % 7


func weekday_name() -> String:
	return WEEKDAYS[weekday()]


func clock_text() -> String:
	var m := minutes % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]
