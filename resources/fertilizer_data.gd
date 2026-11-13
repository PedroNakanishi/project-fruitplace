class_name FertilizerData
extends ItemData
## Adubo: dá bônus de Rendimento (unidades extras) e/ou de Crescimento.

@export var price: int = 5
@export_enum("Comum", "Incomum", "Raro", "Épico") var rarity: String = "Comum"
## Unidades extras na colheita.
@export var yield_bonus: int = 0
## Velocidade extra de crescimento (0.15 = 15% mais rápido).
@export var growth_bonus: float = 0.0
