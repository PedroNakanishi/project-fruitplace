extends Node3D
## Mapa 3 — Feira da Vila: abastecer a barraca, clientes e fim do dia.

const CUSTOMER_SCENE := preload("res://scenes/npc/customer.tscn")
const TRAVEL_MINUTES := 30
const STOCK_MINUTES := 3
const OPEN_FROM := 7 * 60
const OPEN_UNTIL := 22 * 60
const STREET_HALF := 16.0
const STOP_CHANCE := 0.6

@onready var cargo_bed: Interactable = $Truck/CargoBed
@onready var driver_door: Interactable = $Truck/DriverDoor
@onready var stall: Interactable = $Stalls/PlayerStall/ServiceArea
@onready var stock_label: Label3D = $Stalls/PlayerStall/StockLabel
@onready var customers: Node3D = $Customers
@onready var spawner: Timer = $CustomerSpawner
@onready var service: Node = $ServiceController
@onready var stall_x: float = $Stalls/PlayerStall/ServicePoint.global_position.x


func _ready() -> void:
	Economy.work_day_open = true
	cargo_bed.prompt = "Abastecer a barraca"
	cargo_bed.interacted.connect(_on_stock)
	driver_door.prompt = "Caminhonete: encerrar ou voltar"
	driver_door.interacted.connect(_on_driver_door)
	stall.interacted.connect(service.serve)
	spawner.timeout.connect(_on_spawn)
	Inventory.changed.connect(func(_c: StringName) -> void: _refresh_stock())
	_refresh_stock()
	_on_spawn()


func _process(_delta: float) -> void:
	var n: int = service.waiting_count()
	stall.prompt = "Atender cliente (%d na fila)" % n if n > 0 else "Barraca (ninguém na fila)"


func _on_spawn() -> void:
	spawner.start(randf_range(3.0, 7.0))
	var t := TimeManager.minutes % (24 * 60)
	if TimeManager.night_pending or t < OPEN_FROM or t > OPEN_UNTIL:
		return
	var from_left := randf() < 0.5
	var lane_z := randf_range(1.0, 2.6)
	var start := Vector3(-STREET_HALF if from_left else STREET_HALF, 0.0, lane_z)
	var exit := Vector3(STREET_HALF if from_left else -STREET_HALF, 0.0, lane_z)
	var stop := Inventory.total(Inventory.STALL) > 0 and randf() < STOP_CHANCE
	var c: Customer = CUSTOMER_SCENE.instantiate()
	c.setup(Catalog.CUSTOMERS.pick_random(), start, stall_x, exit, stop)
	c.reached_stall.connect(_on_reached_stall)
	customers.add_child(c)


func _on_reached_stall(c: Customer) -> void:
	if service.can_join():
		service.join(c)


func _on_stock() -> void:
	var moved := Inventory.transfer(Inventory.TRUCK, Inventory.STALL)
	if moved > 0:
		EventBus.toast.emit("Abasteceu %d itens na barraca." % moved)
		TimeManager.advance(STOCK_MINUTES)
	elif Inventory.total(Inventory.TRUCK) == 0:
		EventBus.toast.emit("A caçamba está vazia.")
	else:
		EventBus.toast.emit("A barraca está cheia.")


func _on_driver_door() -> void:
	var pick := await MenuLayer.current.choose("Caminhonete", "", ["Encerrar o dia", "Voltar para casa (o dia segue)", "Fechar"])
	match pick:
		0:
			await _end_work_day()
		1:
			SceneRouter.go_to(&"backyard", &"FromTruck", TRAVEL_MINUTES)


func _end_work_day() -> void:
	var body := "Vendas: R$ %d\nUnidades vendidas: %d\nClientes felizes: %d\nClientes perdidos: %d" % [
		Economy.sales_today, Economy.units_today, Economy.happy_today, Economy.angry_today]
	await MenuLayer.current.choose("Resumo do dia", body, ["Guardar a barraca e voltar para casa"])
	if TimeManager.night_pending:
		return
	Inventory.transfer(Inventory.STALL, Inventory.TRUCK)
	Economy.work_day_open = false
	SceneRouter.go_to(&"backyard", &"FromTruck", TRAVEL_MINUTES)


func _refresh_stock() -> void:
	var parts: PackedStringArray = []
	var stock := Inventory.items(Inventory.STALL)
	for id: StringName in stock:
		parts.append("%s %d · R$ %d" % [Catalog.item_name(id), stock[id], Economy.sell_price(id)])
	stock_label.text = "\n".join(parts) if not parts.is_empty() else "Barraca vazia"
