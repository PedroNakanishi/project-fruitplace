extends Node
## Estado de cada lote do canteiro. Vive fora da cena do Quintal para que
## as plantas cresçam enquanto o jogador está na Feira.

signal plot_changed(index: int)
signal seed_changed(seed: StringName)

const PLOT_COUNT := 6
const WATER_SPEED_BONUS := 0.35  ## Regado: ~25% menos tempo restante.
const WATER_ENERGY_COST := 3.0
const DEFAULT_SEED := &"semente_tomate"

var plots: Array[Dictionary] = []
## Semente usada ao tocar num lote vazio. Trocada com Q.
var selected_seed: StringName = DEFAULT_SEED


func _ready() -> void:
	TimeManager.minute_passed.connect(func(_m: int) -> void: grow(1.0))
	TimeManager.day_started.connect(func(_d: int) -> void: _dry_all())
	reset()


func reset() -> void:
	selected_seed = DEFAULT_SEED
	plots.clear()
	for i in PLOT_COUNT:
		plots.append(_empty())
		plot_changed.emit(i)
	seed_changed.emit(selected_seed)


## Culturas com semente na mochila, na ordem do catálogo.
func available_seeds() -> Array[CropData]:
	var out: Array[CropData] = []
	for c: CropData in Catalog.CROPS:
		if Inventory.count(Inventory.BACKPACK, c.seed_id()) > 0:
			out.append(c)
	return out


## A semente selecionada; se acabou, a primeira disponível; ou null.
func selected_crop() -> CropData:
	var c := Catalog.crop_for_seed(selected_seed)
	if c and Inventory.count(Inventory.BACKPACK, selected_seed) > 0:
		return c
	var avail := available_seeds()
	return avail[0] if not avail.is_empty() else null


## Passa para a próxima semente disponível. Devolve a nova, ou null.
func cycle_seed() -> CropData:
	var avail := available_seeds()
	if avail.is_empty():
		return null
	var idx := -1
	for i in avail.size():
		if avail[i].seed_id() == selected_seed:
			idx = i
	var next := avail[(idx + 1) % avail.size()]
	selected_seed = next.seed_id()
	seed_changed.emit(selected_seed)
	return next


func first_fertilizer() -> FertilizerData:
	for f: FertilizerData in Catalog.FERTILIZERS:
		if Inventory.count(Inventory.BACKPACK, f.id) > 0:
			return f
	return null


## A próxima ação de um toque no lote: &"plant", &"water", &"fertilize",
## &"harvest", ou &"wait" (nada a fazer agora).
func next_action(i: int) -> StringName:
	if is_ready(i):
		return &"harvest"
	if is_empty(i):
		return &"plant"
	if not plots[i].watered and Economy.water_charges > 0:
		return &"water"
	if not plots[i].fertilized and first_fertilizer() != null:
		return &"fertilize"
	return &"wait"


## Minutos de jogo até a colheita, com os buffs atuais.
func minutes_left(i: int) -> int:
	var c := crop_of(i)
	if c == null:
		return 0
	var p := plots[i]
	var speed: float = 1.0 + p.growth_bonus + (WATER_SPEED_BONUS if p.watered else 0.0)
	return maxi(0, ceili((c.grow_minutes - p.progress) / speed))


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
