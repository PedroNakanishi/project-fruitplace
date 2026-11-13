class_name CustomerProfile
extends Resource
## Tipo de cliente: aparência e paciência. O humor é sorteado na chegada
## (ver Customer.MOOD_WEIGHTS) e muda durante o atendimento.

@export var id: StringName
@export var display_name: String
@export var color: Color = Color.WHITE
## Segundos reais que espera na fila antes de ir embora.
@export var patience_seconds: float = 30.0
