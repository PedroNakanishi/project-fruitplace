extends Node3D
## Mapa 2 — Quintal: canteiro e caminhonete.
## Cada toque num lote faz a próxima ação, sem menu:
## plantar (semente selecionada, Q troca) → regar → adubar → colher.

const ACTION_MINUTES := 1
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
	var crop := GardenState.crop_of(i)
	match GardenState.next_action(i):
		&"harvest":
			var qty := GardenState.harvest(i)
			EventBus.toast.emit("Colheu %d× %s." % [qty, crop.display_name.to_lower()])
		&"plant":
			var seed := GardenState.selected_crop()
			if seed == null:
				EventBus.toast.emit("Sem sementes. Compre pelo telefone, em casa.")
				return
			GardenState.selected_seed = seed.seed_id()
			GardenState.plant(i, seed)
		&"water":
			var err := GardenState.water(i)
			if err != "":
				EventBus.toast.emit(err)
				return
		&"fertilize":
			var err := GardenState.fertilize(i, GardenState.first_fertilizer())
			if err != "":
				EventBus.toast.emit(err)
				return
		_:
			var why := "" if GardenState.plots[i].watered else " · regador vazio"
			EventBus.toast.emit("%s: %d%%, pronto em %d min%s." % [crop.display_name, int(GardenState.stage(i) * 100.0), GardenState.minutes_left(i), why])
			return
	TimeManager.advance(ACTION_MINUTES)


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
