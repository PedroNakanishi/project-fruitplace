extends Node
## Tira um print de cada mapa (precisa de janela, não roda em --headless).
## Uso: Godot --path . res://tests/screenshot_tour.tscn -- <pasta de saída>

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else OS.get_user_data_dir()
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	TimeManager.running = false
	Inventory.add(Inventory.STALL, &"tomate", 6)
	Inventory.add(Inventory.STALL, &"alface", 4)
	GardenState.plant(0, Catalog.crop(&"tomate"))
	GardenState.plots[0].watered = true
	Inventory.add(Inventory.BACKPACK, &"semente_alface", 1)
	GardenState.plant(1, Catalog.crop(&"alface"))
	GardenState.grow(400)
	GardenState.plant(2, Catalog.crop(&"tomate"))
	GardenState.grow(60)
	for map_id: StringName in [&"house", &"backyard", &"market"]:
		var spawn: StringName = {&"house": &"FromStart", &"backyard": &"FromTruck", &"market": &"FromTruck"}[map_id]
		SceneRouter.load_now(map_id, spawn)
		if map_id == &"market":
			for i in 3:
				map_ref()._on_spawn()
		for f in 90:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join("shot_%s.png" % map_id))
	get_tree().quit()


func map_ref() -> Node:
	return SceneRouter.current_map
