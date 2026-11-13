extends Node3D
## Câmera ortográfica isométrica. Com `follow`, acompanha o alvo suavemente.

@export var target_path: NodePath
@export var follow := false
@export var yaw_degrees := 45.0
@export var pitch_degrees := -35.0
@export var distance := 30.0
@export var ortho_size := 13.0

@onready var cam: Camera3D = $Camera3D
var _target: Node3D
var _snapped := false


func _ready() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ortho_size
	cam.position = Vector3(0.0, 0.0, distance)
	cam.far = 200.0
	cam.make_current()
	if follow and not target_path.is_empty():
		_target = get_node(target_path)


func _process(delta: float) -> void:
	if _target == null:
		return
	if not _snapped:
		global_position = _target.global_position
		_snapped = true
	global_position = global_position.lerp(_target.global_position, 1.0 - exp(-6.0 * delta))
