extends Node
## Luz do dia: muda o sol, a luz ambiente e a cor do céu conforme o relógio,
## e acende as luzes do grupo "night_light" quando escurece.

const NIGHT := [Color(0.55, 0.65, 1.0), 0.3, Color(0.5, 0.55, 0.9), 0.55, Color(0.06, 0.07, 0.18), 1.0]
const DAY := [Color(1.0, 0.96, 0.86), 1.15, Color(1.0, 0.95, 0.85), 0.7, Color(0.55, 0.82, 0.95), 0.0]
## [minuto do dia, [cor do sol, força do sol, cor ambiente, força ambiente, céu, quanto é noite 0..1]]
const KEYS := [
	[0, NIGHT],
	[5 * 60, NIGHT],
	[6 * 60 + 30, [Color(1.0, 0.72, 0.5), 0.8, Color(1.0, 0.84, 0.76), 0.6, Color(0.98, 0.72, 0.52), 0.3]],  # amanhecer
	[9 * 60, DAY],
	[16 * 60, DAY],
	[18 * 60, [Color(1.0, 0.62, 0.35), 0.95, Color(1.0, 0.8, 0.7), 0.62, Color(0.98, 0.58, 0.38), 0.35]],  # pôr do sol
	[19 * 60 + 15, [Color(0.65, 0.6, 1.0), 0.4, Color(0.6, 0.55, 0.9), 0.55, Color(0.22, 0.16, 0.38), 0.9]],  # crepúsculo
	[20 * 60 + 30, NIGHT],
	[24 * 60, NIGHT],
]

@export var sun_path: NodePath = ^"../Sun"
@export var environment_path: NodePath = ^"../Environment"

var _sun: DirectionalLight3D
var _env: Environment
var _lamps: Array[Light3D] = []
var _last := -1


func _ready() -> void:
	_sun = get_node(sun_path)
	_env = (get_node(environment_path) as WorldEnvironment).environment
	for l: Light3D in get_parent().find_children("*", "Light3D", true, false):
		if l.is_in_group(&"night_light"):
			l.set_meta(&"full_energy", l.light_energy)
			_lamps.append(l)
	_apply()


func _process(_delta: float) -> void:
	if TimeManager.minutes != _last:
		_apply()


func _apply() -> void:
	_last = TimeManager.minutes
	var s := sample(_last % (24 * 60))
	_sun.light_color = s[0]
	_sun.light_energy = s[1]
	_env.ambient_light_color = s[2]
	_env.ambient_light_energy = s[3]
	_env.background_color = s[4]
	for l in _lamps:
		l.light_energy = float(l.get_meta(&"full_energy")) * float(s[5])
		l.visible = float(s[5]) > 0.02


## Mistura os dois pontos-chave vizinhos de `minute` (0..1439).
static func sample(minute: int) -> Array:
	for i in range(1, KEYS.size()):
		if minute <= KEYS[i][0]:
			var a: Array = KEYS[i - 1][1]
			var b: Array = KEYS[i][1]
			var t := inverse_lerp(KEYS[i - 1][0], KEYS[i][0], minute)
			return [a[0].lerp(b[0], t), lerpf(a[1], b[1], t), a[2].lerp(b[2], t), lerpf(a[3], b[3], t), a[4].lerp(b[4], t), lerpf(a[5], b[5], t)]
	return NIGHT
