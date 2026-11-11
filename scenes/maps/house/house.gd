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
		return
	var rested := PlayerStats.is_rested_for_sleep()
	var body := "Dormir agora encerra o dia e abre as contas."
	body += "\nVocê vai acordar com o buff Bem descansado." if rested else "\nEnergia baixa: sem bônus de descanso."
	if await MenuLayer.current.choose("Cama", body, ["Dormir", "Ainda não"]) == 0:
		EventBus.sleep_requested.emit()


func _on_fridge() -> void:
	if not Economy.fridge_stocked:
		EventBus.toast.emit("Geladeira vazia! Pague a conta de Comida à noite.")
		return
	var options: Array = []
	for f: FoodData in Catalog.FOODS:
		options.append("%s  (+%d fome, %d min)" % [f.display_name, int(f.hunger_restore), f.minutes_to_eat])
	options.append("Fechar")
	var body := "Fome: %d/100" % int(PlayerStats.hunger)
	var i := await MenuLayer.current.choose("Geladeira", body, options)
	if i < 0 or i >= Catalog.FOODS.size():
		return
	var food: FoodData = Catalog.FOODS[i]
	PlayerStats.eat(food)
	EventBus.toast.emit("Comeu " + food.display_name.to_lower() + ".")
	TimeManager.advance(food.minutes_to_eat)


func _on_phone() -> void:
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
			options.append("%s (%s) — R$ %d · cresce em %dh · tem %d" % [c.display_name, c.category, c.seed_price, c.grow_minutes / 60, Inventory.count(Inventory.BACKPACK, c.seed_id())])
		options.append("Voltar")
		var i := await MenuLayer.current.choose("Sementes", "Saldo: R$ %d · cada clique compra 1" % Economy.money, options)
		if i < 0 or i >= Catalog.CROPS.size():
			return
		var crop: CropData = Catalog.CROPS[i]
		if Economy.spend(crop.seed_price):
			Inventory.add(Inventory.BACKPACK, crop.seed_id(), 1)
		else:
			EventBus.toast.emit("Dinheiro insuficiente.")


func _shop_fertilizers() -> void:
	while not TimeManager.night_pending:
		var options: Array = []
		for f: FertilizerData in Catalog.FERTILIZERS:
			var bonus := "+%d unidade" % f.yield_bonus if f.yield_bonus > 0 else "%d%% mais rápido" % int(f.growth_bonus * 100.0)
			options.append("%s (%s) — R$ %d · %s · tem %d" % [f.display_name, f.rarity, f.price, bonus, Inventory.count(Inventory.BACKPACK, f.id)])
		options.append("Voltar")
		var i := await MenuLayer.current.choose("Adubos", "Saldo: R$ %d · cada clique compra 1" % Economy.money, options)
		if i < 0 or i >= Catalog.FERTILIZERS.size():
			return
		var fert: FertilizerData = Catalog.FERTILIZERS[i]
		if Economy.spend(fert.price):
			Inventory.add(Inventory.BACKPACK, fert.id, 1)
		else:
			EventBus.toast.emit("Dinheiro insuficiente.")
