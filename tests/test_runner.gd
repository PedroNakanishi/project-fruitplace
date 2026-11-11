extends Node
## Teste de ponta a ponta do vertical slice. Roda o loop de um dia inteiro
## respondendo os menus por código. Uso:
##   Godot --headless --path . res://tests/test_runner.tscn
## Sai com código 0 se tudo passou, 1 se algo falhou.

var failures := 0
var main: Node


func _ready() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	TimeManager.running = false  # o teste controla o relógio
	await _run()
	print("\nRESULTADO: %s (%d falha(s))" % ["OK" if failures == 0 else "FALHOU", failures])
	get_tree().quit(1 if failures else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


## Responde o menu aberto com a opção `i`.
func pick(i: int) -> void:
	check(MenuLayer.current.is_open, "menu aberto antes de escolher %d" % i)
	MenuLayer.current._picked.emit(i)


func wait_router() -> void:
	for f in 300:
		if not SceneRouter.busy:
			return
		await get_tree().process_frame


func map() -> Node:
	return SceneRouter.current_map


func _run() -> void:
	print("== Início")
	check(SceneRouter.current_id == &"house", "começa na Casa")
	check(TimeManager.day == 1 and TimeManager.clock_text() == "07:30", "dia 1 às 07:30")
	check(Economy.money == 150, "R$ 150 iniciais")
	check(Inventory.count(Inventory.BACKPACK, &"semente_tomate") == 6, "6 sementes de tomate")

	print("== Casa")
	map()._on_bed()
	check(not TimeManager.night_pending and not MenuLayer.current.is_open, "não dorme antes das 19:30")

	PlayerStats.hunger = 30.0
	var t0 := TimeManager.minutes
	map()._on_fridge()
	pick(1)  # prato feito
	check(PlayerStats.hunger > 72.0 and PlayerStats.hunger <= 75.0, "prato feito restaura 45 de fome")
	check(TimeManager.minutes - t0 == 20, "comer gasta 20 min")

	map()._on_phone()
	pick(0)  # Sementes
	pick(1)  # alface
	pick(3)  # Voltar
	pick(1)  # Adubos
	pick(0)  # esterco
	pick(2)  # Voltar
	pick(2)  # Desligar
	check(Economy.money == 150 - 3 - 5, "comprou alface (R$3) e esterco (R$5)")
	check(Inventory.count(Inventory.BACKPACK, &"semente_alface") == 1, "1 semente de alface na mochila")
	check(Inventory.count(Inventory.BACKPACK, &"esterco") == 1, "1 esterco na mochila")
	check(not MenuLayer.current.is_open, "telefone fechado")

	print("== Quintal")
	SceneRouter.go_to(&"backyard", &"FromHouse", 5)
	await wait_router()
	check(SceneRouter.current_id == &"backyard", "foi para o Quintal")

	map()._on_plot(0)
	pick(0)  # tomate
	check(GardenState.plots[0].crop == &"tomate", "plantou tomate no lote 0")
	check(Inventory.count(Inventory.BACKPACK, &"semente_tomate") == 5, "gastou 1 semente")

	var energy_before := PlayerStats.energy
	map()._on_plot(0)
	pick(0)  # regar
	check(GardenState.plots[0].watered, "lote regado")
	check(Economy.water_charges == Economy.WATER_CHARGES_PER_DAY - 1, "gastou 1 rega")
	check(PlayerStats.energy < energy_before - 2.5, "regar custa energia")

	map()._on_plot(0)
	pick(0)  # adubar com esterco
	check(GardenState.plots[0].fertilized and GardenState.plots[0].yield_bonus == 1, "adubado (+1 unidade)")

	GardenState.grow(240)
	check(GardenState.is_ready(0), "tomate pronto depois de crescer")
	map()._on_plot(0)
	check(Inventory.count(Inventory.BACKPACK, &"tomate") == 4, "colheu 3 + 1 do adubo")
	check(GardenState.is_empty(0), "lote liberado")

	map()._on_load_truck()
	check(Inventory.total(Inventory.TRUCK) == 4, "4 tomates na caçamba")
	check(Inventory.count(Inventory.BACKPACK, &"semente_tomate") == 5, "sementes ficaram na mochila")

	t0 = TimeManager.minutes
	map()._on_drive()
	pick(0)
	await wait_router()
	check(SceneRouter.current_id == &"market", "chegou na Feira")
	check(Economy.fuel_trips == Economy.TRIPS_PER_TANK - 1, "viagem gastou gasolina")
	check(TimeManager.minutes - t0 >= 30, "viagem levou 30 min")

	print("== Feira")
	map()._on_stock()
	check(Inventory.total(Inventory.STALL) == 4 and Inventory.total(Inventory.TRUCK) == 0, "barraca abastecida")

	var service: Node = map().get_node("ServiceController")
	var c: Customer = load("res://scenes/npc/customer.tscn").instantiate()
	c.setup(Catalog.CUSTOMERS[0], Vector3(0, 0, 2), 0.0, Vector3(16, 0, 2), true)  # vaidoso
	map().get_node("Customers").add_child(c)
	service.join(c)
	c.state = Customer.State.WAITING
	c.wants = &"tomate"
	c.wants_qty = 2
	var money_before := Economy.money
	service.serve()
	pick(0)  # bajular: vaidoso gosta
	check(c.mood > 0.7, "vaidoso ficou feliz com a bajulação")
	pick(2)  # vender (opções restantes: desconto, sobrepreço, vender)
	var expected := roundi(Economy.sell_price(&"tomate") * 2 * 1.1)
	check(Economy.money - money_before == expected, "venda de 2 tomates com +10%% = R$ %d" % expected)
	check(Inventory.count(Inventory.STALL, &"tomate") == 2, "2 tomates saíram da barraca")
	check(Economy.happy_today == 1, "cliente feliz contado")
	check(service.queue.is_empty(), "fila vazia depois da venda")

	var c2: Customer = load("res://scenes/npc/customer.tscn").instantiate()
	c2.setup(Catalog.CUSTOMERS[1], Vector3(0, 0, 2), 0.0, Vector3(16, 0, 2), true)  # pão-duro
	map().get_node("Customers").add_child(c2)
	service.join(c2)
	c2.state = Customer.State.WAITING
	service.serve()
	pick(2)  # sobrepreço: pão-duro odeia
	check(c2.mood < 0.2, "pão-duro irritado com sobrepreço")
	pick(2)  # vender → recusa
	check(Economy.angry_today == 1, "cliente perdido contado")
	check(Inventory.count(Inventory.STALL, &"tomate") == 2, "nada vendido ao cliente irritado")

	map()._on_driver_door()
	pick(0)  # encerrar o dia
	pick(0)  # resumo → voltar
	await wait_router()
	check(SceneRouter.current_id == &"backyard", "voltou para o Quintal")
	check(Inventory.total(Inventory.STALL) == 0 and Inventory.total(Inventory.TRUCK) == 2, "sobra voltou para a caçamba")
	check(not Economy.work_day_open, "dia de trabalho encerrado")

	print("== Noite: contas pagas")
	check(GardenState.plant(1, Catalog.crop(&"alface")), "plantou alface no lote 1")
	var stage_before := GardenState.stage(1)
	TimeManager.minutes = 21 * 60
	var money_night := Economy.money
	main.run_night(false)
	await get_tree().process_frame
	check(MenuLayer.current.is_open, "tela de contas abriu")
	check(await MenuLayer.current.choose("x", "", ["y"]) == -1, "outro menu não fecha a tela de contas")
	pick(0)  # confirmar (todas marcadas)
	TimeManager.running = false
	check(TimeManager.day == 2 and TimeManager.clock_text() == "07:30", "dia 2 às 07:30")
	check(Economy.money == money_night - Economy.bills_total(), "pagou R$ %d de contas" % Economy.bills_total())
	check(PlayerStats.has_buff(PlayerStats.BUFF_RESTED), "buff Bem descansada")
	check(GardenState.stage(1) > stage_before, "alface cresceu durante a noite")
	check(SceneRouter.current_id == &"house", "acorda em casa")

	print("== Noite: desmaio às 02:55 sem pagar")
	Economy.money = 0
	TimeManager.minutes = TimeManager.FAINT_AT - 1
	TimeManager.advance(1)
	await get_tree().process_frame
	check(TimeManager.night_pending and MenuLayer.current.is_open, "desmaio às 02:55 abre as contas")
	pick(0)
	TimeManager.running = false
	check(TimeManager.day == 3, "dia 3")
	check(is_equal_approx(PlayerStats.max_energy, PlayerStats.FAINT_MAX_ENERGY), "energia máxima reduzida após desmaio")
	check(Economy.risk == 1, "contador de falência em 1")
	check(not Economy.fridge_stocked and Economy.fuel_trips == 0 and Economy.water_charges == 0, "contas não pagas cortam geladeira, gasolina e água")

	print("== Falência")
	PlayerStats.spend_energy(1000.0)  # desmaio por energia
	await get_tree().process_frame
	check(MenuLayer.current.is_open, "energia zerada abre as contas")
	pick(0)
	check(MenuLayer.current.is_open and MenuLayer.current._title.text == "FALÊNCIA", "2 noites seguidas = falência")
	pick(0)  # recomeçar
	TimeManager.running = false
	check(TimeManager.day == 1 and Economy.money == Economy.START_MONEY and Economy.risk == 0, "recomeçou do dia 1")
	check(GardenState.is_empty(1) and Inventory.total(Inventory.TRUCK) == 0, "estado zerado")
	check(not MenuLayer.current.is_open, "nenhum menu sobrando")
