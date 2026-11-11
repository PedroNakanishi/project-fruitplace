class_name CustomerProfile
extends Resource
## Perfil oculto de cliente: como o humor reage a cada opção de atendimento.
## Humor vai de 0 (furioso) a 1 (encantado) e começa em `start_mood`.

@export var id: StringName
@export var display_name: String
@export var color: Color = Color.WHITE
@export_range(0.0, 1.0) var start_mood: float = 0.5
@export var flattery_reaction: float = 0.0
@export var discount_reaction: float = 0.0
@export var markup_reaction: float = 0.0
## Segundos reais que espera na fila antes de ir embora.
@export var patience_seconds: float = 30.0
