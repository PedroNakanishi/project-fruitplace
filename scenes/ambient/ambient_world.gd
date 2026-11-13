class_name AmbientWorld
extends Node3D
## Ambientação do mapa: pedestres, carros, bichos, plantas e props espalhados
## só por enfeite, para o mundo parecer vivo. Nada aqui mexe na jogabilidade.
## `layout` escolhe o mapa: "market" (Feira, Mapa 3) ou "backyard_outside"
## (Mapa 2 — só FORA do quintal cercado).

const DAY_NIGHT := preload("res://scenes/components/day_night.gd")
const TREE := preload("res://scenes/props/tree.tscn")
const PALM := preload("res://scenes/props/palm.tscn")
const BUSH := preload("res://scenes/props/bush.tscn")
const FLOWERS := preload("res://scenes/props/flowers.tscn")
const ROCK := preload("res://scenes/props/rock.tscn")

const CAR_COLORS := [
	Color(0.85, 0.25, 0.22), Color(0.25, 0.5, 0.8), Color(0.95, 0.8, 0.3),
	Color(0.9, 0.9, 0.88), Color(0.3, 0.65, 0.45), Color(0.55, 0.3, 0.6),
]
const FLOWER_BUTTERFLIES := [Color(1.0, 0.75, 0.2), Color(0.95, 0.5, 0.7), Color(0.55, 0.75, 1.0), Color(1.0, 0.95, 0.9)]

@export_enum("market", "backyard_outside") var layout := "market"

var _rng := RandomNumberGenerator.new()
var _props: Node3D
var _flora: Node3D
var _fauna: Node3D
var _walkers: Node3D
var _traffic: Node3D

## Retângulos (x, z) onde NÃO se põe nada estático.
var _exclude: Array[Rect2] = []
var _occupied: Array[Vector2] = []
var _flowers: Array[Vector3] = []
var _butterflies: Array[Dictionary] = []
var _fireflies: Array[Dictionary] = []
var _threats: Array[Node3D] = []

# configuração por mapa
var _lanes: Array[float] = []
var _walk_x := 17.5
var _walker_cap := 8
var _walker_gap := Vector2(2.5, 5.0)
var _cross: Array[float] = []  ## x das faixas de travessia; vazio = ninguém atravessa
var _animal_block: Array[Rect2] = []  ## onde bicho nenhum pisa
var _keep_out := Rect2()  ## borboletas e afins nunca entram aqui (o quintal)
var _car_lanes := Vector2.ZERO  ## z da pista que vai para -X (x) e para +X (y)
var _car_gap := Vector2(14.0, 28.0)
var _bird_gap := Vector2(9.0, 18.0)

var _walker_timer := 1.0
var _car_timer := 6.0
var _bird_timer := 4.0
var _clock := 0.0
var _night := 0.0
var _time := 0.0


func _ready() -> void:
	_rng.seed = 20261113
	_props = _group("Props")
	_flora = _group("Flora")
	_fauna = _group("Fauna")
	_walkers = _group("Walkers")
	_traffic = _group("Traffic")
	var player := get_parent().get_node_or_null("Player") as Node3D
	if player:
		_threats.append(player)
	match layout:
		"market":
			_build_market()
		_:
			_build_backyard_outside()
	_apply_time_of_day()
	# já começa com gente na rua (e não só quando o primeiro pedestre chega)
	for i in 4:
		_spawn_walker(true)
	_spawn_car(true)


func _group(n: String) -> Node3D:
	var g := Node3D.new()
	g.name = n
	add_child(g)
	return g


# === Mapa 3: Feira da Vila =================================================

func _build_market() -> void:
	_lanes = [5.7, 7.2, -8.8, -10.2]
	_walk_x = 17.5
	_walker_cap = 10
	_cross = [-15.0, -11.0, 11.0, 15.0]
	_animal_block = [Rect2(-9.5, -7.0, 19.0, 5.6), Rect2(-14.5, -9.0, 5.0, 5.0)]
	_car_lanes = Vector2(-0.4, 3.4)
	# zonas de gameplay: rua, barracas, caminhão e calçada de trabalho
	_exclude = [
		Rect2(-18.5, -1.7, 37.0, 6.4), Rect2(-9.5, -7.0, 19.0, 5.6), Rect2(-14.5, -9.0, 5.0, 5.0),
	]
	_occupied = [Vector2(-15, 6.5), Vector2(10, 6.8), Vector2(14, -9), Vector2(-6, 5), Vector2(6, 5)]

	# calçada da frente
	_place(PropFactory.bench(), Vector3(-10.5, 0, 8.0), 180.0)
	_place(PropFactory.bench(), Vector3(9.5, 0, 8.0), 180.0)
	_place(PropFactory.trash_bin(), Vector3(-5.2, 0, 5.7))
	_place(PropFactory.trash_bin("gas_blue"), Vector3(7.0, 0, 5.7))
	_place(PropFactory.mailbox(), Vector3(13.0, 0, 5.5), 200.0)
	_place(PropFactory.bike(), Vector3(-14.0, 0, 7.6), 90.0)
	_place(PropFactory.bike(), Vector3(-13.2, 0, 7.8), 80.0)
	_place(PropFactory.planter(true), Vector3(-3.0, 0, 8.1), 180.0)
	_place(PropFactory.planter(true), Vector3(3.0, 0, 8.1), 180.0)
	_place(PropFactory.planter(), Vector3(-17.0, 0, 6.0), 90.0)
	_place(PropFactory.planter(true), Vector3(16.5, 0, 6.2), 90.0)
	_place(PropFactory.sign_board("Feira da Vila"), Vector3(11.5, 0, 5.4), 205.0)
	_place(PropFactory.umbrella_table("stripes_pink"), Vector3(14.6, 0, 7.4))
	_place(PropFactory.umbrella_table("stripes_blue"), Vector3(-7.4, 0, 7.4))
	var line := PropFactory.bunting(12.0, 3.6)
	line.position = Vector3(0, 0, 5.0)
	_props.add_child(line)
	# faixa de trás
	_place(PropFactory.bench(), Vector3(-3.0, 0, -11.8), 0.0)
	_place(PropFactory.bench(), Vector3(6.0, 0, -11.8), 0.0)
	_place(PropFactory.planter(true), Vector3(0.0, 0, -12.1))
	_place(PropFactory.planter(true), Vector3(10.0, 0, -12.1))
	_place(PropFactory.planter(), Vector3(-7.0, 0, -12.1))
	_place(PropFactory.crate_stack(3), Vector3(-9.0, 0, -9.6), 15.0)
	_place(PropFactory.crate_stack(8), Vector3(15.0, 0, -6.0), -20.0)
	_place(PropFactory.barrel(), Vector3(-8.2, 0, -11.0))
	_place(PropFactory.barrel(), Vector3(14.2, 0, -7.4))
	_place(PropFactory.trash_bin(), Vector3(2.0, 0, -11.8))
	_place(PropFactory.trash_bin("gas_blue"), Vector3(-16.5, 0, -2.4))

	# casinhas de fundo, formando a "vila"
	var walls := ["wall_pink", "wall_cream", "wall_mint", "wall_yellow"]
	var x := -29.0
	var k := 0
	while x < 29.0:
		var w := _rng.randf_range(4.4, 6.2)
		var h := PropFactory.village_house(walls[k % walls.size()], w, 4.0, _rng.randf_range(3.0, 3.8), k)
		h.position = Vector3(x + w * 0.5, 0, -17.5 + _rng.randf_range(-0.6, 0.6))
		_props.add_child(h)
		x += w + _rng.randf_range(0.8, 1.8)
		k += 1

	# plantas
	var back_hedge: Array[Rect2] = [Rect2(-30, -14.8, 60, 1.6)]
	var sides: Array[Rect2] = [Rect2(-34, -12, 15, 20), Rect2(19.5, -12, 15, 20)]
	var front: Array[Rect2] = [Rect2(-30, 9.3, 60, 3.5)]
	var far_front: Array[Rect2] = [Rect2(-30, 13.5, 60, 4.0)]
	_scatter(func() -> Node3D: return BUSH.instantiate(), 16, back_hedge, 1.6)
	_scatter(func() -> Node3D: return TREE.instantiate(), 4, back_hedge, 4.5)
	_scatter(func() -> Node3D: return PALM.instantiate(), 4, sides, 4.0)
	_scatter(func() -> Node3D: return TREE.instantiate(), 3, sides, 4.5)
	_scatter(func() -> Node3D: return BUSH.instantiate(), 7, sides, 1.8)
	_scatter(func() -> Node3D: return FLOWERS.instantiate(), 14, sides, 1.1, true)
	_scatter(func() -> Node3D: return FLOWERS.instantiate(), 10, front, 1.2, true)
	_scatter(func() -> Node3D: return BUSH.instantiate(), 6, front, 1.8)
	_scatter(func() -> Node3D: return ROCK.instantiate(), 4, front, 2.0)
	_scatter(func() -> Node3D: return PALM.instantiate(), 3, far_front, 5.0)
	_scatter(func() -> Node3D: return TREE.instantiate(), 2, far_front, 5.0)
	_tufts(220, [Rect2(-34, -14.8, 15, 22), Rect2(19.5, -14.8, 15, 22), Rect2(-30, 9.3, 60, 6.0)])
	# flores nos canteiros da calçada (para as borboletas)
	for p: Vector3 in [Vector3(-3, 0, 8.1), Vector3(3, 0, 8.1), Vector3(0, 0, -12.1), Vector3(10, 0, -12.1)]:
		_flowers.append(p)

	# bichos
	_fauna_group(AmbientAnimal.Kind.PIGEON, 5, Rect2(-14, -1.0, 28, 4.6))
	_fauna_group(AmbientAnimal.Kind.PIGEON, 3, Rect2(-12, 5.0, 24, 3.0))
	_fauna_group(AmbientAnimal.Kind.CHICKEN, 3, Rect2(10.5, -11.5, 6.5, 3.5))
	_fauna_group(AmbientAnimal.Kind.CAT, 1, Rect2(-8.5, -11.5, 2.5, 2.0))
	_fauna_group(AmbientAnimal.Kind.CAT, 1, Rect2(-6.0, 6.8, 4.0, 1.4))
	_make_butterflies(6)
	_make_fireflies(16, Rect2(-20, -13, 40, 24))


# === Mapa 2: só fora do quintal ============================================

func _build_backyard_outside() -> void:
	_lanes = [7.3, 8.5]
	_walk_x = 20.0
	_walker_cap = 3
	_walker_gap = Vector2(7.0, 13.0)
	_car_lanes = Vector2(9.5, 11.7)
	_car_gap = Vector2(20.0, 38.0)
	_bird_gap = Vector2(7.0, 14.0)
	# o quintal inteiro (cerca + casa) é intocável
	var yard := Rect2(-9.4, -7.2, 18.8, 14.0)
	_exclude = [yard, Rect2(-40, 7.8, 80, 5.6)]  # quintal e estrada
	_animal_block = [yard, Rect2(-40, 7.9, 80, 5.6)]
	_keep_out = yard.grow(1.6)
	_occupied = [Vector2(-12, -1), Vector2(11.5, -6), Vector2(-11, 5), Vector2(-4, 7.3), Vector2(1.5, 7.5)]

	# casas dos vizinhos, de frente para o quintal
	var left := PropFactory.village_house("wall_mint", 5.4, 4.2, 3.2, 21)
	left.position = Vector3(-20.5, 0, -3.0)
	left.rotation_degrees.y = 90.0
	_props.add_child(left)
	var right := PropFactory.village_house("wall_cream", 5.0, 4.2, 3.4, 22)
	right.position = Vector3(20.5, 0, -1.0)
	right.rotation_degrees.y = -90.0
	_props.add_child(right)
	_occupied.append_array([Vector2(-20.5, -3.0), Vector2(20.5, -1.0)])

	# beira da estrada: ponto de ônibus improvisado e caixa de correio
	_place(PropFactory.bench(), Vector3(8.0, 0, 7.2), 0.0)
	_place(PropFactory.trash_bin(), Vector3(9.4, 0, 7.2))
	_place(PropFactory.mailbox(), Vector3(-0.5, 0, 7.2), 180.0)
	_place(PropFactory.sign_board("Feira →"), Vector3(-6.2, 0, 7.3), 10.0)
	# do lado de fora das cercas
	_place(PropFactory.bike(), Vector3(9.2, 0, 2.0), 90.0)
	_place(PropFactory.crate_stack(5), Vector3(-9.9, 0, -3.5), 80.0)
	_place(PropFactory.barrel(), Vector3(-10.0, 0, -2.2))
	_place(PropFactory.planter(), Vector3(9.6, 0, -2.5), 90.0)

	var left_field: Array[Rect2] = [Rect2(-32, -14, 22, 21)]
	var right_field: Array[Rect2] = [Rect2(10, -14, 22, 21)]
	var behind: Array[Rect2] = [Rect2(-10, -15, 20, 7)]
	var verge: Array[Rect2] = [Rect2(-30, 6.6, 60, 1.0)]
	var across: Array[Rect2] = [Rect2(-30, 14.0, 60, 6.0)]
	_scatter(func() -> Node3D: return TREE.instantiate(), 4, left_field, 4.6)
	_scatter(func() -> Node3D: return TREE.instantiate(), 4, right_field, 4.6)
	_scatter(func() -> Node3D: return PALM.instantiate(), 3, left_field, 4.0)
	_scatter(func() -> Node3D: return PALM.instantiate(), 3, right_field, 4.0)
	_scatter(func() -> Node3D: return TREE.instantiate(), 3, behind, 4.5)
	_scatter(func() -> Node3D: return BUSH.instantiate(), 8, left_field, 1.7)
	_scatter(func() -> Node3D: return BUSH.instantiate(), 8, right_field, 1.7)
	_scatter(func() -> Node3D: return BUSH.instantiate(), 4, behind, 1.7)
	_scatter(func() -> Node3D: return FLOWERS.instantiate(), 16, left_field, 1.1, true)
	_scatter(func() -> Node3D: return FLOWERS.instantiate(), 16, right_field, 1.1, true)
	_scatter(func() -> Node3D: return FLOWERS.instantiate(), 6, verge, 1.4, true)
	_scatter(func() -> Node3D: return ROCK.instantiate(), 4, left_field, 2.0)
	_scatter(func() -> Node3D: return ROCK.instantiate(), 3, right_field, 2.0)
	_scatter(func() -> Node3D: return BUSH.instantiate(), 5, across, 1.8)
	_scatter(func() -> Node3D: return PALM.instantiate(), 3, across, 5.0)
	_tufts(260, [Rect2(-32, -14, 22, 21), Rect2(10, -14, 22, 21), Rect2(-10, -15, 20, 7), Rect2(-30, 6.6, 60, 1.0)])

	_fauna_group(AmbientAnimal.Kind.CHICKEN, 4, Rect2(10.5, -4.0, 7.0, 8.5))
	_fauna_group(AmbientAnimal.Kind.CHICKEN, 2, Rect2(-17.0, -1.0, 6.5, 6.0))
	_fauna_group(AmbientAnimal.Kind.PIGEON, 3, Rect2(-8, 6.9, 16, 1.0))
	_fauna_group(AmbientAnimal.Kind.CAT, 1, Rect2(-15.0, -6.0, 3.0, 3.0))
	_make_butterflies(7)
	_make_fireflies(18, Rect2(-24, -13, 48, 20))


# === montagem estática ======================================================

func _place(n: Node3D, pos: Vector3, yaw := 0.0) -> void:
	n.position = pos
	n.rotation_degrees.y = yaw
	_props.add_child(n)
	_occupied.append(Vector2(pos.x, pos.z))


func _blocked(p: Vector2, min_dist: float) -> bool:
	for r in _exclude:
		if r.has_point(p):
			return true
	for o in _occupied:
		if o.distance_to(p) < min_dist:
			return true
	return false


func _scatter(builder: Callable, count: int, zones: Array[Rect2], min_dist: float, is_flower := false) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 40:
		tries += 1
		var z := zones[_rng.randi() % zones.size()]
		var p := Vector2(_rng.randf_range(z.position.x, z.end.x), _rng.randf_range(z.position.y, z.end.y))
		if _blocked(p, min_dist):
			continue
		var n: Node3D = builder.call()
		n.position = Vector3(p.x, 0.0, p.y)
		n.rotation.y = _rng.randf() * TAU
		n.scale = Vector3.ONE * _rng.randf_range(0.85, 1.25)
		_flora.add_child(n)
		_occupied.append(p)
		if is_flower:
			_flowers.append(n.position)
		placed += 1


## Tufos de capim: um MultiMesh só, com varias lâminas tortas.
func _tufts(count: int, zones: Array[Rect2]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var blade := BoxMesh.new()
	blade.size = Vector3(0.05, 0.32, 0.05)
	mm.mesh = blade
	var transforms: Array[Transform3D] = []
	var guard := 0
	while transforms.size() < count * 3 and guard < count * 12:
		guard += 1
		var z := zones[_rng.randi() % zones.size()]
		var p := Vector2(_rng.randf_range(z.position.x, z.end.x), _rng.randf_range(z.position.y, z.end.y))
		for r in _exclude:
			if r.has_point(p):
				p = Vector2(INF, INF)
				break
		if p.x == INF:
			continue
		for b in 3:
			var basis := Basis.from_euler(Vector3(_rng.randf_range(-0.35, 0.35), _rng.randf() * TAU, _rng.randf_range(-0.35, 0.35)))
			basis = basis.scaled(Vector3(1.0, _rng.randf_range(0.7, 1.5), 1.0))
			transforms.append(Transform3D(basis, Vector3(p.x + (b - 1) * 0.07, 0.14, p.y + _rng.randf_range(-0.05, 0.05))))
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassTufts"
	mmi.multimesh = mm
	mmi.material_override = PropFactory.color_mat(Color(0.36, 0.7, 0.2))
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flora.add_child(mmi)


func _fauna_group(kind: AmbientAnimal.Kind, count: int, zone: Rect2) -> void:
	for i in count:
		var model: Node3D
		match kind:
			AmbientAnimal.Kind.CHICKEN:
				model = PropFactory.chicken(_rng.randf() < 0.6)
			AmbientAnimal.Kind.PIGEON:
				model = PropFactory.pigeon()
			_:
				model = PropFactory.cat([Color(0.85, 0.55, 0.25), Color(0.3, 0.3, 0.32), Color(0.92, 0.9, 0.85)][_rng.randi() % 3])
		var a := AmbientAnimal.new()
		a.threats = _threats
		a.setup(kind, zone, _animal_block, model)
		_fauna.add_child(a)


func _make_butterflies(count: int) -> void:
	var anchors: Array[Vector3] = []
	for f in _flowers:
		if not _keep_out.has_point(Vector2(f.x, f.z)):
			anchors.append(f)
	if anchors.is_empty():
		return
	for i in count:
		var b := PropFactory.butterfly(FLOWER_BUTTERFLIES[i % FLOWER_BUTTERFLIES.size()])
		_fauna.add_child(b)
		_butterflies.append({
			"node": b, "anchor": anchors[_rng.randi() % anchors.size()],
			"t": _rng.randf() * 20.0, "r": _rng.randf_range(0.7, 1.6), "s": _rng.randf_range(0.5, 0.9),
		})


func _make_fireflies(count: int, zone: Rect2) -> void:
	for i in count:
		var f := PropFactory.firefly()
		_fauna.add_child(f)
		var p := Vector2.ZERO
		for t in 30:
			p = Vector2(_rng.randf_range(zone.position.x, zone.end.x), _rng.randf_range(zone.position.y, zone.end.y))
			if not _blocked(p, 0.0) and not _keep_out.grow(1.0).has_point(p):
				break
		_fireflies.append({"node": f, "pos": Vector3(p.x, _rng.randf_range(0.6, 1.8), p.y), "t": _rng.randf() * 20.0})


# === vida em tempo real =====================================================

func _process(delta: float) -> void:
	if TimeManager.night_pending:
		return
	_time += delta
	_clock -= delta
	if _clock <= 0.0:
		_clock = 1.0
		_apply_time_of_day()
		_prune_threats()
	_walker_timer -= delta
	if _walker_timer <= 0.0:
		_walker_timer = randf_range(_walker_gap.x, _walker_gap.y) * (3.0 if _night > 0.6 else 1.0)
		if _walkers.get_child_count() < (_walker_cap if _night < 0.6 else maxi(1, _walker_cap / 4)):
			_spawn_walker()
	_car_timer -= delta
	if _car_timer <= 0.0:
		_car_timer = randf_range(_car_gap.x, _car_gap.y) * (2.0 if _night > 0.6 else 1.0)
		_spawn_car()
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = randf_range(_bird_gap.x, _bird_gap.y)
		if _night < 0.4:
			_spawn_birds()
	_update_butterflies()
	_update_fireflies()


func _apply_time_of_day() -> void:
	_night = float(DAY_NIGHT.sample(TimeManager.minutes % (24 * 60))[5])
	for f in _fireflies:
		(f.node as Node3D).visible = _night > 0.55
	for b in _butterflies:
		(b.node as Node3D).visible = _night < 0.4


func _prune_threats() -> void:
	for i in range(_threats.size() - 1, -1, -1):
		if not is_instance_valid(_threats[i]):
			_threats.remove_at(i)


func _spawn_walker(scattered := false) -> void:
	var dir := 1.0 if randf() < 0.5 else -1.0
	var lane: float = _lanes[randi() % _lanes.size()]
	var x0 := -dir * _walk_x
	var x1 := dir * _walk_x
	var kid := randf() < 0.14
	var spd := randf_range(2.1, 2.6) if kid else randf_range(1.1, 1.8)
	var path: Array[Vector3] = []
	var pauses: Array[float] = []
	if not scattered and not _cross.is_empty() and randf() < 0.2:
		# atravessa a rua numa das faixas, parando um instante para olhar
		var cx: float = _cross[randi() % _cross.size()]
		var from_front := randf() < 0.5
		var a := 6.4 if from_front else -2.6
		var b := -2.6 if from_front else 6.4
		var ea := 4.9 if from_front else -1.9
		var eb := -1.9 if from_front else 4.9
		path = [Vector3(x0, 0, a), Vector3(cx, 0, a), Vector3(cx, 0, ea), Vector3(cx, 0, eb), Vector3(cx, 0, b), Vector3(x1, 0, b)]
		pauses = [0.0, randf_range(0.8, 1.8), 0.0, 0.0, 0.0, 0.0]
	else:
		if scattered:
			x0 = randf_range(-9.0, 9.0)
		path = [Vector3(x0, 0, lane)]
		pauses = [0.0]
		if randf() < 0.4:
			path.append(Vector3(lerpf(x0, x1, randf_range(0.3, 0.7)), 0, lane))
			pauses.append(randf_range(2.0, 5.0))
		path.append(Vector3(x1, 0, lane))
		pauses.append(0.0)
	var w := AmbientWalker.new()
	_walkers.add_child(w)
	w.setup(path, pauses, spd, kid)
	_threats.append(w)


func _spawn_car(scattered := false) -> void:
	var to_left := randf() < 0.5
	var lane := _car_lanes.x if to_left else _car_lanes.y
	var model := PropFactory.car(CAR_COLORS[randi() % CAR_COLORS.size()])
	var m := AmbientMover.new()
	m.add_child(model)
	var dir := -1.0 if to_left else 1.0
	m.position = Vector3(randf_range(-8.0, 8.0) if scattered else -dir * 21.0, 0.0, lane)
	model.rotation.y = 0.0 if dir > 0.0 else PI
	m.velocity = Vector3(dir * randf_range(3.5, 5.5), 0, 0)
	m.limit_x = 22.0
	_traffic.add_child(m)


func _spawn_birds() -> void:
	var dir := -1.0 if randf() < 0.5 else 1.0
	var z0 := randf_range(-8.0, 6.0)
	var y0 := randf_range(5.5, 8.0)
	var col: Color = [Color(0.25, 0.25, 0.3), Color(0.85, 0.35, 0.25), Color(0.3, 0.5, 0.8)][randi() % 3]
	for i in randi_range(1, 3):
		var model := PropFactory.bird(col)
		model.rotation.y = PI * 0.5 * dir
		var m := AmbientMover.new()
		m.add_child(model)
		m.position = Vector3(-dir * 20.0 - dir * i * 1.4, y0 + randf_range(-0.5, 0.5), z0 + randf_range(-1.0, 1.0))
		m.velocity = Vector3(dir * randf_range(3.0, 4.0), 0, 0)
		m.limit_x = 22.0
		m.flap = true
		m.bob = 0.25
		_traffic.add_child(m)


func _update_butterflies() -> void:
	if _night >= 0.4:
		return
	for bf in _butterflies:
		var t: float = bf.t + _time * bf.s
		var a: Vector3 = bf.anchor
		var node: Node3D = bf.node
		var old := node.position
		node.position = a + Vector3(sin(t * 1.3) * bf.r, 0.7 + sin(t * 2.1) * 0.25, cos(t * 0.9) * bf.r)
		var d := node.position - old
		if d.length_squared() > 0.000001:
			node.rotation.y = atan2(d.x, d.z)
		var flap := sin(_time * 28.0 + bf.t) * 0.9
		(node.get_node("WingL") as Node3D).rotation.z = -flap
		(node.get_node("WingR") as Node3D).rotation.z = flap


func _update_fireflies() -> void:
	if _night <= 0.55:
		return
	for f in _fireflies:
		var t: float = f.t + _time
		var p: Vector3 = f.pos
		var node: Node3D = f.node
		node.position = p + Vector3(sin(t * 0.7) * 0.8, sin(t * 1.3) * 0.3, cos(t * 0.5) * 0.8)
		node.scale = Vector3.ONE * (0.6 + 0.6 * maxf(0.0, sin(t * 2.4)))
