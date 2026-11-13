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
	main.menu.choose("Cama", "Dormir agora encerra o dia e abre as contas.", ["Dormir", "Ainda não"])
	await _frames(5)
	_shot(out, "menu_in")
	await _frames(40)
	_shot(out, "menu_done")
	main.menu.close()
	await _frames(40)
	main.show_inventory()
	await _frames(40)
	_shot(out, "inventory")
	main.menu.close()
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
