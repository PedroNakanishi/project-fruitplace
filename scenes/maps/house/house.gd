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
	door.interacted.connect(func() -> void: SceneRouter.go_to(&"backyard", &"FromHouse", SceneRouter.DOOR_MINUTES))


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
				await _shop("Sementes", Catalog.CROPS.map(func(c: CropData) -> StringName: return c.seed_id()))
			1:
				await _shop("Adubos", Catalog.FERTILIZERS.map(func(f: FertilizerData) -> StringName: return f.id))
			_:
				return


## Loja do telefone: cada clique compra 1 unidade de `ids` (itens com preço no Catalog).
func _shop(title: String, ids: Array) -> void:
	while not TimeManager.night_pending:
		var options: Array = []
		for item_id: StringName in ids:
			options.append({"name": Catalog.item_name(item_id), "icon": Catalog.icon(item_id), "desc": Catalog.description(item_id),
				"price": Catalog.price(item_id), "note": "Você tem %d" % Inventory.count(Inventory.BACKPACK, item_id)})
		var i := await MenuLayer.current.choose_items(title, "Saldo: R$ %d · cada clique compra 1" % Economy.money, options)
		if i < 0 or i >= ids.size():
			return
		var bought: StringName = ids[i]
		if Economy.spend(Catalog.price(bought)):
			Inventory.add(Inventory.BACKPACK, bought, 1)
			Sfx.play(&"buy")
		else:
			EventBus.toast.emit("Dinheiro insuficiente.")
			Sfx.play(&"error")
