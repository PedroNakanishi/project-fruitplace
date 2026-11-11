extends Node
## Fila da barraca do jogador e o minigame de Atender.
## Bajular, Desconto e Sobrepreço podem ser usados uma vez cada antes de Vender.

const QUEUE_MAX := 4
const QUEUE_SPACING := 1.1
const SERVICE_MINUTES := 2
const SALE_MINUTES := 3
const REFUSE_BELOW := 0.2  ## Humor abaixo disso: o cliente não compra.
const HAPPY_FROM := 0.6

const OPTIONS := {
	&"bajular": {"label": "Bajular (+10%, −2 energia)", "price": 0.10, "energy": -2.0},
	&"desconto": {"label": "Dar desconto (−15%, +2 energia)", "price": -0.15, "energy": 2.0},
	&"sobrepreco": {"label": "Sobrepreço (+30%, −5 energia)", "price": 0.30, "energy": -5.0},
}

@export var service_point_path: NodePath

var queue: Array[Customer] = []
var _service_point: Node3D
var _serving := false


func _ready() -> void:
	_service_point = get_node(service_point_path)


func can_join() -> bool:
	return queue.size() < QUEUE_MAX and Inventory.total(Inventory.STALL) > 0


func join(c: Customer) -> void:
	_pick_want(c)
	queue.append(c)
	c.gave_up.connect(_on_gave_up)
	c.go_to_queue(_spot(queue.size() - 1))


func waiting_count() -> int:
	return queue.size()


## Atende o primeiro da fila. Chamado pela barraca.
func serve() -> void:
	if _serving:
		return
	var c: Customer = queue.front() if not queue.is_empty() else null
	if c == null or c.state != Customer.State.WAITING:
		EventBus.toast.emit("Ninguém esperando na barraca agora.")
		return
	_serving = true
	c.being_served = true
	var price_mult := 1.0
	var used := {}
	while is_instance_valid(c) and not TimeManager.night_pending:
		if Inventory.count(Inventory.STALL, c.wants) == 0 and not _pick_want(c):
			EventBus.toast.emit("A barraca ficou sem produto!")
			_finish(c, false, false)
			break
		var qty := mini(c.wants_qty, Inventory.count(Inventory.STALL, c.wants))
		var price := maxi(1, roundi(Economy.sell_price(c.wants) * qty * price_mult))
		var body := "Cliente quer %d× %s.\nPreço: R$ %d\nHumor: %s" % [qty, Catalog.item_name(c.wants).to_lower(), price, c.mood_text()]
		var keys: Array = []
		var labels: Array = []
		for k: StringName in OPTIONS:
			if not used.has(k):
				keys.append(k)
				labels.append(OPTIONS[k].label)
		keys.append(&"vender")
		labels.append("Vender por R$ %d" % price)
		var pick := await MenuLayer.current.choose("Atender", body, labels)
		if pick < 0 or not is_instance_valid(c):
			if is_instance_valid(c):
				c.being_served = false
			break
		var key: StringName = keys[pick]
		if key == &"vender":
			_sell(c, qty, price)
			break
		used[key] = true
		price_mult += OPTIONS[key].price
		var energy: float = OPTIONS[key].energy
		if energy < 0.0:
			PlayerStats.spend_energy(-energy)
		else:
			PlayerStats.gain_energy(energy)
		c.mood = clampf(c.mood + _reaction(c.profile, key), 0.0, 1.0)
		TimeManager.advance(SERVICE_MINUTES)
		if c.mood <= 0.0:
			EventBus.toast.emit("O cliente foi embora bufando!")
			_finish(c, false, true)
			break
	_serving = false


func _sell(c: Customer, qty: int, price: int) -> void:
	if c.mood < REFUSE_BELOW:
		EventBus.toast.emit("O cliente se irritou e não comprou!")
		_finish(c, false, true)
	else:
		Inventory.remove(Inventory.STALL, c.wants, qty)
		var happy := c.mood >= HAPPY_FROM
		Economy.record_sale(price, qty, happy)
		EventBus.toast.emit("+R$ %d%s" % [price, "  (cliente feliz!)" if happy else ""])
		_finish(c, happy, false)
	TimeManager.advance(SALE_MINUTES)


func _finish(c: Customer, happy: bool, lost: bool) -> void:
	queue.erase(c)
	if lost:
		Economy.record_lost_customer()
	c.leave(happy)
	_reflow()


func _reaction(p: CustomerProfile, key: StringName) -> float:
	match key:
		&"bajular":
			return p.flattery_reaction
		&"desconto":
			return p.discount_reaction
		&"sobrepreco":
			return p.markup_reaction
	return 0.0


## Escolhe um produto que a barraca tem. Devolve false se está vazia.
func _pick_want(c: Customer) -> bool:
	var stock := Inventory.items(Inventory.STALL)
	if stock.is_empty():
		return false
	c.wants = stock.keys().pick_random()
	c.wants_qty = randi_range(1, 3)
	return true


func _on_gave_up(c: Customer) -> void:
	if queue.has(c):
		queue.erase(c)
		Economy.record_lost_customer()
		EventBus.toast.emit("Um cliente cansou de esperar e foi embora.")
		_reflow()


func _spot(i: int) -> Vector3:
	return _service_point.global_position + Vector3(i * QUEUE_SPACING, 0.0, 0.0)


func _reflow() -> void:
	for i in queue.size():
		queue[i].move_in_queue(_spot(i))
