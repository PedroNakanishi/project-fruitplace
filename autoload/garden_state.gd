extends Node
## Estado de cada lote do canteiro. Vive fora da cena do Quintal para que
## as plantas cresçam enquanto o jogador está na Feira.

signal plot_changed(index: int)

const PLOT_COUNT := 6
const WATER_SPEED_BONUS := 0.35  ## Regado: ~25% menos tempo restante.
const WATER_ENERGY_COST := 3.0

var plots: Array[Dictionary] = []


func _ready() -> void:
	TimeManager.minute_passed.connect(func(_m: int) -> void: grow(1.0))
	TimeManager.day_started.connect(func(_d: int) -> void: _dry_all())
	reset()


func reset() -> void:
	plots.clear()
	for i in PLOT_COUNT:
		plots.append(_empty())
		plot_changed.emit(i)


func _empty() -> Dictionary:
	return {"crop": &"", "progress": 0.0, "watered": false, "yield_bonus": 0, "growth_bonus": 0.0, "fertilized": false}


func grow(minutes: float) -> void:
	for i in plots.size():
		var p := plots[i]
		if p.crop == &"" or is_ready(i):
			continue
		var speed: float = 1.0 + p.growth_bonus + (WATER_SPEED_BONUS if p.watered else 0.0)
		p.progress += minutes * speed
		plot_changed.emit(i)


func crop_of(i: int) -> CropData:
	return Catalog.crop(plots[i].crop)


func is_empty(i: int) -> bool:
	return plots[i].crop == &""


## 0..1 até a colheita.
func stage(i: int) -> float:
	var c := crop_of(i)
	if c == null:
		return 0.0
	return clampf(plots[i].progress / c.grow_minutes, 0.0, 1.0)


func is_ready(i: int) -> bool:
	return not is_empty(i) and stage(i) >= 1.0


func plant(i: int, crop: CropData) -> bool:
	if not is_empty(i) or not Inventory.remove(Inventory.BACKPACK, crop.seed_id(), 1):
		return false
	plots[i] = _empty()
	plots[i].crop = crop.id
	plot_changed.emit(i)
	return true


## Devolve "" se deu certo, ou o motivo da falha.
func water(i: int) -> String:
	if is_empty(i) or is_ready(i):
		return "Nada para regar aqui."
	if plots[i].watered:
		return "Já foi regado hoje."
	if not Economy.use_water():
		return "O regador está vazio. Pague a conta de Água."
	plots[i].watered = true
	PlayerStats.spend_energy(WATER_ENERGY_COST)
	plot_changed.emit(i)
	return ""


func fertilize(i: int, fert: FertilizerData) -> String:
	if is_empty(i) or is_ready(i):
		return "Nada para adubar aqui."
	if plots[i].fertilized:
		return "Este lote já foi adubado."
	if not Inventory.remove(Inventory.BACKPACK, fert.id, 1):
		return "Você não tem " + fert.display_name + "."
	plots[i].fertilized = true
	plots[i].yield_bonus += fert.yield_bonus
	plots[i].growth_bonus += fert.growth_bonus
	plot_changed.emit(i)
	return ""


## Colhe para a mochila e libera o lote. Devolve as unidades colhidas.
func harvest(i: int) -> int:
	if not is_ready(i):
		return 0
	var c := crop_of(i)
	var qty: int = c.base_yield + plots[i].yield_bonus
	Inventory.add(Inventory.BACKPACK, c.id, qty)
	plots[i] = _empty()
	plot_changed.emit(i)
	return qty


func _dry_all() -> void:
	for i in plots.size():
		plots[i].watered = false
		plot_changed.emit(i)
