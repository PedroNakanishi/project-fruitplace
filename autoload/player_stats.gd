extends Node
## Fome, energia e buffs do jogador.

signal energy_changed(value: float, max_value: float)
signal hunger_changed(value: float)
signal buffs_changed(buffs: Array[StringName])
signal player_fainted

const BASE_MAX_ENERGY := 100.0
const FAINT_MAX_ENERGY := 80.0  ## Penalidade do dia seguinte ao desmaio.
const ENERGY_DRAIN_PER_MIN := 0.05
const HUNGER_DRAIN_PER_MIN := 0.08
const RESTED_THRESHOLD := 0.10  ## Dormir acima de 10% dá "Bem descansada".
const BUFF_RESTED := &"bem_descansada"

const BUFF_NAMES := {BUFF_RESTED: "Bem descansada"}

var max_energy := BASE_MAX_ENERGY
var energy := BASE_MAX_ENERGY
var hunger := 80.0
var buffs: Array[StringName] = []
var _fainted := false


func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute)


func reset() -> void:
	max_energy = BASE_MAX_ENERGY
	energy = max_energy
	hunger = 80.0
	buffs.clear()
	_fainted = false
	_emit_all()


func _on_minute(_m: int) -> void:
	_set_hunger(hunger - HUNGER_DRAIN_PER_MIN)
	spend_energy(ENERGY_DRAIN_PER_MIN * drain_multiplier())


## Fome saciada reduz o dreno; fome baixa dobra; o buff de descanso reduz.
func drain_multiplier() -> float:
	var m := 1.0
	if hunger > 50.0:
		m *= 0.8
	elif hunger < 20.0:
		m *= 2.0
	if has_buff(BUFF_RESTED):
		m *= 0.85
	return m


func spend_energy(amount: float) -> void:
	energy = clampf(energy - amount, 0.0, max_energy)
	energy_changed.emit(energy, max_energy)
	if energy <= 0.0 and not _fainted:
		_fainted = true
		player_fainted.emit()


func gain_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, max_energy)
	energy_changed.emit(energy, max_energy)


func eat(food: FoodData) -> void:
	_set_hunger(hunger + food.hunger_restore)


func has_buff(buff: StringName) -> bool:
	return buffs.has(buff)


func is_rested_for_sleep() -> bool:
	return energy > max_energy * RESTED_THRESHOLD


func start_day(fainted: bool, rested: bool) -> void:
	max_energy = FAINT_MAX_ENERGY if fainted else BASE_MAX_ENERGY
	energy = max_energy
	buffs.clear()
	if rested:
		buffs.append(BUFF_RESTED)
	_fainted = false
	hunger = maxf(hunger - 15.0, 0.0)  # a noite sem comer
	_emit_all()


func _set_hunger(value: float) -> void:
	hunger = clampf(value, 0.0, 100.0)
	hunger_changed.emit(hunger)


func _emit_all() -> void:
	energy_changed.emit(energy, max_energy)
	hunger_changed.emit(hunger)
	buffs_changed.emit(buffs)
