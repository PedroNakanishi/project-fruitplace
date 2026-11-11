extends Node3D
## Vitrine da barraca do jogador: um caixote por produto em estoque, com
## frutas na cor do produto (até PER_CRATE por caixote).

const SLOTS_X := [-1.05, -0.35, 0.35, 1.05]
const PER_CRATE := 8

var _mesh := SphereMesh.new()
var _mats := {}


func _ready() -> void:
	_mesh.radius = 0.085
	_mesh.height = 0.17
	_mesh.radial_segments = 6
	_mesh.rings = 3
	Inventory.changed.connect(_on_inventory_changed)
	_refresh()


func _on_inventory_changed(container: StringName) -> void:
	if container == Inventory.STALL:
		_refresh()


func _refresh() -> void:
	for c in get_children():
		c.queue_free()
	var stock := Inventory.items(Inventory.STALL)
	var slot := 0
	for id: StringName in stock:
		if slot >= SLOTS_X.size():
			break
		for n in mini(stock[id], PER_CRATE):
			var fruit := MeshInstance3D.new()
			fruit.mesh = _mesh
			fruit.material_override = _material(id)
			var row := n / 4
			fruit.position = Vector3(SLOTS_X[slot] - 0.2 + (n % 4) * 0.135, 0.02 + row * 0.03, -0.09 + row * 0.17)
			add_child(fruit)
		slot += 1


func _material(id: StringName) -> StandardMaterial3D:
	if not _mats.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_color = Catalog.crop(id).color
		m.roughness = 1.0
		_mats[id] = m
	return _mats[id]
