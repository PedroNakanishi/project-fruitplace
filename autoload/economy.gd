extends Node
## Dinheiro, preços do dia, contas noturnas e a regra de falência.

signal money_changed(value: int)
signal risk_changed(value: int)

const START_MONEY := 150
const BILLS := [
	{"id": &"comida", "name": "Comida", "cost": 30, "effect": "geladeira estocada"},
	{"id": &"agua", "name": "Água", "cost": 15, "effect": "regador cheio"},
	{"id": &"gasolina", "name": "Gasolina", "cost": 25, "effect": "tanque cheio"},
]
const WATER_CHARGES_PER_DAY := 12
const TRIPS_PER_TANK := 4
const PRICE_VARIANCE := 0.15
## Noites seguidas com 2+ contas negativas até a falência.
const BANKRUPT_AFTER := 2
const UNPAID_LIMIT := 2

var money := START_MONEY
var risk := 0
var fridge_stocked := true
var water_charges := WATER_CHARGES_PER_DAY
var fuel_trips := TRIPS_PER_TANK
var price_multiplier := {}

# Resumo do dia de trabalho
var work_day_open := false
var sales_today := 0
var units_today := 0
var happy_today := 0
var angry_today := 0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	reset()


func reset() -> void:
	money = START_MONEY
	risk = 0
	fridge_stocked = true
	water_charges = WATER_CHARGES_PER_DAY
	fuel_trips = TRIPS_PER_TANK
	start_day(1)
	money_changed.emit(money)
	risk_changed.emit(risk)


func start_day(day: int) -> void:
	_rng.seed = hash(day)
	for c: CropData in Catalog.CROPS:
		price_multiplier[c.id] = 1.0 + _rng.randf_range(-PRICE_VARIANCE, PRICE_VARIANCE)
	work_day_open = false
	sales_today = 0
	units_today = 0
	happy_today = 0
	angry_today = 0


func sell_price(crop_id: StringName) -> int:
	var crop := Catalog.crop(crop_id)
	return maxi(1, roundi(crop.base_sell_price * price_multiplier.get(crop_id, 1.0)))


func spend(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	money_changed.emit(money)
	return true


func earn(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func record_sale(amount: int, units: int, happy: bool) -> void:
	earn(amount)
	sales_today += amount
	units_today += units
	if happy:
		happy_today += 1
	EventBus.sale_completed.emit(amount)


func record_lost_customer() -> void:
	angry_today += 1
	EventBus.customer_left.emit(false)


func use_trip() -> bool:
	if fuel_trips <= 0:
		return false
	fuel_trips -= 1
	return true


func use_water() -> bool:
	if water_charges <= 0:
		return false
	water_charges -= 1
	return true


func bills_total() -> int:
	var t := 0
	for b: Dictionary in BILLS:
		t += b.cost
	return t


## Paga as contas marcadas em `paid` (id -> bool) e aplica os efeitos.
## Devolve true se o jogador faliu.
func settle_bills(paid: Dictionary) -> bool:
	var unpaid := 0
	for b: Dictionary in BILLS:
		var ok: bool = paid.get(b.id, false) and spend(b.cost)
		if not ok:
			unpaid += 1
		match b.id:
			&"comida":
				fridge_stocked = ok
			&"agua":
				water_charges = WATER_CHARGES_PER_DAY if ok else 0
			&"gasolina":
				fuel_trips = TRIPS_PER_TANK if ok else 0
	risk = risk + 1 if unpaid >= UNPAID_LIMIT else 0
	risk_changed.emit(risk)
	return risk >= BANKRUPT_AFTER
