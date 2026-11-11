extends OmniLight3D
## Luz que tremula, como a tela de uma TV de tubo.

@export var base_energy := 0.6
@export var amount := 0.25

var _wait := 0.0


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = randf_range(0.08, 0.4)
		light_energy = base_energy + randf_range(-amount, amount)
