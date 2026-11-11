extends Node3D
## Visual de um lote. Não guarda estado: lê tudo do GardenState.

signal plot_interacted(index: int)

@export var plot_index := 0

@onready var soil: CSGBox3D = $Soil
@onready var plant: MeshInstance3D = $Plant
@onready var fruit: MeshInstance3D = $Fruit
@onready var interactable: Interactable = $Interactable

var _soil_mat := StandardMaterial3D.new()
var _fruit_mat := StandardMaterial3D.new()


func _ready() -> void:
	soil.material = _soil_mat
	fruit.material_override = _fruit_mat
	interactable.interacted.connect(func() -> void: plot_interacted.emit(plot_index))
	GardenState.plot_changed.connect(_on_plot_changed)
	GardenState.seed_changed.connect(func(_s: StringName) -> void: refresh())
	Inventory.changed.connect(func(_c: StringName) -> void: refresh())
	refresh()


func _on_plot_changed(i: int) -> void:
	if i == plot_index:
		refresh()


## O prompt diz o que o próximo toque vai fazer.
func refresh() -> void:
	var p: Dictionary = GardenState.plots[plot_index]
	var crop := GardenState.crop_of(plot_index)
	_soil_mat.albedo_color = Color(0.3, 0.18, 0.1) if p.watered else Color(0.52, 0.34, 0.2)
	plant.visible = crop != null
	fruit.visible = GardenState.is_ready(plot_index)
	if crop:
		plant.scale = Vector3.ONE * lerpf(0.25, 1.0, GardenState.stage(plot_index))
		_fruit_mat.albedo_color = crop.color
	var pct := int(GardenState.stage(plot_index) * 100.0)
	match GardenState.next_action(plot_index):
		&"harvest":
			interactable.prompt = "Colher " + crop.display_name.to_lower()
		&"plant":
			var seed := GardenState.selected_crop()
			if seed:
				var n := Inventory.count(Inventory.BACKPACK, seed.seed_id())
				interactable.prompt = "Plantar %s (%d)   [Q] trocar" % [seed.display_name.to_lower(), n]
			else:
				interactable.prompt = "Sem sementes"
		&"water":
			interactable.prompt = "Regar %s · %d%%" % [crop.display_name.to_lower(), pct]
		&"fertilize":
			interactable.prompt = "Adubar com %s · %d%%" % [GardenState.first_fertilizer().display_name.to_lower(), pct]
		_:
			interactable.prompt = "%s %d%% · pronto em %d min" % [crop.display_name, pct, GardenState.minutes_left(plot_index)]
