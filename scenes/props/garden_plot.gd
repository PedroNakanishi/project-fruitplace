extends Node3D
## Visual de um lote. Não guarda estado: lê tudo do GardenState.
## O modelo da planta vem de res://scenes/props/crops/<id>.tscn; o nó "Ripe"
## dentro dele só aparece quando está pronto para colher.

signal plot_interacted(index: int)

const SOIL_DRY := preload("res://assets/materials/soil.tres")
const SOIL_WET := preload("res://assets/materials/soil_wet.tres")
const CROP_SCENE := "res://scenes/props/crops/%s.tscn"
const GENERIC_CROP := "generic"

@export var plot_index := 0

@onready var soil: MeshInstance3D = $Soil
@onready var plant_slot: Node3D = $PlantSlot
@onready var interactable: Interactable = $Interactable

var _crop_id := &""
var _model: Node3D
var _visual_key := ""


func _ready() -> void:
	interactable.interacted.connect(func() -> void: plot_interacted.emit(plot_index))
	GardenState.plot_changed.connect(_on_plot_changed)
	GardenState.seed_changed.connect(func(_s: StringName) -> void: _refresh_prompt())
	Inventory.changed.connect(func(_c: StringName) -> void: _refresh_prompt())
	refresh()


func _on_plot_changed(i: int) -> void:
	if i == plot_index:
		refresh()


func refresh() -> void:
	_refresh_visual()
	_refresh_prompt()


## Só refaz o modelo quando algo visível mudou (cultura, rega, pronto ou
## um vigésimo de crescimento), não a cada minuto de jogo.
func _refresh_visual() -> void:
	var p: Dictionary = GardenState.plots[plot_index]
	var key := "%s|%s|%d|%s" % [p.crop, p.watered, int(GardenState.stage(plot_index) * 20.0), GardenState.is_ready(plot_index)]
	if key == _visual_key:
		return
	_visual_key = key
	var crop := GardenState.crop_of(plot_index)
	soil.material_override = SOIL_WET if p.watered else SOIL_DRY
	_show_crop(crop)
	if _model:
		_model.scale = Vector3.ONE * lerpf(0.3, 1.0, GardenState.stage(plot_index))
		var ripe := _model.get_node_or_null("Ripe") as Node3D
		if ripe:
			ripe.visible = GardenState.is_ready(plot_index)


## O prompt diz o que o próximo toque vai fazer.
func _refresh_prompt() -> void:
	var crop := GardenState.crop_of(plot_index)
	var pct := int(GardenState.stage(plot_index) * 100.0)
	match GardenState.next_action(plot_index):
		&"harvest":
			interactable.prompt = "Colher " + crop.display_name.to_lower()
		&"plant":
			var seed := GardenState.selected_crop()
			if seed:
				var n := Inventory.count(Inventory.BACKPACK, seed.seed_id())
				interactable.prompt = "Plantar %s (%d)   [%s] trocar" % [seed.display_name.to_lower(), n, EventBus.key_label(&"cycle_seed")]
			else:
				interactable.prompt = "Sem sementes"
		&"water":
			interactable.prompt = "Regar %s · %d%%" % [crop.display_name.to_lower(), pct]
		&"fertilize":
			interactable.prompt = "Adubar com %s · %d%%" % [GardenState.first_fertilizer().display_name.to_lower(), pct]
		_:
			interactable.prompt = "%s %d%% · pronto em %d min" % [crop.display_name, pct, GardenState.minutes_left(plot_index)]


## Troca o modelo quando a cultura do lote muda. Cultura sem cena própria usa
## o broto genérico, com o fruto pintado na cor do produto.
func _show_crop(crop: CropData) -> void:
	var id: StringName = crop.id if crop else &""
	if id == _crop_id:
		return
	_crop_id = id
	if _model:
		_model.queue_free()
		_model = null
	if crop == null:
		return
	var path := CROP_SCENE % id
	var generic := not ResourceLoader.exists(path)
	if generic:
		path = CROP_SCENE % GENERIC_CROP
	_model = (load(path) as PackedScene).instantiate()
	plant_slot.add_child(_model)
	if generic:
		var m := StandardMaterial3D.new()
		m.albedo_color = crop.color
		m.roughness = 1.0
		for fruit: MeshInstance3D in _model.get_node("Ripe").find_children("*", "MeshInstance3D", true, false):
			fruit.material_override = m
