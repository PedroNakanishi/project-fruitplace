extends Node3D
## Gira sem parar em torno de um eixo local (hélice do ventilador).

@export var axis := Vector3.FORWARD
@export var speed := 12.0  ## rad/s


func _process(delta: float) -> void:
	rotate_object_local(axis, speed * delta)
