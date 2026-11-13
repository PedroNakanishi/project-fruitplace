class_name Humanoid
extends Node3D
## Boneco low-poly do jogador, dos clientes e dos feirantes.
## As cores entram pelos exports; `walking` liga o balanço de pernas e braços.

signal stepped  ## Um pé tocou o chão (para o som de passo).

const SKINS := [Color(0.96, 0.78, 0.62), Color(0.85, 0.62, 0.45), Color(0.68, 0.46, 0.32), Color(0.45, 0.3, 0.2)]
const HAIRS := [Color(0.12, 0.09, 0.07), Color(0.3, 0.18, 0.1), Color(0.55, 0.36, 0.16), Color(0.75, 0.74, 0.72), Color(0.85, 0.7, 0.3)]
const PANTS := [Color(0.22, 0.3, 0.55), Color(0.35, 0.3, 0.26), Color(0.25, 0.25, 0.28), Color(0.6, 0.52, 0.4), Color(0.5, 0.2, 0.25)]
const STRIDE := 11.0  ## Velocidade do balanço, em rad/s.

@export var shirt := Color(0.95, 0.55, 0.25)
@export var pants := Color(0.24, 0.38, 0.68)
@export var skin := Color(0.85, 0.62, 0.45)
@export var hair := Color(0.2, 0.13, 0.08)
@export var hat := false

var walking := false
var _phase := 0.0
var _swing := 0.0

@onready var _rig: Node3D = $Rig
@onready var _leg_l: Node3D = $Rig/LegL
@onready var _leg_r: Node3D = $Rig/LegR
@onready var _arm_l: Node3D = $Rig/ArmL
@onready var _arm_r: Node3D = $Rig/ArmR


func _ready() -> void:
	apply_look()


## Sorteia pele, cabelo e calça; a camisa fica com `shirt_color`.
func randomize_look(shirt_color: Color) -> void:
	shirt = shirt_color
	skin = SKINS.pick_random()
	hair = HAIRS.pick_random()
	pants = PANTS.pick_random()
	hat = randf() < 0.2
	if is_node_ready():
		apply_look()


## Pinta as peças pelo prefixo do nome: Shirt*, Pants*, Skin*, Hair*.
func apply_look() -> void:
	var mats := {"Shirt": _flat(shirt), "Pants": _flat(pants), "Skin": _flat(skin), "Hair": _flat(hair)}
	for part: MeshInstance3D in _rig.find_children("*", "MeshInstance3D", true, false):
		for prefix: String in mats:
			if part.name.begins_with(prefix):
				part.material_override = mats[prefix]
	($Rig/Hat as Node3D).visible = hat


func _process(delta: float) -> void:
	_swing = move_toward(_swing, 1.0 if walking else 0.0, delta * 8.0)
	if _swing <= 0.0:
		_phase = 0.0
		return
	var before := sin(_phase)
	_phase += delta * STRIDE
	var s := sin(_phase)
	if walking and signf(s) != signf(before):
		stepped.emit()
	var a := s * 0.75 * _swing
	_leg_l.rotation.x = a
	_leg_r.rotation.x = -a
	_arm_l.rotation.x = -a * 0.8
	_arm_r.rotation.x = a * 0.8
	_rig.position.y = absf(cos(_phase)) * 0.04 * _swing


static func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic_specular = 0.2
	return m
