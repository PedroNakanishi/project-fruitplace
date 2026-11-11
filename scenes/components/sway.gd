extends Node3D
## Balanço suave de vai e vem: folhas ao vento, roupa no varal, rabo do cachorro.

@export var axis := Vector3.FORWARD
@export var degrees := 4.0
@export var speed := 1.2

var _base := Vector3.ZERO
var _t := 0.0


func _ready() -> void:
	_base = rotation
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * speed
	rotation = _base + axis * deg_to_rad(degrees) * sin(_t)
