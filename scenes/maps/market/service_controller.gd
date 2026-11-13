extends Node
## Fila da barraca do jogador e o Atendimento.
## Cada cliente chega com um HUMOR (Raiva < Triste < Normal < Feliz).
##   Conversar  — 1× por cliente: 45% melhora, 45% piora, 10% fica igual.
##   Desconto   — humor melhora, paga menos, ganha um pouco de energia. Fecha a venda.
##   Vender     — só fecha a venda.
##   Sobrepreço — humor piora, paga mais, gasta energia. Fecha a venda.

const QUEUE_MAX := 4
const QUEUE_SPACING := 1.1
const TALK_MINUTES := 2
const SALE_MINUTES := 3

const TALK_BETTER := 0.45
const TALK_WORSE := 0.45  ## O que sobra (10%) mantém o humor.

const DISCOUNT_PRICE := -0.15
const DISCOUNT_ENERGY := 2.0  ## Ganho baixo.
const MARKUP_PRICE := 0.30
const MARKUP_ENERGY := 5.0  ## Perda moderada.

signal queue_changed

@export var service_point_path: NodePath

var queue: Array[Customer] = []
## Sorteio de 0 a 1 da conversa (trocado nos testes).
var roll: Callable = func() -> float: return randf()
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
	queue_changed.emit()


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
	while is_instance_valid(c) and not TimeManager.night_pending:
		if Inventory.count(Inventory.STALL, c.wants) == 0 and not _pick_want(c):
			EventBus.toast.emit("A barraca ficou sem produto!")
			_finish(c, true)
			break
		var qty := mini(c.wants_qty, Inventory.count(Inventory.STALL, c.wants))
		var base := Economy.sell_price(c.wants) * qty
		var keys: Array[StringName] = []
		var labels: Array = []
		if not c.talked:
			keys.append(&"conversar")
			labels.append("Conversar  (o humor pode melhorar ou piorar)")
		keys.append(&"desconto")
		labels.append("Desconto: R$ %d  (humor melhora, +%d energia)" % [_price(base, DISCOUNT_PRICE), int(DISCOUNT_ENERGY)])
		keys.append(&"vender")
		labels.append("Vender: R$ %d" % _price(base, 0.0))
		var body := "Cliente quer %d× %s.\nHumor: %s" % [qty, Catalog.item_name(c.wants).to_lower(), c.mood_text()]
		# Cliente com Raiva não aceita pagar a mais: a opção some do menu.
		if c.mood == Customer.Mood.RAIVA:
			body += "\nCom raiva, ele não aceita sobrepreço."
		else:
			keys.append(&"sobrepreco")
			labels.append("Sobrepreço: R$ %d  (humor piora, −%d energia)" % [_price(base, MARKUP_PRICE), int(MARKUP_ENERGY)])

		var pick := await MenuLayer.current.choose("Atender", body, labels)
		if not is_instance_valid(c):
			break
		if pick < 0:
			c.being_served = false
			break
		match keys[pick]:
			&"conversar":
				_talk(c)
				TimeManager.advance(TALK_MINUTES)
				continue
			&"desconto":
				c.shift_mood(1)
				PlayerStats.gain_energy(DISCOUNT_ENERGY)
				_sell(c, qty, _price(base, DISCOUNT_PRICE))
			&"vender":
				_sell(c, qty, _price(base, 0.0))
			&"sobrepreco":
				c.shift_mood(-1)
				PlayerStats.spend_energy(MARKUP_ENERGY)
				_sell(c, qty, _price(base, MARKUP_PRICE))
		break
	_serving = false


static func _price(base: int, change: float) -> int:
	return maxi(1, roundi(base * (1.0 + change)))


## Conversa fiada: uma vez por cliente, e pode sair pela culatra.
func _talk(c: Customer) -> void:
	c.talked = true
	Sfx.play(&"talk")
	var r: float = roll.call()
	if r < TALK_BETTER:
		c.shift_mood(1)
		EventBus.toast.emit("A conversa animou o cliente!")
	elif r < TALK_BETTER + TALK_WORSE:
		c.shift_mood(-1)
		EventBus.toast.emit("A conversa azedou o humor do cliente...")
	else:
		EventBus.toast.emit("Conversa vai, conversa vem... nada mudou.")


func _sell(c: Customer, qty: int, price: int) -> void:
	Inventory.remove(Inventory.STALL, c.wants, qty)
	var happy := c.mood == Customer.Mood.FELIZ
	Economy.record_sale(price, qty, happy)
	EventBus.toast.emit("+R$ %d%s" % [price, "  (cliente feliz!)" if happy else ""])
	if happy:
		Sfx.play(&"happy", -3.0)
	elif c.mood == Customer.Mood.RAIVA:
		Sfx.play(&"angry", -3.0)
	_finish(c, false)
	TimeManager.advance(SALE_MINUTES)


func _finish(c: Customer, lost: bool) -> void:
	queue.erase(c)
	if lost:
		Economy.record_lost_customer()
	c.leave()
	_reflow()
	queue_changed.emit()


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
		queue_changed.emit()


func _spot(i: int) -> Vector3:
	return _service_point.global_position + Vector3(i * QUEUE_SPACING, 0.0, 0.0)


func _reflow() -> void:
	for i in queue.size():
		queue[i].move_in_queue(_spot(i))
