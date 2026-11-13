extends Node
## Sinais globais que desacoplam os sistemas, e o mapa de controles.

signal toast(text: String)
signal interaction_prompt(text: String)  ## "" esconde o prompt.
signal interaction_focus(target: Node3D)  ## null = nada em foco.
signal cinematic_finished
signal sleep_requested
signal sale_completed(amount: int)
signal customer_left(happy: bool)

## Verdadeiro enquanto um menu está aberto.
var ui_blocking := false
## Verdadeiro durante uma cinemática.
var cinematic_active := false

const INPUT_KEYS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"interact": [KEY_E, KEY_SPACE],
	&"cycle_seed": [KEY_Q],
	&"inventory": [KEY_I, KEY_TAB],
}


func _ready() -> void:
	for action: StringName in INPUT_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in INPUT_KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


## O jogador não deve andar nem interagir agora.
func input_locked() -> bool:
	return ui_blocking or cinematic_active or SceneRouter.busy or TimeManager.night_pending
