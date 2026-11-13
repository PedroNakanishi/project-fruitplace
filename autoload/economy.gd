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
## As contas sobem um pouco a cada dia (inflação dos anos 90).
const INFLATION_PER_DAY := 0.03
## Leilões de lojas: dia da semana (0 = segunda) e minuto do dia.
const AUCTIONS := [
	{"weekday": 1, "minutes": 15 * 60},  # Terça 15:00
	{"weekday": 5, "minutes": 11 * 60},  # Sábado 11:00
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
## Jogador saiu sem encerrar o dia: placa "Volto logo", ninguém compra.
var stall_away := false
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
	stall_away = false
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


## Valor de uma conta no dia atual, com a inflação acumulada.
func bill_cost(bill: Dictionary) -> int:
	return roundi(bill.cost * pow(1.0 + INFLATION_PER_DAY, TimeManager.day - 1))


## As contas desta noite, com os valores do dia.
func bills_today() -> Array:
	var out: Array = []
	for b: Dictionary in BILLS:
		var today := b.duplicate()
		today.cost = bill_cost(b)
		out.append(today)
	return out


func bills_total() -> int:
	var t := 0
	for b: Dictionary in BILLS:
		t += bill_cost(b)
	return t


## Próximo leilão no dia de hoje, em minutos do dia, ou -1.
func auction_today() -> int:
	for a: Dictionary in AUCTIONS:
		if a.weekday == TimeManager.weekday():
			return a.minutes
	return -1


## Paga as contas marcadas em `paid` (id -> bool) e aplica os efeitos.
## Devolve true se o jogador faliu.
func settle_bills(paid: Dictionary) -> bool:
	var unpaid := 0
	for b: Dictionary in BILLS:
		var ok: bool = paid.get(b.id, false) and spend(bill_cost(b))
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
