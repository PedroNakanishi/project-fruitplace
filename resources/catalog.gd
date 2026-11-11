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
