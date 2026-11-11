class_name CropData
extends ItemData
## Uma cultura: a semente comprada, o tempo de crescimento e o produto colhido.
## O produto usa o próprio `id`; a semente usa `seed_id()`.

@export_enum("legume", "verdura", "tuberculo") var category: String = "legume"
@export var seed_price: int = 4
@export var base_sell_price: int = 6
## Minutos de jogo até ficar pronto, sem buffs.
@export var grow_minutes: int = 240
@export var base_yield: int = 3


func seed_id() -> StringName:
	return StringName("semente_" + String(id))
