extends CharacterBody3D
## Movimento relativo à câmera isométrica e foco no Interactable mais próximo.
## A tecla de interação é lida pela cena Main, que chama `try_interact()`.

const SPEED := 5.5
const GRAVITY := 20.0
const FALL_LIMIT := -6.0  ## Abaixo disso o jogador caiu do mapa.

@onready var reach: Area3D = $Reach
@onready var body: Humanoid = $Body

var _focus: Interactable
var _last_prompt := ""
var _last_target: Interactable
var _safe_position := Vector3.ZERO
var _has_safe := false


func _ready() -> void:
	body.stepped.connect(Sfx.step)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if not EventBus.input_locked():
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var cam := get_viewport().get_camera_3d()
	var yaw := cam.global_rotation.y if cam else 0.0
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	_keep_on_map()
	body.walking = dir.length_squared() > 0.01 and is_on_floor()
	if dir.length_squared() > 0.01:
		body.rotation.y = atan2(dir.x, dir.z)
	_update_focus()


## Rede de segurança: se uma falha de colisão deixar o jogador cair do
## mapa, ele volta para o último lugar firme em vez de sumir no limbo.
func _keep_on_map() -> void:
	if is_on_floor():
		_safe_position = global_position
		_has_safe = true
	elif global_position.y < FALL_LIMIT and _has_safe:
		global_position = _safe_position
		velocity = Vector3.ZERO


func try_interact() -> void:
	if _focus and _focus.enabled:
		_focus.interact()


func _update_focus() -> void:
	var best: Interactable = null
	if not EventBus.input_locked():
		var best_d := INF
		for a in reach.get_overlapping_areas():
			if a is Interactable and a.enabled:
				var d := global_position.distance_squared_to(a.global_position)
				if d < best_d:
					best = a
					best_d = d
	_focus = best
	var prompt := best.prompt if best else ""
	if best != _last_target:
		_last_target = best
		EventBus.interaction_focus.emit(best)
	if prompt != _last_prompt:
		_last_prompt = prompt
		EventBus.interaction_prompt.emit(prompt)
