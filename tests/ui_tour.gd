extends Node
## Prints da interface: HUD, menu animando, transições de mapa e cinemática.
## Uso: Godot --path . res://tests/ui_tour.tscn -- <pasta de saída>


func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else OS.get_user_data_dir()
	Engine.set_meta(&"skip_cinematic", true)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	TimeManager.running = false
	await _frames(40)
	Economy.money += 25
	await _frames(14)
	_shot(out, "hud")
	Inventory.add(Inventory.BACKPACK, &"semente_alface", 3)
	Inventory.add(Inventory.BACKPACK, &"npk", 2)
	Inventory.add(Inventory.TRUCK, &"tomate", 9)
	Inventory.add(Inventory.TRUCK, &"mandioca", 4)
	PlayerStats.hunger = 12.0
	Economy.water_charges = 5
	await _frames(40)
	_shot(out, "bars")
	var house := SceneRouter.current_map
	house._on_phone()
	await _frames(5)
	house._on_phone()
	await _frames(5)
	main.menu.close()
	await _frames(30)
	house._on_fridge()
	await _frames(50)
	_shot(out, "fridge")
	main.menu.close()
	await _frames(30)
	house._shop("Sementes", Catalog.CROPS.map(func(c: CropData) -> StringName: return c.seed_id()))
	await _frames(50)
	_shot(out, "shop")
	main.menu.close()
	await _frames(30)
	main.show_inventory()
	await _frames(40)
	_shot(out, "inventory")
	main.inventory_ui._on_tab(1)
	await _frames(30)
	_shot(out, "inventory_truck")
	main.inventory_ui.close()
	await _frames(30)
	SceneRouter.go_to(&"backyard", &"FromHouse", 0)
	await _frames(12)
	_shot(out, "iris")
	await _frames(60)
	SceneRouter.go_to(&"market", &"FromTruck", 0)
	await _frames(12)
	_shot(out, "pixels")
	await _frames(60)
	SceneRouter.load_now(&"house", &"FromStart")
	await _frames(3)
	main._show_title()
	await _frames(50)
	_shot(out, "title")
	main.menu.close()
	await _frames(3)
	main.pause()
	await _frames(50)
	_shot(out, "pause")
	main.menu.close()
	await _frames(30)
	Cinematic.play(self, Cinematic.INTRO, SceneRouter.current_map.get_node("CameraRig"))
	await _frames(60)
	_shot(out, "cine_1")
	await _frames(240)
	_shot(out, "cine_2")
	await _frames(420)
	_shot(out, "cine_title")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_%s.png" % name))
