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


static var _crops := {}
static var _seeds := {}
static var _ferts := {}
static var _foods := {}


## Índices id -> recurso, montados uma vez.
static func _index() -> void:
	if not _crops.is_empty():
		return
	for c: CropData in CROPS:
		_crops[c.id] = c
		_seeds[c.seed_id()] = c
	for f: FertilizerData in FERTILIZERS:
		_ferts[f.id] = f
	for f: FoodData in FOODS:
		_foods[f.id] = f


static func crop(id: StringName) -> CropData:
	_index()
	return _crops.get(id)


static func crop_for_seed(seed: StringName) -> CropData:
	_index()
	return _seeds.get(seed)


static func fertilizer(id: StringName) -> FertilizerData:
	_index()
	return _ferts.get(id)


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
	_index()
	return _foods.get(id)


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
		return "Cresce em %s." % _duration(c.grow_minutes)
	var f := fertilizer(id)
	if f:
		var bonus := "+%d unidade na colheita" % f.yield_bonus if f.yield_bonus > 0 else "%d%% mais rápido" % int(f.growth_bonus * 100.0)
		return "%s · %s" % [f.rarity, bonus]
	var fd := food(id)
	if fd:
		return "+%d de fome · %d min" % [int(fd.hunger_restore), fd.minutes_to_eat]
	return ""


## 150 -> "2h30", 240 -> "4h", 45 -> "45min".
static func _duration(minutes: int) -> String:
	var h := minutes / 60
	var m := minutes % 60
	if h == 0:
		return "%dmin" % m
	return "%dh" % h if m == 0 else "%dh%02d" % [h, m]


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
