extends Node
## Raiz do jogo: segura o render pixelado e a UI, encaminha a tecla de
## interação e conduz a noite (contas, falência, novo dia).

@onready var map_slot: Node3D = %MapSlot
@onready var menu: MenuLayer = %MenuLayer

var _night_running := false


func _ready() -> void:
	SceneRouter.map_slot = map_slot
	EventBus.sleep_requested.connect(func() -> void: run_night(false))
	PlayerStats.player_fainted.connect(func() -> void: run_night(true))
	TimeManager.faint_time_reached.connect(func() -> void: run_night(true))
	SceneRouter.load_now(&"house", &"FromStart")
	EventBus.toast.emit.call_deferred("Dia 1 — o tempo não para!")
	Sfx.play(&"new_day")


# A interação fica aqui (fora do SubViewport) para que a tecla usada num
# botão de menu nunca reabra o objeto no mesmo quadro.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and not EventBus.input_locked():
		var p := SceneRouter.player()
		if p:
			p.try_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cycle_seed") and not EventBus.input_locked():
		var c := GardenState.cycle_seed()
		if c:
			EventBus.toast.emit("Semente: %s (%d)" % [c.display_name, Inventory.count(Inventory.BACKPACK, c.seed_id())])
		else:
			EventBus.toast.emit("Sem sementes na mochila.")
		get_viewport().set_input_as_handled()


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
	note += "\nDeixar 2 contas sem pagar por 2 noites seguidas leva à falência."
	if Economy.risk > 0:
		note += "\n⚠ Ontem 2 contas ficaram sem pagar!"

	Sfx.play(&"night")
	var paid: Dictionary = await menu.bills(Economy.bills_today(), Economy.money, note)
	if Economy.settle_bills(paid):
		await menu.choose("FALÊNCIA", "As dívidas chegaram. Você perdeu a barraca no dia %d." % TimeManager.day, ["Recomeçar"])
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
	_night_running = false


func restart() -> void:
	TimeManager.reset()
	PlayerStats.reset()
	Inventory.reset()
	Economy.reset()
	GardenState.reset()
	SceneRouter.load_now(&"house", &"FromStart")
	EventBus.toast.emit("Dia 1 — o tempo não para!")
