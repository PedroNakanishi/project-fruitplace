extends Node
## Três containers de itens: mochila, caçamba da caminhonete e barraca.
## Cada um é um Dictionary id -> quantidade.

signal changed(container: StringName)

const BACKPACK := &"backpack"
const TRUCK := &"truck"
const STALL := &"stall"
const CAPACITY := {BACKPACK: 999, TRUCK: 40, STALL: 24}
const STARTING_ITEMS := {&"semente_tomate": 6}

var _items := {}


func _ready() -> void:
	reset()


func reset() -> void:
	_items = {BACKPACK: {}, TRUCK: {}, STALL: {}}
	for id: StringName in STARTING_ITEMS:
		add(BACKPACK, id, STARTING_ITEMS[id])
	for c: StringName in _items:
		changed.emit(c)


func count(container: StringName, id: StringName) -> int:
	return _items[container].get(id, 0)


func total(container: StringName) -> int:
	var n := 0
	for q: int in _items[container].values():
		n += q
	return n


func items(container: StringName) -> Dictionary:
	return _items[container].duplicate()


## Itens do container como [{id, qty}], ordenados por tipo e nome (para a tela de inventário).
func entries(container: StringName) -> Array:
	var list: Array = []
	for id: StringName in _items[container]:
		list.append({"id": id, "qty": _items[container][id]})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ka := Catalog.kind(a["id"])
		var kb := Catalog.kind(b["id"])
		if ka != kb:
			return ka < kb
		return Catalog.item_name(a["id"]) < Catalog.item_name(b["id"]))
	return list


func space(container: StringName) -> int:
	return CAPACITY[container] - total(container)


## Adiciona até onde couber e devolve quantas unidades entraram.
func add(container: StringName, id: StringName, qty: int) -> int:
	var added := mini(qty, space(container))
	if added <= 0:
		return 0
	_items[container][id] = count(container, id) + added
	changed.emit(container)
	return added


func remove(container: StringName, id: StringName, qty: int) -> bool:
	var have := count(container, id)
	if have < qty:
		return false
	if have == qty:
		_items[container].erase(id)
	else:
		_items[container][id] = have - qty
	changed.emit(container)
	return true


## Move tudo que couber de um container para outro. `filter(id) -> bool`
## escolhe quais itens mover. Devolve quantas unidades foram movidas.
func transfer(from: StringName, to: StringName, filter := Callable()) -> int:
	var moved := 0
	for id: StringName in _items[from].keys():
		if filter.is_valid() and not filter.call(id):
			continue
		var qty := mini(count(from, id), space(to))
		if qty <= 0:
			break
		remove(from, id, qty)
		add(to, id, qty)
		moved += qty
	return moved


func to_dict() -> Dictionary:
	return _items.duplicate(true)


## Recarrega o que `to_dict()` devolveu (também aceita chaves em texto, vindas do JSON).
func restore(d: Dictionary) -> void:
	_items = {BACKPACK: {}, TRUCK: {}, STALL: {}}
	for container: Variant in d:
		var key := StringName(str(container))
		if not _items.has(key):
			continue
		for id: Variant in d[container]:
			_items[key][StringName(str(id))] = int(d[container][id])
	for c: StringName in _items:
		changed.emit(c)
