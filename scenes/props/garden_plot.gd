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
	refresh()


func _on_plot_changed(i: int) -> void:
	if i == plot_index:
		refresh()


func refresh() -> void:
	var p: Dictionary = GardenState.plots[plot_index]
	var crop := GardenState.crop_of(plot_index)
	var ripe := GardenState.is_ready(plot_index)
	_soil_mat.albedo_color = Color(0.3, 0.18, 0.1) if p.watered else Color(0.52, 0.34, 0.2)
	plant.visible = crop != null
	fruit.visible = ripe
	if crop == null:
		interactable.prompt = "Plantar"
		return
	var s := GardenState.stage(plot_index)
	plant.scale = Vector3.ONE * lerpf(0.25, 1.0, s)
	_fruit_mat.albedo_color = crop.color
	if ripe:
		interactable.prompt = "Colher " + crop.display_name.to_lower()
	else:
		var tags := ""
		if p.watered:
			tags += " · regado"
		if p.fertilized:
			tags += " · adubado"
		interactable.prompt = "%s %d%%%s" % [crop.display_name, int(s * 100.0), tags]
