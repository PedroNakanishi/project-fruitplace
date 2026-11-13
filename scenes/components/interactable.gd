class_name Interactable
extends Area3D
## Qualquer objeto com que o jogador pode interagir. O mapa conecta
## `interacted` à lógica; `prompt` aparece no HUD quando o jogador chega perto.

signal interacted

@export var prompt := "Interagir"
@export var enabled := true


func interact() -> void:
	if enabled:
		interacted.emit()
