extends Node3D
## Caminhonete: mostra na caçamba uma quantidade de caixotes proporcional à carga.

@onready var cargo: Node3D = $Cargo


func _ready() -> void:
	Inventory.changed.connect(_on_inventory_changed)
	_refresh()


func _on_inventory_changed(container: StringName) -> void:
	if container == Inventory.TRUCK:
		_refresh()


func _refresh() -> void:
	var crates := cargo.get_child_count()
	var fill := float(Inventory.total(Inventory.TRUCK)) / Inventory.CAPACITY[Inventory.TRUCK]
	var shown := ceili(fill * crates)
	for i in crates:
		(cargo.get_child(i) as Node3D).visible = i < shown
