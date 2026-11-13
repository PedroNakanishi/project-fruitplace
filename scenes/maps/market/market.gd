extends Node3D
## Mapa 3 — Feira da Vila: abastecer a barraca, clientes que analisam as
## barracas, placa "Volto logo" e fim do dia.

const CUSTOMER_SCENE := preload("res://scenes/npc/customer.tscn")
const STOCK_MINUTES := 3
const OPEN_UNTIL := 22 * 60
const STREET_HALF := 16.0
const NEIGHBOR_BUY_CHANCE := 0.3
const PLAYER_STALL := &"player"

@onready var cargo_bed: Interactable = $Truck/CargoBed
@onready var driver_door: Interactable = $Truck/DriverDoor
@onready var stall: Interactable = $Stalls/PlayerStall/ServiceArea
@onready var stock_label: Label3D = $Stalls/PlayerStall/StockLabel
@onready var customers: Node3D = $Customers
@onready var spawner: Timer = $CustomerSpawner
@onready var service: Node = $ServiceController

## Barracas que os clientes analisam, da esquerda para a direita.
var stops: Array = []
## Sorteio de 0 a 1 usado nas decisões dos clientes (trocado nos testes).
var roll: Callable = func() -> float: return randf()


func _ready() -> void:
	stops = [
		{"id": &"west", "x": $Stalls/AuctionStalls/StallWest.global_position.x},
		{"id": PLAYER_STALL, "x": $Stalls/PlayerStall.global_position.x},
		{"id": &"east", "x": $Stalls/AuctionStalls/StallEast.global_position.x},
	]
	Economy.work_day_open = true
	cargo_bed.prompt = "Abastecer a barraca"
	cargo_bed.interacted.connect(_on_stock)
	driver_door.prompt = "Caminhonete: encerrar ou voltar"
	driver_door.interacted.connect(_on_driver_door)
	stall.interacted.connect(_on_stall)
	spawner.timeout.connect(_on_spawn)
	service.queue_changed.connect(_update_prompt)
	Inventory.changed.connect(func(_c: StringName) -> void: _refresh_stock())
	_refresh_stock()
	_update_prompt()
	_on_spawn()


## O texto do balcão muda só quando a fila ou a placa mudam.
func _update_prompt() -> void:
	if Economy.stall_away:
		stall.prompt = "Reabrir a barraca (tirar a placa \"Volto logo\")"
		return
	var n: int = service.waiting_count()
	stall.prompt = "Atender cliente (%d na fila)" % n if n > 0 else "Barraca (ninguém na fila)"


func spawn_customer(profile: CustomerProfile, from_left: bool) -> Customer:
	var lane_z := randf_range(1.4, 2.6)
	var start := Vector3(-STREET_HALF if from_left else STREET_HALF, 0.0, lane_z)
	var exit := Vector3(STREET_HALF if from_left else -STREET_HALF, 0.0, lane_z)
	var path := stops.duplicate()
	if not from_left:
		path.reverse()
	var c: Customer = CUSTOMER_SCENE.instantiate()
	c.setup(profile, start, path, exit)
	c.evaluated.connect(_on_customer_evaluated)
	customers.add_child(c)
	return c


## Chance (0..1) de um cliente entrar na fila depois de analisar a barraca.
## Variedade e preço do dia ajudam; fila longa atrapalha (o apressado em dobro).
func player_stall_appeal(c: Customer) -> float:
	var stock := Inventory.items(Inventory.STALL)
	if Economy.stall_away or stock.is_empty():
		return 0.0
	var appeal := 0.4 + 0.12 * stock.size()
	var avg_mult := 0.0
	for id: StringName in stock:
		avg_mult += Economy.price_multiplier.get(id, 1.0)
	appeal += (1.0 - avg_mult / stock.size()) * 1.5
	var queue_penalty: float = 0.1 * service.waiting_count()
	if c.profile.id == &"apressado":
		queue_penalty *= 2.0
	return clampf(appeal - queue_penalty, 0.05, 0.9)


func _on_customer_evaluated(c: Customer, stall_id: StringName) -> void:
	if stall_id == PLAYER_STALL:
		if service.can_join() and roll.call() < player_stall_appeal(c):
			service.join(c)
	elif roll.call() < NEIGHBOR_BUY_CHANCE:
		c.browse()
	# sem decisão: o cliente segue para a próxima barraca


func _on_spawn() -> void:
	spawner.start(randf_range(2.5, 5.5))
	var t := TimeManager.minutes % (24 * 60)
	if TimeManager.night_pending or t > OPEN_UNTIL:
		return
	spawn_customer(Catalog.CUSTOMERS.pick_random(), randf() < 0.5)


func _on_stall() -> void:
	if Economy.stall_away:
		Economy.stall_away = false
		_refresh_stock()
		_update_prompt()
		EventBus.toast.emit("Barraca reaberta!")
		return
	service.serve()


func _on_stock() -> void:
	var moved := Inventory.transfer(Inventory.TRUCK, Inventory.STALL)
	if moved > 0:
		EventBus.toast.emit("Abasteceu %d itens na barraca." % moved)
		Sfx.play(&"plant")
		TimeManager.advance(STOCK_MINUTES)
	elif Inventory.total(Inventory.TRUCK) == 0:
		EventBus.toast.emit("A caçamba está vazia.")
	else:
		EventBus.toast.emit("A barraca está cheia.")


func _on_driver_door() -> void:
	var pick := await MenuLayer.current.choose("Caminhonete", "", ["Encerrar o dia", "Voltar para casa (a barraca fica com \"Volto logo\")", "Fechar"])
	match pick:
		0:
			await _end_work_day()
		1:
			# Sem colaborador, a barraca não vende sozinha.
			Economy.stall_away = true
			SceneRouter.go_to(&"backyard", &"FromTruck", SceneRouter.TRUCK_TRAVEL_MINUTES)


func _end_work_day() -> void:
	var body := "Vendas: R$ %d\nUnidades vendidas: %d\nClientes felizes: %d\nClientes perdidos: %d" % [
		Economy.sales_today, Economy.units_today, Economy.happy_today, Economy.angry_today]
	await MenuLayer.current.choose("Resumo do dia", body, ["Guardar a barraca e voltar para casa"])
	if TimeManager.night_pending:
		return
	Inventory.transfer(Inventory.STALL, Inventory.TRUCK)
	Economy.work_day_open = false
	Economy.stall_away = false
	SceneRouter.go_to(&"backyard", &"FromTruck", SceneRouter.TRUCK_TRAVEL_MINUTES)


func _refresh_stock() -> void:
	if Economy.stall_away:
		stock_label.text = "VOLTO LOGO"
		stock_label.modulate = Color(1.0, 0.75, 0.3)
		return
	stock_label.modulate = Color.WHITE
	var parts: PackedStringArray = []
	var stock := Inventory.items(Inventory.STALL)
	for id: StringName in stock:
		parts.append("%s %d · R$ %d" % [Catalog.item_name(id), stock[id], Economy.sell_price(id)])
	stock_label.text = "\n".join(parts) if not parts.is_empty() else "Barraca vazia"
