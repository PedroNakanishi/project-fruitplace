extends Node
## Raiz do jogo: segura o render pixelado e a UI, encaminha a tecla de
## interação e conduz a noite (contas, falência, novo dia).

@onready var map_slot: Node3D = %MapSlot
@onready var menu: MenuLayer = %MenuLayer

var inventory_ui: InventoryUI
var _night_running := false


func _ready() -> void:
	SceneRouter.map_slot = map_slot
	inventory_ui = InventoryUI.new()
	$UI.add_child(inventory_ui)
	EventBus.sleep_requested.connect(func() -> void: run_night(false))
	PlayerStats.player_fainted.connect(func() -> void: run_night(true))
	TimeManager.faint_time_reached.connect(func() -> void: run_night(true))
	SceneRouter.load_now(&"house", &"FromStart")
	if _interactive():
		TimeManager.running = false  # o relógio só corre depois do menu inicial
		_show_title.call_deferred()
	else:
		_start_message()


## Menu inicial e abertura só aparecem com janela e fora dos testes (que definem "skip_cinematic").
func _interactive() -> bool:
	return DisplayServer.get_name() != "headless" and not Engine.has_meta(&"skip_cinematic")


## Menu inicial: Continuar (se houver save), Novo jogo, Ver abertura e Sair.
func _show_title() -> void:
	TimeManager.running = false
	var rig := SceneRouter.current_map.get_node_or_null("CameraRig") as Node3D
	while true:
		var keys: Array[StringName] = []
		var labels: Array = []
		var saved := SaveGame.load_data()
		if not saved.is_empty():
			keys.append(&"continue")
			labels.append("Continuar (Dia %d)" % int(saved["day"]))
		keys.append(&"new")
		labels.append("Novo jogo")
		keys.append(&"intro")
		labels.append("Ver abertura")
		keys.append(&"quit")
		labels.append("Sair")
		var pick := await menu.choose("FruitPlace", "A feira te espera", labels)
		if pick < 0:
			continue
		match keys[pick]:
			&"continue":
				if SaveGame.load_game():
					SceneRouter.load_now(&"house", &"FromStart")
					EventBus.toast.emit("Dia %d — bem-vindo de volta!" % TimeManager.day)
					Sfx.play(&"new_day")
					return
			&"new":
				restart()
				if not SaveGame.intro_seen():
					await _play_intro(rig)
				TimeManager.running = true
				return
			&"intro":
				await _play_intro(rig)
			&"quit":
				quit_game()
				return


func _play_intro(rig: Node3D) -> void:
	await Cinematic.play(self, Cinematic.INTRO, rig)
	SaveGame.mark_intro_seen()


func quit_game() -> void:
	Sfx.stop_all()
	get_tree().quit()


## Pausa (Esc): o relógio para enquanto o menu está aberto.
func pause() -> void:
	TimeManager.running = false
	var pick := await menu.choose("Pausa", "O jogo salva sozinho toda manhã, ao acordar.", ["Continuar", "Menu inicial", "Sair do jogo"])
	match pick:
		1:
			await _show_title()
		2:
			quit_game()
			return
	TimeManager.running = true


func _start_message() -> void:
	EventBus.toast.emit("Dia 1 — o tempo não para!")
	Sfx.play(&"new_day")


# A interação fica aqui (fora do SubViewport) para que a tecla usada num
# botão de menu nunca reabra o objeto no mesmo quadro.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and not EventBus.input_locked():
		var p := SceneRouter.player()
		if p:
			p.try_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and not EventBus.input_locked() and _interactive():
		pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"inventory") and not EventBus.input_locked():
		show_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cycle_seed") and not EventBus.input_locked():
		var c := GardenState.cycle_seed()
		if c:
			EventBus.toast.emit("Semente: %s (%d)" % [c.display_name, Inventory.count(Inventory.BACKPACK, c.seed_id())])
		else:
			EventBus.toast.emit("Sem sementes na mochila.")
		get_viewport().set_input_as_handled()


## Abre a tela de inventário (tecla I ou Tab).
func show_inventory() -> void:
	inventory_ui.open()


## Fluxo noturno: disparado ao dormir na cama ou desmaiar.
func run_night(fainted: bool) -> void:
	if _night_running:
		return
	_night_running = true
	TimeManager.night_pending = true
	menu.close()
	while SceneRouter.busy:
		await get_tree().process_frame

	var rested := not fainted and PlayerStats.is_rested_for_sleep()
	var sleep_minutes := TimeManager.minutes_until_morning()
	var note := "Você desmaiou de cansaço." if fainted else "Hora de dormir."
	note += "\nDeixar %d contas sem pagar por %d noites seguidas leva à falência." % [Economy.UNPAID_LIMIT, Economy.BANKRUPT_AFTER]
	if Economy.risk > 0:
		note += "\n⚠ Ontem %d contas ficaram sem pagar!" % Economy.UNPAID_LIMIT

	Sfx.play(&"night")
	var paid: Dictionary = await menu.bills(Economy.bills_today(), Economy.money, note)
	if Economy.settle_bills(paid):
		await menu.choose("FALÊNCIA", "As dívidas chegaram. Você perdeu a barraca no dia %d." % TimeManager.day, ["Recomeçar"])
		SaveGame.delete()
		restart()
		_night_running = false
		return

	GardenState.grow(sleep_minutes)
	TimeManager.start_new_day()
	PlayerStats.start_day(fainted, rested)
	Economy.start_day(TimeManager.day)
	SceneRouter.load_now(&"house", &"FromStart")
	var msg := "Dia %d" % TimeManager.day
	if rested:
		msg += " — buff Bem descansado!"
	elif fainted:
		msg += " — energia máxima reduzida"
	EventBus.toast.emit(msg)
	SaveGame.save()
	_night_running = false


func restart() -> void:
	TimeManager.reset()
	PlayerStats.reset()
	Inventory.reset()
	Economy.reset()
	GardenState.reset()
	SceneRouter.load_now(&"house", &"FromStart")
	_start_message()
