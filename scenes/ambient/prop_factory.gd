class_name PropFactory
extends RefCounted
## Monta props e bichos low-poly por código (caixas e esferas com os materiais
## do jogo). Convenção do projeto: a frente é +Z e a origem fica no chão.

const MAT := "res://assets/materials/"

static var _cache := {}


static func mat(id: String) -> Material:
	if not _cache.has(id):
		_cache[id] = load(MAT + id + ".tres")
	return _cache[id]


static func color_mat(c: Color, rough := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


## Caixa posicionada pelo centro; `m` é um id de material ou um Material.
static func box(parent: Node3D, size: Vector3, pos: Vector3, m: Variant, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(m) if m is String else m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func ball(parent: Node3D, radius: float, pos: Vector3, m: Variant, squash := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = mat(m) if m is String else m
	mi.position = pos
	mi.scale.y = squash
	parent.add_child(mi)
	return mi


static func cyl(parent: Node3D, radius: float, height: float, pos: Vector3, m: Variant) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 10
	mi.mesh = cm
	mi.material_override = mat(m) if m is String else m
	mi.position = pos
	parent.add_child(mi)
	return mi


# === props de rua ===========================================================

static func bench() -> Node3D:
	var n := Node3D.new()
	n.name = "Bench"
	box(n, Vector3(1.5, 0.08, 0.5), Vector3(0, 0.45, 0), "wood_light")
	box(n, Vector3(1.5, 0.4, 0.07), Vector3(0, 0.75, -0.24), "wood_light", Vector3(-8, 0, 0))
	for x: float in [-0.65, 0.65]:
		box(n, Vector3(0.08, 0.45, 0.46), Vector3(x, 0.22, 0), "dark")
	return n


static func trash_bin(m := "can_green") -> Node3D:
	var n := Node3D.new()
	n.name = "TrashBin"
	cyl(n, 0.22, 0.7, Vector3(0, 0.35, 0), m)
	cyl(n, 0.25, 0.06, Vector3(0, 0.72, 0), "dark")
	return n


static func mailbox() -> Node3D:
	var n := Node3D.new()
	n.name = "Mailbox"
	box(n, Vector3(0.08, 0.9, 0.08), Vector3(0, 0.45, 0), "wood")
	box(n, Vector3(0.36, 0.22, 0.26), Vector3(0, 1.0, 0), "tomato")
	box(n, Vector3(0.06, 0.12, 0.02), Vector3(0.14, 1.14, 0.14), "yellow")
	return n


static func crate_stack(seed_value := 0) -> Node3D:
	var n := Node3D.new()
	n.name = "Crates"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	box(n, Vector3(0.7, 0.5, 0.7), Vector3(0, 0.25, 0), "crate")
	box(n, Vector3(0.7, 0.5, 0.7), Vector3(0.78, 0.25, 0.05), "crate", Vector3(0, rng.randf_range(-8, 8), 0))
	box(n, Vector3(0.6, 0.5, 0.6), Vector3(0.3, 0.75, 0.0), "crate", Vector3(0, rng.randf_range(-20, 20), 0))
	ball(n, 0.16, Vector3(0.3, 1.08, 0.0), ["tomato", "orange", "mango", "lettuce"][rng.randi() % 4])
	return n


static func barrel() -> Node3D:
	var n := Node3D.new()
	n.name = "Barrel"
	cyl(n, 0.3, 0.8, Vector3(0, 0.4, 0), "wood")
	cyl(n, 0.32, 0.05, Vector3(0, 0.22, 0), "dark")
	cyl(n, 0.32, 0.05, Vector3(0, 0.6, 0), "dark")
	return n


static func planter(with_tree := false) -> Node3D:
	var n := Node3D.new()
	n.name = "Planter"
	box(n, Vector3(1.1, 0.4, 0.55), Vector3(0, 0.2, 0), "terracotta")
	box(n, Vector3(1.0, 0.05, 0.45), Vector3(0, 0.41, 0), "soil")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 6:
		var x := -0.4 + i * 0.16
		ball(n, 0.12, Vector3(x, 0.55, rng.randf_range(-0.1, 0.1)), "leaves" if i % 2 == 0 else "leaves_light", 0.9)
		ball(n, 0.06, Vector3(x, 0.66, rng.randf_range(-0.1, 0.1)), ["tomato", "yellow", "pink", "white"][rng.randi() % 4])
	if with_tree:
		cyl(n, 0.06, 1.1, Vector3(0, 0.95, 0), "bark")
		ball(n, 0.55, Vector3(0, 1.75, 0), "leaves", 0.85)
		ball(n, 0.38, Vector3(0.25, 1.95, 0.1), "leaves_light")
	return n


static func bike() -> Node3D:
	var n := Node3D.new()
	n.name = "Bike"
	for z: float in [-0.42, 0.42]:
		var wheel := cyl(n, 0.3, 0.05, Vector3(0, 0.3, z), "tire")
		wheel.rotation_degrees = Vector3(0, 0, 90)
	box(n, Vector3(0.05, 0.05, 0.9), Vector3(0, 0.55, 0), "gas_blue", Vector3(-8, 0, 0))
	box(n, Vector3(0.05, 0.4, 0.05), Vector3(0, 0.5, -0.25), "gas_blue")
	box(n, Vector3(0.12, 0.04, 0.26), Vector3(0, 0.78, -0.3), "dark")
	box(n, Vector3(0.4, 0.04, 0.04), Vector3(0, 0.85, 0.4), "chrome")
	return n


static func sign_board(text := "FEIRA") -> Node3D:
	var n := Node3D.new()
	n.name = "SignBoard"
	box(n, Vector3(0.9, 0.7, 0.06), Vector3(0, 0.8, 0), "dark", Vector3(0, 0, 0))
	box(n, Vector3(0.1, 0.5, 0.05), Vector3(-0.3, 0.25, -0.15), "wood", Vector3(-12, 0, 0))
	box(n, Vector3(0.1, 0.5, 0.05), Vector3(0.3, 0.25, -0.15), "wood", Vector3(-12, 0, 0))
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = 0.0045
	l.position = Vector3(0, 0.82, 0.04)
	l.modulate = Color(0.98, 0.95, 0.85)
	l.outline_size = 4
	n.add_child(l)
	return n


static func umbrella_table(m := "stripes_pink") -> Node3D:
	var n := Node3D.new()
	n.name = "UmbrellaTable"
	cyl(n, 0.4, 0.05, Vector3(0, 0.72, 0), "wood_light")
	cyl(n, 0.05, 0.72, Vector3(0, 0.36, 0), "wood")
	for x: float in [-0.7, 0.7]:
		cyl(n, 0.2, 0.05, Vector3(x, 0.42, 0), "wood")
		cyl(n, 0.04, 0.42, Vector3(x, 0.21, 0), "wood")
	cyl(n, 0.03, 1.9, Vector3(0, 0.95, 0), "pole")
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 1.05
	cm.height = 0.4
	cm.radial_segments = 8
	cone.mesh = cm
	cone.material_override = mat(m)
	cone.position = Vector3(0, 2.0, 0)
	n.add_child(cone)
	return n


## Poste de bandeirinhas: um fio com triângulos coloridos entre dois pontos.
static func bunting(length := 6.0, height := 3.2) -> Node3D:
	var n := Node3D.new()
	n.name = "Bunting"
	var cols := ["tomato", "yellow", "gas_blue", "lamp_green", "pink"]
	box(n, Vector3(length, 0.02, 0.02), Vector3(0, height, 0), "dark")
	var count := int(length / 0.45)
	for i in count:
		var x := -length * 0.5 + 0.3 + i * (length - 0.6) / maxf(count - 1, 1)
		var sag := sin(float(i) / maxf(count - 1, 1) * PI) * -0.18
		box(n, Vector3(0.22, 0.28, 0.02), Vector3(x, height - 0.16 + sag, 0), cols[i % cols.size()], Vector3(0, 0, 45))
	return n


# === construções ============================================================

## Casinha de vila vista de frente (para o cenário de fundo).
static func village_house(wall: String, width := 5.0, depth := 4.0, height := 3.4, seed_value := 0) -> Node3D:
	var n := Node3D.new()
	n.name = "VillageHouse"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	box(n, Vector3(width, height, depth), Vector3(0, height * 0.5, 0), wall)
	box(n, Vector3(width + 0.1, 0.5, depth + 0.1), Vector3(0, 0.25, 0), wall + "_dark" if ResourceLoader.exists(MAT + wall + "_dark.tres") else wall)
	# telhado de duas águas (dois painéis inclinados)
	var roof_h := 1.3
	var ang := rad_to_deg(atan2(roof_h, depth * 0.5))
	var slope := sqrt(roof_h * roof_h + depth * depth * 0.25) + 0.2
	for s: float in [-1.0, 1.0]:
		box(n, Vector3(width + 0.5, 0.14, slope), Vector3(0, height + roof_h * 0.5 + 0.05, s * depth * 0.25), "roof", Vector3(-s * ang, 0, 0))
	box(n, Vector3(width, roof_h, 0.1), Vector3(0, height + roof_h * 0.45, depth * 0.5 - 0.05), wall)
	# porta e janelas na frente (+Z)
	var door_x := rng.randf_range(-width * 0.25, width * 0.25)
	box(n, Vector3(0.9, 1.9, 0.1), Vector3(door_x, 0.95, depth * 0.5 + 0.02), "door")
	for wx: float in [-1.0, 1.0]:
		var x := door_x + wx * 1.7
		if absf(x) < width * 0.5 - 0.5:
			box(n, Vector3(0.9, 0.9, 0.08), Vector3(x, 1.9, depth * 0.5 + 0.02), "window")
			box(n, Vector3(1.05, 0.12, 0.12), Vector3(x, 1.38, depth * 0.5 + 0.06), "wood_light")
			box(n, Vector3(0.18, 0.9, 0.1), Vector3(x - 0.58, 1.9, depth * 0.5 + 0.04), "shutter")
			box(n, Vector3(0.18, 0.9, 0.1), Vector3(x + 0.58, 1.9, depth * 0.5 + 0.04), "shutter")
	box(n, Vector3(0.45, 1.4, 0.45), Vector3(width * 0.28, height + roof_h + 0.3, -depth * 0.2), "wall_cream")
	return n


## Carro simples (hatch) de lado: o comprimento fica no eixo X (anda em +X).
static func car(body_color: Color) -> Node3D:
	var n := Node3D.new()
	n.name = "Car"
	var paint := color_mat(body_color, 0.45)
	box(n, Vector3(2.3, 0.55, 1.05), Vector3(0, 0.55, 0), paint)
	box(n, Vector3(1.25, 0.5, 0.95), Vector3(-0.15, 1.05, 0), paint)
	box(n, Vector3(1.05, 0.38, 0.97), Vector3(-0.15, 1.07, 0), "glass_dark")
	box(n, Vector3(0.08, 0.14, 0.2), Vector3(1.16, 0.62, 0.35), "headlight")
	box(n, Vector3(0.08, 0.14, 0.2), Vector3(1.16, 0.62, -0.35), "headlight")
	box(n, Vector3(0.08, 0.14, 0.2), Vector3(-1.16, 0.62, 0.35), "taillight")
	box(n, Vector3(0.08, 0.14, 0.2), Vector3(-1.16, 0.62, -0.35), "taillight")
	for x: float in [-0.75, 0.75]:
		for z: float in [-0.5, 0.5]:
			var w := cyl(n, 0.26, 0.16, Vector3(x, 0.26, z), "tire")
			w.rotation_degrees = Vector3(90, 0, 0)
	return n


# === bichos =================================================================

static func chicken(white := true) -> Node3D:
	var n := Node3D.new()
	n.name = "Chicken"
	var body: Variant = "white" if white else color_mat(Color(0.62, 0.38, 0.2))
	ball(n, 0.17, Vector3(0, 0.25, 0), body, 0.85).scale.z = 1.2
	ball(n, 0.1, Vector3(0, 0.42, 0.14), body)
	box(n, Vector3(0.05, 0.05, 0.08), Vector3(0, 0.4, 0.24), "yellow")
	box(n, Vector3(0.03, 0.06, 0.07), Vector3(0, 0.52, 0.14), "tomato")
	box(n, Vector3(0.12, 0.16, 0.05), Vector3(0, 0.3, -0.2), body, Vector3(30, 0, 0))
	for x: float in [-0.05, 0.05]:
		box(n, Vector3(0.02, 0.1, 0.02), Vector3(x, 0.05, 0.02), "yellow")
	return n


static func pigeon() -> Node3D:
	var n := Node3D.new()
	n.name = "Pigeon"
	var body := color_mat(Color(0.58, 0.6, 0.66))
	var Body := Node3D.new()
	Body.name = "Body"
	n.add_child(Body)
	ball(Body, 0.1, Vector3(0, 0.15, 0), body, 0.85).scale.z = 1.3
	ball(Body, 0.06, Vector3(0, 0.25, 0.1), color_mat(Color(0.4, 0.42, 0.5)))
	box(Body, Vector3(0.025, 0.025, 0.05), Vector3(0, 0.24, 0.17), "yellow")
	box(Body, Vector3(0.08, 0.03, 0.14), Vector3(0, 0.15, -0.14), color_mat(Color(0.4, 0.42, 0.5)))
	for s: float in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "WingL" if s < 0.0 else "WingR"
		wing.position = Vector3(s * 0.08, 0.18, 0.0)
		Body.add_child(wing)
		box(wing, Vector3(0.14, 0.02, 0.12), Vector3(s * 0.07, 0, 0), body)
	for x: float in [-0.03, 0.03]:
		box(n, Vector3(0.015, 0.07, 0.015), Vector3(x, 0.035, 0.0), "tomato")
	return n


static func cat(fur: Color) -> Node3D:
	var n := Node3D.new()
	n.name = "Cat"
	var m := color_mat(fur)
	box(n, Vector3(0.2, 0.2, 0.42), Vector3(0, 0.2, 0), m)
	box(n, Vector3(0.18, 0.17, 0.17), Vector3(0, 0.33, 0.26), m)
	for x: float in [-0.06, 0.06]:
		box(n, Vector3(0.05, 0.07, 0.03), Vector3(x, 0.45, 0.25), m)
		box(n, Vector3(0.025, 0.03, 0.02), Vector3(x, 0.35, 0.35), "dark")
		box(n, Vector3(0.06, 0.15, 0.07), Vector3(x, 0.08, 0.15), m)
		box(n, Vector3(0.06, 0.15, 0.07), Vector3(x, 0.08, -0.15), m)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.27, -0.2)
	n.add_child(tail)
	box(tail, Vector3(0.05, 0.05, 0.34), Vector3(0, 0.1, -0.12), m, Vector3(-35, 0, 0))
	return n


static func butterfly(c: Color) -> Node3D:
	var n := Node3D.new()
	n.name = "Butterfly"
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.25
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for s: float in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "WingL" if s < 0.0 else "WingR"
		n.add_child(wing)
		box(wing, Vector3(0.1, 0.01, 0.08), Vector3(s * 0.05, 0, 0), m)
	box(n, Vector3(0.02, 0.02, 0.09), Vector3.ZERO, "dark")
	return n


static func bird(c: Color) -> Node3D:
	var n := Node3D.new()
	n.name = "Bird"
	var m := color_mat(c)
	box(n, Vector3(0.1, 0.1, 0.26), Vector3.ZERO, m)
	box(n, Vector3(0.05, 0.03, 0.06), Vector3(0, 0, 0.16), "yellow")
	for s: float in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "WingL" if s < 0.0 else "WingR"
		wing.position = Vector3(s * 0.05, 0.03, 0)
		n.add_child(wing)
		box(wing, Vector3(0.32, 0.015, 0.16), Vector3(s * 0.16, 0, 0), m)
	return n


static func firefly() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 6
	sm.rings = 3
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.95, 0.5)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.95, 0.4)
	m.emission_energy_multiplier = 3.0
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
