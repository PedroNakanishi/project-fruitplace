extends Node
## Tira prints de cada mapa em horários diferentes (precisa de janela, não
## roda em --headless).
## Uso: Godot --path . res://tests/screenshot_tour.tscn -- <pasta de saída>

const SHOTS := [
	[&"house", &"FromStart", 10 * 60, "house_day"],
	[&"house", &"FromBackyard", 21 * 60, "house_night"],
	[&"backyard", &"FromTruck", 10 * 60, "backyard_day"],
	[&"backyard", &"FromHouse", 18 * 60, "backyard_sunset"],
	[&"backyard", &"FromTruck", 21 * 60, "backyard_night"],
	[&"market", &"FromTruck", 10 * 60, "market_day"],
	[&"market", &"FromTruck", 20 * 60, "market_night"],
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else OS.get_user_data_dir()
	Engine.set_meta(&"skip_cinematic", true)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	TimeManager.running = false
	Inventory.add(Inventory.STALL, &"tomate", 6)
	Inventory.add(Inventory.STALL, &"alface", 4)
	Inventory.add(Inventory.TRUCK, &"mandioca", 20)
	Inventory.add(Inventory.BACKPACK, &"semente_alface", 2)
	Inventory.add(Inventory.BACKPACK, &"semente_mandioca", 2)
	GardenState.plant(0, Catalog.crop(&"tomate"))
	GardenState.plots[0].watered = true
	GardenState.plant(1, Catalog.crop(&"alface"))
	GardenState.plant(3, Catalog.crop(&"mandioca"))
	GardenState.grow(700)
	GardenState.plant(2, Catalog.crop(&"tomate"))
	GardenState.plant(4, Catalog.crop(&"alface"))
	GardenState.plant(5, Catalog.crop(&"mandioca"))
	GardenState.grow(90)
	for shot: Array in SHOTS:
		TimeManager.minutes = shot[2]
		SceneRouter.load_now(shot[0], shot[1])
		var frames := 60
		if shot[0] == &"market":
			frames = 620
			var market := SceneRouter.current_map
			for i in 5:
				market._on_spawn()
			for mood: int in [Customer.Mood.FELIZ, Customer.Mood.RAIVA, Customer.Mood.TRISTE]:
				var c: Customer = market.spawn_customer(Catalog.CUSTOMERS.pick_random(), true)
				c.mood = mood as Customer.Mood
				market.get_node("ServiceController").join(c)
		for f in frames:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("shot_%s.png" % shot[3]))
		print("%s: %d fps" % [shot[3], Engine.get_frames_per_second()])
	get_tree().quit()
