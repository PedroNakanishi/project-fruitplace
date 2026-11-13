extends Node3D
## Mapa 1 — Casa: cama, geladeira, telefone e porta para o Quintal.

const PHONE_MINUTES := 3

@onready var bed: Interactable = $Interactables/Bed
@onready var fridge: Interactable = $Interactables/Fridge
@onready var phone: Interactable = $Interactables/Phone
@onready var door: Interactable = $Interactables/DoorToBackyard


func _ready() -> void:
	bed.interacted.connect(_on_bed)
	fridge.interacted.connect(_on_fridge)
	phone.interacted.connect(_on_phone)
	door.interacted.connect(func() -> void: SceneRouter.go_to(&"backyard", &"FromHouse", 5))


func _on_bed() -> void:
	if not TimeManager.can_sleep():
		EventBus.toast.emit("Ainda não. Só dá para dormir depois das 19:30.")
		Sfx.play(&"error")
		return
	var rested := PlayerStats.is_rested_for_sleep()
	var body := "Dormir agora encerra o dia e abre as contas."
	body += "\nVocê vai acordar com o buff Bem descansado." if rested else "\nEnergia baixa: sem bônus de descanso."
	if await MenuLayer.current.choose("Cama", body, ["Dormir", "Ainda não"]) == 0:
		EventBus.sleep_requested.emit()


func _on_fridge() -> void:
	if not Economy.fridge_stocked:
		EventBus.toast.emit("Geladeira vazia! Pague a conta de Comida à noite.")
		Sfx.play(&"error")
		return
	var options: Array = []
	for f: FoodData in Catalog.FOODS:
		options.append({"name": f.display_name, "icon": Catalog.icon(f.id), "desc": Catalog.description(f.id)})
	var body := "Fome: %d/100" % int(PlayerStats.hunger)
	var i := await MenuLayer.current.choose_items("Geladeira", body, options, "Fechar")
	if i < 0 or i >= Catalog.FOODS.size():
		return
	var food: FoodData = Catalog.FOODS[i]
	PlayerStats.eat(food)
	Sfx.play(&"eat")
	EventBus.toast.emit("Comeu " + food.display_name.to_lower() + ".")
	TimeManager.advance(food.minutes_to_eat)


func _on_phone() -> void:
	Sfx.play(&"phone")
	TimeManager.advance(PHONE_MINUTES)
	while not TimeManager.night_pending:
		var tab := await MenuLayer.current.choose("Telefone", "Saldo: R$ %d" % Economy.money, ["Sementes", "Adubos", "Desligar"])
		match tab:
			0:
				await _shop_seeds()
			1:
				await _shop_fertilizers()
			_:
				return


func _shop_seeds() -> void:
	while not TimeManager.night_pending:
		var options: Array = []
		for c: CropData in Catalog.CROPS:
			var sid := c.seed_id()
			options.append({"name": Catalog.item_name(sid), "icon": Catalog.icon(sid), "desc": Catalog.description(sid),
				"price": c.seed_price, "note": "Você tem %d" % Inventory.count(Inventory.BACKPACK, sid)})
		var i := await MenuLayer.current.choose_items("Sementes", "Saldo: R$ %d · cada clique compra 1" % Economy.money, options)
		if i < 0 or i >= Catalog.CROPS.size():
			return
		var crop: CropData = Catalog.CROPS[i]
		if Economy.spend(crop.seed_price):
			Inventory.add(Inventory.BACKPACK, crop.seed_id(), 1)
			Sfx.play(&"buy")
		else:
			EventBus.toast.emit("Dinheiro insuficiente.")
			Sfx.play(&"error")


func _shop_fertilizers() -> void:
	while not TimeManager.night_pending:
		var options: Array = []
		for f: FertilizerData in Catalog.FERTILIZERS:
			options.append({"name": f.display_name, "icon": Catalog.icon(f.id), "desc": Catalog.description(f.id),
				"price": f.price, "note": "Você tem %d" % Inventory.count(Inventory.BACKPACK, f.id)})
		var i := await MenuLayer.current.choose_items("Adubos", "Saldo: R$ %d · cada clique compra 1" % Economy.money, options)
		if i < 0 or i >= Catalog.FERTILIZERS.size():
			return
		var fert: FertilizerData = Catalog.FERTILIZERS[i]
		if Economy.spend(fert.price):
			Inventory.add(Inventory.BACKPACK, fert.id, 1)
			Sfx.play(&"buy")
		else:
			EventBus.toast.emit("Dinheiro insuficiente.")
			Sfx.play(&"error")
