extends Node
## Teste de ponta a ponta do vertical slice. Roda o loop de um dia inteiro
## respondendo os menus por código. Uso:
##   Godot --headless --path . res://tests/test_runner.tscn
## Sai com código 0 se tudo passou, 1 se algo falhou.

var failures := 0
var finished := false
var main: Node


func _ready() -> void:
	# O teste não mexe no save nem nas configurações reais do jogador.
	SaveGame.save_path = "user://test_save.json"
	SaveGame.settings_path = "user://test_settings.cfg"
	SaveGame.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.settings_path))
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	TimeManager.running = false  # o teste controla o relógio
	await _run()
	check(finished, "o teste chegou ao fim (sem erro de script no meio)")
	print("\nRESULTADO: %s (%d falha(s))" % ["OK" if failures == 0 else "FALHOU", failures])
	# Dá tempo de o áudio parar; senão o Godot fecha avisando de recursos em uso.
	Sfx.stop_all()
	await get_tree().create_timer(0.4).timeout
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


## Quantas opções o menu aberto está mostrando.
func option_count() -> int:
	var n := 0
	for c in MenuLayer.current._content.find_children("*", "Button", true, false):
		if not c.is_queued_for_deletion():
			n += 1
	return n


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
	# A porta da frente precisa ser sólida: antes dava para atravessar o vão e cair do mapa.
	for f in 3:
		await get_tree().physics_frame
	var player := SceneRouter.player() as CharacterBody3D
	player.global_position = Vector3(0.0, 0.05, 4.0)
	check(player.move_and_collide(Vector3(0.0, 0.0, 3.0), true) != null, "a porta da casa bloqueia a passagem")
	for x: float in [-5.0, -0.9, 0.9, 5.0]:
		player.global_position = Vector3(x, 0.05, 4.0)
		check(player.move_and_collide(Vector3(0.0, 0.0, 3.0), true) != null, "parede da frente fechada em x = %.1f" % x)
	player.global_position = Vector3(0.0, -20.0, 30.0)  # simula uma queda para fora do mapa
	player._safe_position = Vector3(0.0, 0.05, 3.6)
	player._has_safe = true
	for f in 3:
		await get_tree().physics_frame
	check(player.global_position.y > -1.0, "quem cai do mapa volta para o último chão firme")
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

	var plot0: Interactable = map().get_node("Garden/Plot0/Interactable")
	check(plot0.prompt.begins_with("Plantar tomate"), "prompt diz o próximo toque: plantar tomate")
	t0 = TimeManager.minutes
	map()._on_plot(0)
	check(not MenuLayer.current.is_open, "plantar não abre menu")
	check(GardenState.plots[0].crop == &"tomate", "plantou tomate no lote 0 com um toque")
	check(TimeManager.minutes - t0 == 1, "ação no quintal leva 1 min")
	check(Inventory.count(Inventory.BACKPACK, &"semente_tomate") == 5, "gastou 1 semente")

	check(GardenState.cycle_seed().id == &"alface", "Q troca para alface")
	map()._on_plot(1)
	check(GardenState.plots[1].crop == &"alface", "plantou alface no lote 1")
	check(GardenState.cycle_seed().id == &"tomate", "sem alface, Q volta para tomate")

	var energy_before := PlayerStats.energy
	check(plot0.prompt.begins_with("Regar"), "prompt: regar")
	map()._on_plot(0)
	check(GardenState.plots[0].watered, "lote regado com um toque")
	check(Economy.water_charges == Economy.WATER_CHARGES_PER_DAY - 1, "gastou 1 rega")
	check(PlayerStats.energy < energy_before - 2.5, "regar custa energia")

	check(plot0.prompt.begins_with("Adubar com esterco"), "prompt: adubar")
	map()._on_plot(0)
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
	var market := map()
	for n in market.get_node("Customers").get_children():
		n.free()  # o teste controla os clientes
	market.get_node("CustomerSpawner").stop()
	var rolls := [0.99, 0.0]  # recusa a vizinha, aceita a barraca do jogador
	market.roll = func() -> float: return rolls.pop_front() if not rolls.is_empty() else 0.0
	map()._on_stock()
	check(Inventory.total(Inventory.STALL) == 4 and Inventory.total(Inventory.TRUCK) == 0, "barraca abastecida")

	var service: Node = map().get_node("ServiceController")
	var c: Customer = market.spawn_customer(Catalog.CUSTOMERS[0], true)  # vaidoso, da esquerda
	var saw: Array = []
	c.evaluated.connect(func(_c: Customer, id: StringName) -> void: saw.append(id))
	for f in 1200:
		if c.state == Customer.State.WAITING:
			break
		await get_tree().physics_frame
	check(saw.size() >= 1 and saw[0] == &"west", "cliente parou para analisar a barraca vizinha primeiro")
	check(saw.has(&"player"), "cliente analisou a barraca do jogador")
	check(c.state == Customer.State.WAITING and service.queue.has(c), "depois de analisar, entrou na fila")
	check(market.player_stall_appeal(c) > 0.1, "barraca com estoque é atraente (%.2f)" % market.player_stall_appeal(c))
	var price := Economy.sell_price(&"tomate")
	var talk_rolls := [0.1, 0.5, 0.95]  # melhora, piora, fica igual
	service.roll = func() -> float: return talk_rolls.pop_front()

	print("== Atendimento: conversar + desconto")
	c.wants = &"tomate"
	c.wants_qty = 1
	c.mood = Customer.Mood.TRISTE
	var money_before := Economy.money
	var energy_before2 := PlayerStats.energy
	service.serve()
	check(option_count() == 4, "menu: conversar, desconto, vender e sobrepreço")
	pick(0)  # conversar (sorteio 0.1 = melhora)
	check(c.mood == Customer.Mood.NORMAL, "conversa melhorou o humor: Triste → Normal")
	check(option_count() == 3, "conversar só uma vez por cliente")
	pick(0)  # desconto
	var expected := roundi(price * 0.85)
	check(Economy.money - money_before == expected, "desconto: 1 tomate por R$ %d" % expected)
	check(c.mood == Customer.Mood.FELIZ and Economy.happy_today == 1, "desconto melhorou o humor: cliente feliz contado")
	check(PlayerStats.energy > energy_before2, "desconto devolve um pouco de energia")
	check(Inventory.count(Inventory.STALL, &"tomate") == 3, "1 tomate saiu da barraca")
	check(service.queue.is_empty() and c.state == Customer.State.LEAVING, "desconto encerra a venda")

	print("== Atendimento: sobrepreço")
	var c2: Customer = market.spawn_customer(Catalog.CUSTOMERS[1], true)
	market._on_customer_evaluated(c2, &"player")
	c2.state = Customer.State.WAITING
	c2.wants = &"tomate"
	c2.wants_qty = 1
	c2.mood = Customer.Mood.NORMAL
	money_before = Economy.money
	energy_before2 = PlayerStats.energy
	service.serve()
	pick(3)  # sobrepreço
	expected = roundi(price * 1.3)
	check(Economy.money - money_before == expected, "sobrepreço: 1 tomate por R$ %d" % expected)
	check(c2.mood == Customer.Mood.TRISTE, "sobrepreço piorou o humor: Normal → Triste")
	check(PlayerStats.energy <= energy_before2 - 5.0, "sobrepreço custa energia")
	check(Economy.happy_today == 1 and service.queue.is_empty(), "sobrepreço encerra a venda, sem cliente feliz")
	check(Inventory.count(Inventory.STALL, &"tomate") == 2, "2 tomates na barraca")

	print("== Atendimento: cliente com raiva")
	var c5: Customer = market.spawn_customer(Catalog.CUSTOMERS[0], true)
	market._on_customer_evaluated(c5, &"player")
	c5.state = Customer.State.WAITING
	c5.wants = &"tomate"
	c5.wants_qty = 1
	c5.mood = Customer.Mood.TRISTE
	service.serve()
	pick(0)  # conversar (sorteio 0.5 = piora)
	check(c5.mood == Customer.Mood.RAIVA, "conversa piorou o humor: Triste → Raiva")
	check(option_count() == 2, "com raiva não aceita sobrepreço: só desconto e vender")
	MenuLayer.current.close()  # Esc: desiste de atender agora
	check(not c5.being_served and service.queue.has(c5), "fechar o menu deixa o cliente na fila")
	service.serve()
	check(option_count() == 2, "voltando, a conversa continua gasta")
	MenuLayer.current.close()
	c5.mood = Customer.Mood.NORMAL
	c5.talked = false
	service.serve()
	pick(0)  # conversar (sorteio 0.95 = fica igual)
	check(c5.mood == Customer.Mood.NORMAL, "10% das conversas não mudam nada")
	MenuLayer.current.close()
	c5.patience = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(c5.mood == Customer.Mood.RAIVA and Economy.angry_today == 1, "cliente que cansa de esperar sai com raiva e conta como perdido")
	check(Inventory.count(Inventory.STALL, &"tomate") == 2, "nada vendido ao cliente que foi embora")

	var c3: Customer = market.spawn_customer(Catalog.CUSTOMERS[2], false)
	market._on_customer_evaluated(c3, &"east")
	check(c3.state == Customer.State.BROWSING, "cliente pode comprar na barraca vizinha")

	map()._on_driver_door()
	pick(1)  # voltar para casa com o dia aberto
	await wait_router()
	check(Economy.stall_away and Economy.work_day_open, "barraca fica com \"Volto logo\"")
	map()._on_drive()
	pick(0)
	await wait_router()
	market = map()
	market.get_node("CustomerSpawner").stop()
	check(market.get_node("Stalls/PlayerStall/StockLabel").text == "VOLTO LOGO", "placa Volto logo na barraca")
	var c4: Customer = market.spawn_customer(Catalog.CUSTOMERS[0], true)
	check(market.player_stall_appeal(c4) == 0.0, "ninguém compra com a placa")
	market._on_stall()
	check(not Economy.stall_away, "tocar na barraca reabre")
	check(Inventory.total(Inventory.STALL) == 2, "estoque esperou na barraca")

	map()._on_driver_door()
	pick(0)  # encerrar o dia
	pick(0)  # resumo → voltar
	await wait_router()
	check(SceneRouter.current_id == &"backyard", "voltou para o Quintal")
	check(Inventory.total(Inventory.STALL) == 0 and Inventory.total(Inventory.TRUCK) == 2, "sobra voltou para a caçamba")
	check(not Economy.work_day_open, "dia de trabalho encerrado")

	print("== Noite: contas pagas")
	check(GardenState.plant(2, Catalog.crop(&"tomate")), "plantou tomate no lote 2")
	var stage_before := GardenState.stage(2)
	TimeManager.minutes = 21 * 60
	var money_night := Economy.money
	main.run_night(false)
	await get_tree().process_frame
	check(MenuLayer.current.is_open, "tela de contas abriu")
	check(await MenuLayer.current.choose("x", "", ["y"]) == -1, "outro menu não fecha a tela de contas")
	pick(0)  # confirmar (todas marcadas)
	TimeManager.running = false
	check(TimeManager.day == 2 and TimeManager.clock_text() == "07:30", "dia 2 às 07:30")
	check(Economy.money == money_night - 70, "pagou R$ 70 de contas no dia 1")
	check(Economy.bills_total() > 70, "contas sobem no dia 2 (R$ %d)" % Economy.bills_total())
	check(TimeManager.weekday_name() == "Terça" and Economy.auction_today() == 15 * 60, "dia 2 é terça, leilão às 15:00")
	check(PlayerStats.has_buff(PlayerStats.BUFF_RESTED), "buff Bem descansado")
	check(GardenState.stage(2) > stage_before, "tomate cresceu durante a noite")
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
	check(GardenState.is_empty(2) and Inventory.total(Inventory.TRUCK) == 0, "estado zerado")
	check(not MenuLayer.current.is_open, "nenhum menu sobrando")
	check(not SaveGame.has_save(), "falência apaga o save")

	await _extras()
	SaveGame.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.settings_path))
	finished = true


## Regras que o fluxo do dia não exercita.
func _extras() -> void:
	print("== Capacidades")
	Inventory.reset()
	check(Inventory.add(Inventory.TRUCK, &"tomate", 50) == Inventory.CAPACITY[Inventory.TRUCK], "caçamba aceita só 40")
	check(Inventory.add(Inventory.TRUCK, &"alface", 1) == 0, "caçamba cheia não aceita mais nada")
	check(Inventory.add(Inventory.STALL, &"tomate", 30) == Inventory.CAPACITY[Inventory.STALL], "barraca aceita só 24")
	check(Inventory.transfer(Inventory.TRUCK, Inventory.STALL) == 0, "transferir para a barraca cheia move 0")
	Inventory.reset()

	print("== Leilão")
	var day_before := TimeManager.day
	TimeManager.day = 2
	check(Economy.auction_today() == 15 * 60, "terça tem leilão às 15:00")
	TimeManager.day = 6
	check(Economy.auction_today() == 11 * 60, "sábado tem leilão às 11:00")
	TimeManager.day = 3
	check(Economy.auction_today() == -1, "quarta não tem leilão")
	TimeManager.day = day_before

	print("== Adubo de crescimento")
	GardenState.reset()
	Inventory.reset()
	Inventory.add(Inventory.BACKPACK, &"npk", 1)
	check(GardenState.plant(0, Catalog.crop(&"tomate")), "plantou tomate")
	var slow := GardenState.minutes_left(0)
	check(GardenState.fertilize(0, Catalog.fertilizer(&"npk")) == "", "adubou com NPK")
	check(GardenState.minutes_left(0) < slow, "NPK acelera o crescimento (%d → %d min)" % [slow, GardenState.minutes_left(0)])
	check(GardenState.fertilize(0, Catalog.fertilizer(&"npk")) != "", "não adubar duas vezes")
	check(GardenState.water(0) == "" and GardenState.minutes_left(0) < slow, "regar também acelera")

	print("== Preços do dia")
	Economy.start_day(5)
	var a: float = Economy.price_multiplier[&"tomate"]
	Economy.start_day(5)
	check(is_equal_approx(a, Economy.price_multiplier[&"tomate"]), "o preço é fixo dentro do mesmo dia")
	check(absf(a - 1.0) <= Economy.PRICE_VARIANCE + 0.001, "variação dentro do limite")

	print("== Textos")
	check(Catalog.description(&"semente_alface") == "Cresce em 2h30.", "semente de alface: 2h30")
	check(Catalog.description(&"semente_tomate") == "Cresce em 4h.", "semente de tomate: 4h")
	check(EventBus.key_label(&"interact") == "E", "tecla de interação aparece como E")

	print("== Salvar e continuar")
	Economy.reset()
	Inventory.reset()
	GardenState.reset()
	TimeManager.reset()
	PlayerStats.reset()
	Economy.money = 321
	Economy.risk = 1
	Economy.fridge_stocked = false
	Inventory.add(Inventory.TRUCK, &"mandioca", 7)
	GardenState.plant(3, Catalog.crop(&"tomate"))
	GardenState.grow(60)
	TimeManager.day = 4
	PlayerStats.hunger = 42.0
	var seed_before := Economy.run_seed
	Economy.start_day(4)
	var mult_before: float = Economy.price_multiplier[&"tomate"]
	check(SaveGame.save() and SaveGame.has_save(), "salvou o jogo")
	Economy.money = 1
	Inventory.reset()
	GardenState.reset()
	TimeManager.day = 9
	PlayerStats.hunger = 5.0
	check(SaveGame.load_game(), "carregou o save")
	check(Economy.money == 321 and Economy.risk == 1 and not Economy.fridge_stocked, "economia voltou")
	check(Inventory.count(Inventory.TRUCK, &"mandioca") == 7, "inventário voltou")
	check(GardenState.plots[3].crop == &"tomate" and is_equal_approx(GardenState.plots[3].progress, 60.0), "lote voltou com o crescimento")
	check(TimeManager.day == 4 and TimeManager.clock_text() == "07:30", "dia e hora voltaram")
	check(is_equal_approx(PlayerStats.hunger, 42.0), "fome voltou")
	check(Economy.run_seed == seed_before, "semente de preços voltou")
	check(is_equal_approx(float(Economy.price_multiplier[&"tomate"]), mult_before), "preços do dia seguem o save")
	FileAccess.open(SaveGame.save_path, FileAccess.WRITE).store_string("{ isto não é json")
	check(not SaveGame.has_save() and not SaveGame.load_game(), "save corrompido é ignorado")
	SaveGame.delete()

	print("== Abertura")
	check(not SaveGame.intro_seen(), "abertura ainda não vista")
	SaveGame.mark_intro_seen()
	check(SaveGame.intro_seen(), "abertura lembrada")
