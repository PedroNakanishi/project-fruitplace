class_name Catalog
extends RefCounted
## Acesso estático a todos os dados editáveis em res://data.

const CROPS: Array = [
	preload("res://data/crops/tomate.tres"),
	preload("res://data/crops/alface.tres"),
	preload("res://data/crops/mandioca.tres"),
]

const FERTILIZERS: Array = [
	preload("res://data/fertilizers/esterco.tres"),
	preload("res://data/fertilizers/npk.tres"),
]

const FOODS: Array = [
	preload("res://data/foods/lanche.tres"),
	preload("res://data/foods/prato_feito.tres"),
	preload("res://data/foods/feijoada.tres"),
]

const CUSTOMERS: Array = [
	preload("res://data/customers/vaidoso.tres"),
	preload("res://data/customers/pao_duro.tres"),
	preload("res://data/customers/apressado.tres"),
]


static func crop(id: StringName) -> CropData:
	for c: CropData in CROPS:
		if c.id == id:
			return c
	return null


static func crop_for_seed(seed: StringName) -> CropData:
	for c: CropData in CROPS:
		if c.seed_id() == seed:
			return c
	return null


static func fertilizer(id: StringName) -> FertilizerData:
	for f: FertilizerData in FERTILIZERS:
		if f.id == id:
			return f
	return null


static func is_produce(id: StringName) -> bool:
	return crop(id) != null


static func item_name(id: StringName) -> String:
	var c := crop(id)
	if c:
		return c.display_name
	c = crop_for_seed(id)
	if c:
		return "Semente de " + c.display_name.to_lower()
	var f := fertilizer(id)
	if f:
		return f.display_name
	return String(id)


static func food(id: StringName) -> FoodData:
	for f: FoodData in FOODS:
		if f.id == id:
			return f
	return null


## Tipo do item, para ordenar e rotular no inventário.
static func kind(id: StringName) -> String:
	if crop(id):
		return "Produto"
	if crop_for_seed(id):
		return "Semente"
	if fertilizer(id):
		return "Adubo"
	if food(id):
		return "Comida"
	return "Item"


static func icon(id: StringName) -> Texture2D:
	return ItemIcons.get_icon(id)


## Descrição curta, montada a partir dos dados do item.
static func description(id: StringName) -> String:
	var c := crop(id)
	if c:
		return "%s. Rende %d por planta." % [c.category.capitalize(), c.base_yield]
	c = crop_for_seed(id)
	if c:
		return "Cresce em %dh." % (c.grow_minutes / 60)
	var f := fertilizer(id)
	if f:
		var bonus := "+%d unidade na colheita" % f.yield_bonus if f.yield_bonus > 0 else "%d%% mais rápido" % int(f.growth_bonus * 100.0)
		return "%s · %s" % [f.rarity, bonus]
	var fd := food(id)
	if fd:
		return "+%d de fome · %d min" % [int(fd.hunger_restore), fd.minutes_to_eat]
	return ""


## Preço de referência (compra da semente/adubo, venda do produto); -1 se não tem.
static func price(id: StringName) -> int:
	var c := crop(id)
	if c:
		return c.base_sell_price
	c = crop_for_seed(id)
	if c:
		return c.seed_price
	var f := fertilizer(id)
	if f:
		return f.price
	return -1
