extends Node3D
## Mapa 2 — Quintal: canteiro (plantar, regar, adubar, colher) e caminhonete.

const ACTION_MINUTES := 2
const TRAVEL_MINUTES := 30

@onready var plots: Node3D = $Garden
@onready var cargo_bed: Interactable = $Truck/CargoBed
@onready var driver_door: Interactable = $Truck/DriverDoor
@onready var door: Interactable = $Interactables/DoorToHouse


func _ready() -> void:
	for plot in plots.get_children():
		plot.plot_interacted.connect(_on_plot)
	cargo_bed.prompt = "Carregar produtos na caçamba"
	cargo_bed.interacted.connect(_on_load_truck)
	driver_door.prompt = "Dirigir até a Feira"
	driver_door.interacted.connect(_on_drive)
	door.interacted.connect(func() -> void: SceneRouter.go_to(&"house", &"FromBackyard", 5))


func _on_plot(i: int) -> void:
	if GardenState.is_ready(i):
		var crop := GardenState.crop_of(i)
		var qty := GardenState.harvest(i)
		EventBus.toast.emit("Colheu %d× %s." % [qty, crop.display_name.to_lower()])
		TimeManager.advance(ACTION_MINUTES)
	elif GardenState.is_empty(i):
		await _plant(i)
	else:
		await _tend(i)


func _plant(i: int) -> void:
	var seeds: Array = []
	var options: Array = []
	for c: CropData in Catalog.CROPS:
		var n := Inventory.count(Inventory.BACKPACK, c.seed_id())
		if n > 0:
			seeds.append(c)
			options.append("%s (%d sementes) · pronto em %dh" % [c.display_name, n, c.grow_minutes / 60])
	if seeds.is_empty():
		EventBus.toast.emit("Sem sementes. Compre pelo telefone, em casa.")
		return
	options.append("Cancelar")
	var pick := await MenuLayer.current.choose("Plantar", "", options)
	if pick < 0 or pick >= seeds.size():
		return
	if GardenState.plant(i, seeds[pick]):
		TimeManager.advance(ACTION_MINUTES)


func _tend(i: int) -> void:
	var crop := GardenState.crop_of(i)
	var p: Dictionary = GardenState.plots[i]
	var actions: Array = []
	var options: Array = []
	if not p.watered:
		actions.append(&"water")
		options.append("Regar (−%d energia, %d regas no regador)" % [int(GardenState.WATER_ENERGY_COST), Economy.water_charges])
	if not p.fertilized:
		for f: FertilizerData in Catalog.FERTILIZERS:
			var n := Inventory.count(Inventory.BACKPACK, f.id)
			if n > 0:
				actions.append(f)
				options.append("Adubar com %s (%d)" % [f.display_name, n])
	if actions.is_empty():
		EventBus.toast.emit("%s crescendo: %d%%." % [crop.display_name, int(GardenState.stage(i) * 100.0)])
		return
	options.append("Cancelar")
	var body := "%s: %d%% · %d min de jogo até colher" % [crop.display_name, int(GardenState.stage(i) * 100.0), _minutes_left(i)]
	var pick := await MenuLayer.current.choose("Canteiro", body, options)
	if pick < 0 or pick >= actions.size():
		return
	var action: Variant = actions[pick]
	var err: String = GardenState.water(i) if action is StringName else GardenState.fertilize(i, action)
	if err != "":
		EventBus.toast.emit(err)
	else:
		TimeManager.advance(ACTION_MINUTES)


func _minutes_left(i: int) -> int:
	var p: Dictionary = GardenState.plots[i]
	var speed: float = 1.0 + p.growth_bonus + (GardenState.WATER_SPEED_BONUS if p.watered else 0.0)
	return ceili((GardenState.crop_of(i).grow_minutes - p.progress) / speed)


func _on_load_truck() -> void:
	var moved := Inventory.transfer(Inventory.BACKPACK, Inventory.TRUCK, func(id: StringName) -> bool: return Catalog.is_produce(id))
	if moved > 0:
		EventBus.toast.emit("Carregou %d itens. Caçamba: %d/%d." % [moved, Inventory.total(Inventory.TRUCK), Inventory.CAPACITY[Inventory.TRUCK]])
		TimeManager.advance(ACTION_MINUTES)
	elif Inventory.space(Inventory.TRUCK) == 0:
		EventBus.toast.emit("A caçamba está cheia.")
	else:
		EventBus.toast.emit("Nada colhido na mochila para carregar.")


func _on_drive() -> void:
	var body := "Carga: %d unidades · na barraca: %d\nGasolina: %d viagens" % [
		Inventory.total(Inventory.TRUCK), Inventory.total(Inventory.STALL), Economy.fuel_trips]
	var pick := await MenuLayer.current.choose("Caminhonete", body, ["Viajar para a Feira (%d min)" % TRAVEL_MINUTES, "Cancelar"])
	if pick != 0:
		return
	if not Economy.use_trip():
		EventBus.toast.emit("Sem gasolina! Pague a conta de Gasolina à noite.")
		return
	SceneRouter.go_to(&"market", &"FromTruck", TRAVEL_MINUTES)
