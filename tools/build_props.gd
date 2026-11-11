extends SceneTree
## Monta os materiais e os modelos low-poly do jogo a partir de primitivas.
## Uso: Godot --headless --path . -s tools/build_props.gd
##
## Gera res://assets/materials/*.tres, res://scenes/props/**/*.tscn e
## res://scenes/characters/humanoid.tscn. As cenas geradas são cenas comuns:
## dá para abrir e ajustar no editor. ATENÇÃO: rodar este script de novo
## sobrescreve esses ajustes — mudanças permanentes de forma vão aqui.
## Convenção: a frente de todo objeto é +Z e a origem fica no chão.

const MAT := "res://assets/materials/"
const TEX := "res://assets/textures/"
const PROPS := "res://scenes/props/"
const COMPONENTS := "res://scenes/components/"

var _m := {}


func _initialize() -> void:
	for dir: String in [MAT, PROPS + "crops/", "res://scenes/characters/"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	materials()
	humanoid()
	house_props()
	wall_props()
	yard_props()
	garden_plot()
	crops()
	truck()
	stall("stall_player", "stripes_orange", false)
	stall("stall_blue", "stripes_blue", true)
	stall("stall_pink", "stripes_pink", true)
	print("Modelos gerados em ", PROPS)
	quit()


# === materiais ==============================================================

func materials() -> void:
	# Cenário fixo: triplanar no espaço do mundo (16 px por metro).
	tex("floor_planks", "planks", 2.0, true)
	tex("floor_tile", "tile", 1.0, true)
	tex("grass", "grass", 2.0, true)
	tex("grass_far", "grass", 2.0, true, Color(0.8, 0.86, 0.78))
	tex("soil", "soil", 1.0, true)
	tex("soil_wet", "soil_wet", 1.0, true)
	tex("asphalt", "asphalt", 2.0, true)
	tex("paving", "paving", 2.0, true)
	tex("gravel", "gravel", 1.0, true)
	tex("dirt_road", "gravel", 1.0, true, Color(0.86, 0.72, 0.56))
	tex("roof", "roof", 1.0, true)
	tex("wall_mint", "plaster", 2.0, true, Color(0.62, 0.86, 0.74))
	tex("wall_mint_dark", "plaster", 2.0, true, Color(0.4, 0.66, 0.56))
	tex("wall_pink", "plaster", 2.0, true, Color(0.97, 0.66, 0.68))
	tex("wall_pink_dark", "plaster", 2.0, true, Color(0.82, 0.46, 0.52))
	tex("wall_yellow", "plaster", 2.0, true, Color(0.99, 0.86, 0.52))
	tex("wall_yellow_dark", "plaster", 2.0, true, Color(0.85, 0.52, 0.34))
	tex("wall_cream", "plaster", 2.0, true, Color(0.96, 0.9, 0.78))
	# Objetos: triplanar no espaço do próprio objeto.
	tex("wood", "wood", 1.0)
	tex("wood_light", "wood_light", 1.0)
	tex("crate", "crate", 0.5)
	tex("bark", "bark", 1.0)
	tex("leaves", "leaves", 1.0)
	tex("leaves_light", "leaves", 1.0, false, Color(1.0, 1.0, 0.7))
	tex("palm_leaf", "leaves", 1.0, false, Color(0.85, 1.0, 0.6))
	tex("fabric_white", "fabric", 0.5)
	tex("fabric_blue", "fabric", 0.5, false, Color(0.36, 0.56, 0.92))
	tex("fabric_red", "fabric", 0.5, false, Color(0.86, 0.36, 0.4))
	tex("fabric_red_dark", "fabric", 0.5, false, Color(0.7, 0.27, 0.32))
	tex("fabric_yellow", "fabric", 0.5, false, Color(0.98, 0.82, 0.36))
	tex("gingham", "gingham", 0.5)
	tex("stripes_orange", "stripes_orange", 1.0)
	tex("stripes_blue", "stripes_blue", 1.0)
	tex("stripes_pink", "stripes_pink", 1.0)
	tex("shutter", "wood_light", 1.0, false, Color(0.3, 0.62, 0.42))
	# Texturas esticadas na peça.
	flat("rug", "rug")
	flat("window", "window", false, 0.25)
	flat("door", "door")
	flat("picture", "picture")
	flat("clock", "clock", true)
	# Cores chapadas.
	col("enamel", Color(0.95, 0.95, 0.92))
	col("cream", Color(0.96, 0.92, 0.8))
	col("dark", Color(0.14, 0.14, 0.16))
	col("plastic_dark", Color(0.24, 0.22, 0.22))
	col("gray", Color(0.56, 0.57, 0.6))
	col("chrome", Color(0.8, 0.82, 0.85))
	col("stone", Color(0.72, 0.7, 0.66))
	col("brass", Color(0.92, 0.76, 0.3))
	col("terracotta", Color(0.78, 0.44, 0.28))
	col("straw", Color(0.95, 0.84, 0.46))
	col("phone_red", Color(0.86, 0.16, 0.16))
	col("yellow", Color(0.98, 0.85, 0.25))
	col("orange", Color(0.98, 0.58, 0.14))
	col("tomato", Color(0.86, 0.2, 0.16))
	col("lettuce", Color(0.4, 0.72, 0.24))
	col("lettuce_light", Color(0.66, 0.88, 0.36))
	col("crop_leaf", Color(0.24, 0.58, 0.24))
	col("leaf_dark", Color(0.16, 0.42, 0.24))
	col("cassava", Color(0.62, 0.42, 0.24))
	col("cassava_stem", Color(0.56, 0.3, 0.26))
	col("mango", Color(0.98, 0.7, 0.2))
	col("coconut", Color(0.42, 0.3, 0.18))
	col("pink", Color(0.96, 0.5, 0.68))
	col("white", Color(0.98, 0.98, 0.96))
	col("cloth_blue", Color(0.3, 0.55, 0.85))
	col("cloth_red", Color(0.85, 0.28, 0.25))
	col("gas_blue", Color(0.3, 0.46, 0.62))
	col("can_green", Color(0.3, 0.6, 0.52))
	col("water", Color(0.36, 0.62, 0.86))
	col("glass", Color(0.62, 0.84, 0.95))
	col("glass_dark", Color(0.16, 0.2, 0.26))
	col("cage", Color(0.85, 0.87, 0.9), 0.0, 0.3)
	col("blade", Color(0.5, 0.75, 0.9))
	col("truck_red", Color(0.82, 0.22, 0.18))
	col("truck_red_dark", Color(0.6, 0.15, 0.13))
	col("tire", Color(0.1, 0.1, 0.12))
	col("caramel", Color(0.82, 0.58, 0.3))
	col("caramel_light", Color(0.93, 0.76, 0.5))
	col("caramel_dark", Color(0.6, 0.38, 0.18))
	col("pole", Color(0.9, 0.9, 0.88))
	col("lamp_green", Color(0.16, 0.34, 0.28))
	col("tv_screen", Color(0.45, 0.75, 0.95), 1.2)
	col("lamp_shade", Color(1.0, 0.86, 0.55), 0.9)
	col("headlight", Color(1.0, 0.95, 0.7), 0.6)
	col("taillight", Color(0.95, 0.2, 0.15), 0.4)


## Cor chapada. `glow` > 0 faz a peça emitir luz; `alpha` < 1 deixa translúcida.
func col(id: String, c: Color, glow := 0.0, alpha := 1.0) -> void:
	var m := _base()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_keep(id, m)


## Textura pixelada triplanar. `tile` = metros por repetição. Com `world`, a
## textura acompanha o mundo: peças vizinhas do cenário emendam sem costura.
func tex(id: String, file: String, tile: float, world := false, tint := Color.WHITE) -> void:
	var m := _base()
	m.albedo_texture = load(TEX + file + ".png")
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true
	m.uv1_world_triplanar = world
	m.uv1_scale = Vector3.ONE / tile
	_keep(id, m)


## Textura esticada no UV da peça (quadro, janela, tapete).
func flat(id: String, file: String, cutout := false, glow := 0.0) -> void:
	var m := _base()
	m.albedo_texture = load(TEX + file + ".png")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if cutout:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	if glow > 0.0:
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission_energy_multiplier = glow
	_keep(id, m)


func _base() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 1.0
	m.metallic_specular = 0.2
	return m


func _keep(id: String, m: Material) -> void:
	var path := MAT + id + ".tres"
	ResourceSaver.save(m, path)
	m.take_over_path(path)
	_m[id] = m


# === peças ==================================================================

func box(p: Node3D, n: String, size: Vector3, pos: Vector3, mat: String, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(p, n, mesh, pos, rot, mat)


## Cilindro (ou cone, com raios diferentes) em pé no eixo Y.
func cyl(p: Node3D, n: String, top: float, bottom: float, height: float, pos: Vector3, mat: String,
		rot := Vector3.ZERO, sides := 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return _mesh(p, n, mesh, pos, rot, mat)


func ball(p: Node3D, n: String, radius: float, pos: Vector3, mat: String, squash := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var mi := _mesh(p, n, mesh, pos, Vector3.ZERO, mat)
	mi.scale = squash
	return mi


## Plano virado para +Z (use `rot` para deitar ou virar).
func quad(p: Node3D, n: String, size: Vector2, pos: Vector3, mat: String, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	return _mesh(p, n, mesh, pos, rot, mat)


func node(p: Node3D, n: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	return _place(p, Node3D.new(), n, pos, rot)


## Raiz de um objeto sólido (o jogador esbarra nas caixas criadas com `hit`).
func solid(n: String) -> StaticBody3D:
	var r := StaticBody3D.new()
	r.name = n
	return r


func hit(body: Node3D, size: Vector3, pos: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_place(body, cs, "Hit", pos, Vector3.ZERO)


## Área de interação (Interactable) com uma caixa.
func area(p: Node3D, n: String, size: Vector3, pos: Vector3, prompt: String) -> void:
	var a := Area3D.new()
	a.set_script(load(COMPONENTS + "interactable.gd"))
	a.set("prompt", prompt)
	_place(p, a, n, pos, Vector3.ZERO)
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_place(a, cs, "Shape", Vector3.ZERO, Vector3.ZERO)


## Luz que só acende à noite (ver day_night.gd).
func lamp(p: Node3D, n: String, pos: Vector3, color: Color, energy: float, reach: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = reach
	l.add_to_group(&"night_light", true)
	_place(p, l, n, pos, Vector3.ZERO)


func attach(n: Node, file: String, props := {}) -> void:
	n.set_script(load(file))
	for key: String in props:
		n.set(key, props[key])


func save(root: Node, file: String, dir := PROPS) -> void:
	_own(root, root)
	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, dir + file + ".tscn")
	root.free()


func _mesh(p: Node3D, n: String, mesh: PrimitiveMesh, pos: Vector3, rot: Vector3, mat: String) -> MeshInstance3D:
	assert(_m.has(mat), "material desconhecido: " + mat)
	mesh.material = _m[mat]
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	_place(p, mi, n, pos, rot)
	return mi


func _place(p: Node3D, n: Node3D, node_name: String, pos: Vector3, rot: Vector3) -> Node3D:
	n.name = node_name
	n.position = pos
	n.rotation_degrees = rot
	p.add_child(n, true)
	return n


func _own(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		if c.scene_file_path == "":  # não entra em cenas instanciadas
			_own(c, root)


# === personagens ============================================================

func humanoid() -> void:
	var r := Node3D.new()
	r.name = "Humanoid"
	attach(r, "res://scenes/characters/humanoid.gd")
	var rig := node(r, "Rig")
	for side: int in [-1, 1]:
		var tag := "L" if side < 0 else "R"
		var leg := node(rig, "Leg" + tag, Vector3(side * 0.12, 0.56, 0))
		box(leg, "PantsLeg", Vector3(0.18, 0.5, 0.2), Vector3(0, -0.25, 0), "white")
		box(leg, "Shoe", Vector3(0.19, 0.09, 0.28), Vector3(0, -0.515, 0.035), "dark")
		var arm := node(rig, "Arm" + tag, Vector3(side * 0.295, 1.04, 0))
		box(arm, "ShirtSleeve", Vector3(0.13, 0.26, 0.16), Vector3(0, -0.1, 0), "white")
		box(arm, "SkinArm", Vector3(0.11, 0.26, 0.13), Vector3(0, -0.36, 0), "white")
		box(rig, "Eye" + tag, Vector3(0.05, 0.07, 0.02), Vector3(side * 0.085, 1.29, 0.165), "dark")
	box(rig, "PantsHip", Vector3(0.46, 0.12, 0.26), Vector3(0, 0.56, 0), "white")
	box(rig, "ShirtTorso", Vector3(0.46, 0.46, 0.26), Vector3(0, 0.85, 0), "white")
	box(rig, "SkinHead", Vector3(0.34, 0.32, 0.32), Vector3(0, 1.27, 0), "white")
	box(rig, "HairTop", Vector3(0.37, 0.1, 0.35), Vector3(0, 1.46, -0.01), "white")
	box(rig, "HairBack", Vector3(0.37, 0.24, 0.08), Vector3(0, 1.33, -0.15), "white")
	var hat := node(rig, "Hat", Vector3(0, 1.5, 0))
	cyl(hat, "Brim", 0.42, 0.42, 0.035, Vector3(0, 0.02, 0), "straw")
	cyl(hat, "Crown", 0.19, 0.22, 0.16, Vector3(0, 0.1, 0), "straw")
	cyl(hat, "Band", 0.205, 0.225, 0.045, Vector3(0, 0.055, 0), "tomato")
	save(r, "humanoid", "res://scenes/characters/")


# === casa ===================================================================

func house_props() -> void:
	var r := solid("Bed")
	box(r, "Base", Vector3(2.2, 0.3, 3.2), Vector3(0, 0.27, 0), "wood")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.5, 1.5]:
			box(r, "Leg", Vector3(0.14, 0.12, 0.14), Vector3(x, 0.06, z), "wood")
	box(r, "Headboard", Vector3(2.2, 1.15, 0.14), Vector3(0, 0.6, -1.56), "wood")
	box(r, "Footboard", Vector3(2.2, 0.55, 0.1), Vector3(0, 0.4, 1.58), "wood")
	box(r, "Mattress", Vector3(2.0, 0.24, 3.0), Vector3(0, 0.54, 0), "fabric_white")
	box(r, "Blanket", Vector3(2.06, 0.26, 1.9), Vector3(0, 0.55, 0.52), "fabric_blue")
	box(r, "Fold", Vector3(2.06, 0.05, 0.3), Vector3(0, 0.7, -0.42), "fabric_white")
	box(r, "Pillow", Vector3(1.2, 0.16, 0.5), Vector3(0, 0.74, -1.1), "fabric_white")
	hit(r, Vector3(2.2, 0.8, 3.2), Vector3(0, 0.4, 0))
	save(r, "bed")

	r = solid("Nightstand")
	box(r, "Body", Vector3(0.6, 0.55, 0.55), Vector3(0, 0.275, 0), "wood")
	box(r, "Top", Vector3(0.66, 0.05, 0.6), Vector3(0, 0.575, 0), "wood_light")
	box(r, "Drawer", Vector3(0.48, 0.2, 0.02), Vector3(0, 0.36, 0.285), "wood_light")
	ball(r, "Knob", 0.03, Vector3(0, 0.36, 0.31), "brass")
	cyl(r, "LampBase", 0.06, 0.09, 0.22, Vector3(0, 0.71, 0), "terracotta")
	cyl(r, "LampShade", 0.1, 0.18, 0.2, Vector3(0, 0.9, 0), "lamp_shade")
	lamp(r, "Light", Vector3(0, 1.1, 0.1), Color(1.0, 0.8, 0.5), 1.4, 5.5)
	hit(r, Vector3(0.6, 0.6, 0.55), Vector3(0, 0.3, 0))
	save(r, "nightstand")

	r = solid("Fridge")
	box(r, "Feet", Vector3(0.9, 0.06, 0.85), Vector3(0, 0.03, 0), "dark")
	box(r, "Body", Vector3(0.95, 2.0, 0.9), Vector3(0, 1.06, 0), "enamel")
	box(r, "Seam", Vector3(0.96, 0.03, 0.02), Vector3(0, 1.5, 0.445), "gray")
	box(r, "HandleTop", Vector3(0.05, 0.28, 0.05), Vector3(0.36, 1.75, 0.47), "chrome")
	box(r, "HandleBottom", Vector3(0.05, 0.4, 0.05), Vector3(0.36, 1.2, 0.47), "chrome")
	box(r, "Magnet", Vector3(0.08, 0.08, 0.02), Vector3(-0.2, 1.8, 0.455), "tomato")
	box(r, "Magnet", Vector3(0.08, 0.08, 0.02), Vector3(-0.04, 1.7, 0.455), "yellow")
	box(r, "Note", Vector3(0.16, 0.2, 0.012), Vector3(-0.2, 1.15, 0.455), "cream")
	box(r, "Box", Vector3(0.45, 0.16, 0.35), Vector3(0.1, 2.14, 0), "crate")
	hit(r, Vector3(0.95, 2.1, 0.9), Vector3(0, 1.05, 0))
	save(r, "fridge")

	r = solid("Stove")
	box(r, "Feet", Vector3(0.8, 0.06, 0.7), Vector3(0, 0.03, 0), "dark")
	box(r, "Body", Vector3(0.85, 0.82, 0.75), Vector3(0, 0.47, 0), "enamel")
	box(r, "Top", Vector3(0.87, 0.04, 0.77), Vector3(0, 0.9, 0), "dark")
	for x: float in [-0.2, 0.2]:
		for z: float in [-0.17, 0.17]:
			cyl(r, "Burner", 0.12, 0.12, 0.03, Vector3(x, 0.93, z), "gray")
	box(r, "Oven", Vector3(0.6, 0.4, 0.02), Vector3(0, 0.42, 0.38), "glass_dark")
	box(r, "OvenHandle", Vector3(0.6, 0.04, 0.04), Vector3(0, 0.68, 0.4), "chrome")
	for i in 4:
		cyl(r, "Knob", 0.035, 0.035, 0.03, Vector3(-0.27 + i * 0.18, 0.81, 0.385), "dark", Vector3(90, 0, 0))
	box(r, "Back", Vector3(0.87, 0.22, 0.05), Vector3(0, 1.03, -0.36), "enamel")
	cyl(r, "Pot", 0.14, 0.14, 0.15, Vector3(-0.2, 1.01, -0.17), "gray")
	cyl(r, "PotLid", 0.03, 0.15, 0.04, Vector3(-0.2, 1.1, -0.17), "dark")
	# Botijão de gás ao lado.
	cyl(r, "GasBody", 0.2, 0.2, 0.46, Vector3(-0.78, 0.25, 0.05), "gas_blue")
	ball(r, "GasTop", 0.2, Vector3(-0.78, 0.48, 0.05), "gas_blue", Vector3(1, 0.55, 1))
	cyl(r, "GasNeck", 0.11, 0.11, 0.04, Vector3(-0.78, 0.64, 0.05), "gray")
	hit(r, Vector3(0.85, 1.0, 0.75), Vector3(0, 0.5, 0))
	hit(r, Vector3(0.42, 0.7, 0.42), Vector3(-0.78, 0.35, 0.05))
	save(r, "stove")

	r = solid("Counter")
	box(r, "Cabinet", Vector3(1.6, 0.8, 0.7), Vector3(0, 0.4, 0), "wood_light")
	box(r, "Gap", Vector3(0.03, 0.62, 0.02), Vector3(0, 0.4, 0.35), "wood")
	for x: float in [-0.12, 0.12]:
		ball(r, "Knob", 0.03, Vector3(x, 0.5, 0.37), "brass")
	box(r, "Top", Vector3(1.66, 0.07, 0.76), Vector3(0, 0.835, 0), "stone")
	box(r, "Sink", Vector3(0.6, 0.02, 0.45), Vector3(-0.38, 0.875, 0.02), "dark")
	cyl(r, "Tap", 0.025, 0.025, 0.26, Vector3(-0.38, 1.0, -0.3), "chrome")
	box(r, "Spout", Vector3(0.035, 0.035, 0.2), Vector3(-0.38, 1.12, -0.21), "chrome")
	cyl(r, "Plates", 0.14, 0.1, 0.06, Vector3(0.3, 0.9, 0.05), "cream")
	cyl(r, "Cup", 0.05, 0.04, 0.1, Vector3(0.62, 0.92, -0.15), "tomato")
	hit(r, Vector3(1.6, 0.9, 0.7), Vector3(0, 0.45, 0))
	save(r, "counter")

	r = solid("Sofa")
	for x: float in [-1.1, 1.1]:
		for z: float in [-0.35, 0.4]:
			box(r, "Foot", Vector3(0.1, 0.1, 0.1), Vector3(x, 0.05, z), "wood")
	box(r, "Seat", Vector3(2.5, 0.42, 0.95), Vector3(0, 0.3, 0.05), "fabric_red")
	box(r, "Back", Vector3(2.5, 0.85, 0.25), Vector3(0, 0.62, -0.38), "fabric_red")
	for x: float in [-1.2, 1.2]:
		box(r, "Arm", Vector3(0.25, 0.68, 1.0), Vector3(x, 0.43, 0.02), "fabric_red_dark")
	for x: float in [-0.52, 0.52]:
		box(r, "Cushion", Vector3(1.0, 0.1, 0.62), Vector3(x, 0.55, 0.12), "fabric_red_dark")
	box(r, "Pillow", Vector3(0.4, 0.4, 0.12), Vector3(-0.8, 0.76, -0.16), "fabric_yellow", Vector3(-15, 0, 10))
	hit(r, Vector3(2.65, 0.9, 1.0), Vector3(0, 0.45, 0))
	save(r, "sofa")

	r = solid("Tv")
	box(r, "Stand", Vector3(1.4, 0.5, 0.6), Vector3(0, 0.31, 0), "wood")
	for x: float in [-0.6, 0.6]:
		box(r, "Leg", Vector3(0.08, 0.07, 0.5), Vector3(x, 0.035, 0), "wood")
		box(r, "StandDoor", Vector3(0.54, 0.34, 0.02), Vector3(x * 0.52, 0.31, 0.305), "wood_light")
	box(r, "Body", Vector3(0.95, 0.72, 0.6), Vector3(0, 0.93, 0), "plastic_dark")
	box(r, "Screen", Vector3(0.62, 0.5, 0.02), Vector3(-0.11, 0.95, 0.305), "tv_screen")
	box(r, "Panel", Vector3(0.16, 0.5, 0.02), Vector3(0.33, 0.95, 0.305), "gray")
	for y: float in [1.08, 0.93]:
		cyl(r, "Dial", 0.045, 0.045, 0.03, Vector3(0.33, y, 0.325), "dark", Vector3(90, 0, 0))
	box(r, "AntennaBase", Vector3(0.14, 0.04, 0.1), Vector3(0, 1.31, 0), "dark")
	cyl(r, "Antenna", 0.012, 0.012, 0.6, Vector3(-0.13, 1.58, 0), "chrome", Vector3(0, 0, 25))
	cyl(r, "Antenna", 0.012, 0.012, 0.6, Vector3(0.13, 1.58, 0), "chrome", Vector3(0, 0, -25))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.6, 0.8, 1.0)
	glow.omni_range = 3.5
	_place(r, glow, "Glow", Vector3(-0.1, 0.95, 0.8), Vector3.ZERO)
	attach(glow, COMPONENTS + "flicker_light.gd", {"base_energy": 0.45, "amount": 0.2})
	hit(r, Vector3(1.4, 1.3, 0.6), Vector3(0, 0.65, 0))
	save(r, "tv")

	r = solid("PhoneTable")
	box(r, "Top", Vector3(0.75, 0.05, 0.6), Vector3(0, 0.72, 0), "wood")
	for x: float in [-0.32, 0.32]:
		for z: float in [-0.25, 0.25]:
			box(r, "Leg", Vector3(0.06, 0.7, 0.06), Vector3(x, 0.35, z), "wood")
	box(r, "Shelf", Vector3(0.7, 0.04, 0.55), Vector3(0, 0.25, 0), "wood")
	box(r, "PhoneBook", Vector3(0.3, 0.07, 0.4), Vector3(0, 0.305, 0), "yellow")
	cyl(r, "Doily", 0.27, 0.27, 0.012, Vector3(0, 0.752, 0), "cream")
	box(r, "PhoneBase", Vector3(0.34, 0.09, 0.26), Vector3(0, 0.81, 0), "phone_red", Vector3(12, 0, 0))
	cyl(r, "PhoneDial", 0.07, 0.07, 0.02, Vector3(0, 0.86, 0.06), "cream", Vector3(12, 0, 0))
	box(r, "Handset", Vector3(0.42, 0.055, 0.08), Vector3(0, 0.915, -0.07), "phone_red")
	for x: float in [-0.17, 0.17]:
		box(r, "HandsetCup", Vector3(0.09, 0.08, 0.1), Vector3(x, 0.885, -0.07), "phone_red")
	hit(r, Vector3(0.75, 0.9, 0.6), Vector3(0, 0.45, 0))
	save(r, "phone_table")

	r = solid("DiningTable")
	box(r, "Cloth", Vector3(1.34, 0.2, 0.89), Vector3(0, 0.7, 0), "gingham")
	for x: float in [-0.55, 0.55]:
		for z: float in [-0.33, 0.33]:
			box(r, "Leg", Vector3(0.07, 0.62, 0.07), Vector3(x, 0.31, z), "wood")
	cyl(r, "Bowl", 0.2, 0.12, 0.08, Vector3(0, 0.84, 0), "terracotta")
	ball(r, "Orange", 0.07, Vector3(-0.06, 0.92, 0), "orange")
	ball(r, "Tomato", 0.07, Vector3(0.07, 0.92, 0.04), "tomato")
	ball(r, "Lemon", 0.07, Vector3(0, 0.93, -0.07), "yellow")
	for pos: Vector3 in [Vector3(0.25, 0, 0.82), Vector3(1.02, 0, 0.1)]:
		var stool := node(r, "Stool", pos)
		cyl(stool, "Seat", 0.2, 0.2, 0.05, Vector3(0, 0.46, 0), "wood_light")
		cyl(stool, "Leg", 0.05, 0.08, 0.44, Vector3(0, 0.22, 0), "wood")
		hit(r, Vector3(0.36, 0.48, 0.36), pos + Vector3(0, 0.24, 0))
	hit(r, Vector3(1.34, 0.8, 0.89), Vector3(0, 0.4, 0))
	save(r, "dining_table")

	# Espada-de-são-jorge no vaso.
	r = solid("PottedPlant")
	cyl(r, "Pot", 0.24, 0.17, 0.34, Vector3(0, 0.17, 0), "terracotta")
	cyl(r, "Soil", 0.22, 0.22, 0.02, Vector3(0, 0.34, 0), "dark")
	for i in 7:
		var h := 0.5 + (i * 37 % 5) * 0.09
		var pivot := node(r, "Leaf", Vector3(0, 0.34, 0), Vector3(0, i * 51.4, 0))
		box(pivot, "Blade", Vector3(0.1, h, 0.03), Vector3(0.07 + h * 0.1, h * 0.5, 0), "leaf_dark" if i % 2 == 0 else "crop_leaf", Vector3(0, 0, -12))
	hit(r, Vector3(0.45, 0.9, 0.45), Vector3(0, 0.45, 0))
	save(r, "potted_plant")

	r = solid("FloorFan")
	cyl(r, "Base", 0.24, 0.27, 0.05, Vector3(0, 0.025, 0), "gray")
	cyl(r, "Pole", 0.03, 0.03, 1.15, Vector3(0, 0.6, 0), "chrome")
	cyl(r, "Motor", 0.09, 0.09, 0.2, Vector3(0, 1.25, -0.08), "gray", Vector3(90, 0, 0))
	cyl(r, "Cage", 0.33, 0.33, 0.1, Vector3(0, 1.25, 0.08), "cage", Vector3(90, 0, 0), 12)
	var blades := node(r, "Blades", Vector3(0, 1.25, 0.08))
	attach(blades, COMPONENTS + "spinner.gd", {"axis": Vector3(0, 0, 1), "speed": 14.0})
	for i in 3:
		var pivot := node(blades, "Blade", Vector3.ZERO, Vector3(0, 0, i * 120.0))
		box(pivot, "Mesh", Vector3(0.26, 0.11, 0.015), Vector3(0.15, 0, 0), "blade")
	hit(r, Vector3(0.4, 1.5, 0.4), Vector3(0, 0.75, 0))
	save(r, "floor_fan")

	r = solid("FloorLamp")
	cyl(r, "Base", 0.16, 0.2, 0.05, Vector3(0, 0.025, 0), "dark")
	cyl(r, "Pole", 0.025, 0.025, 1.45, Vector3(0, 0.75, 0), "brass")
	cyl(r, "Shade", 0.16, 0.27, 0.32, Vector3(0, 1.6, 0), "lamp_shade")
	lamp(r, "Light", Vector3(0, 1.75, 0), Color(1.0, 0.82, 0.55), 2.0, 8.0)
	hit(r, Vector3(0.3, 1.7, 0.3), Vector3(0, 0.85, 0))
	save(r, "floor_lamp")

	var rug := Node3D.new()
	rug.name = "Rug"
	quad(rug, "Mesh", Vector2(3.0, 2.0), Vector3(0, 0.015, 0), "rug", Vector3(-90, 0, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	save(rug, "rug")


# === peças de parede ========================================================

func wall_props() -> void:
	var r := solid("Door")
	for x: float in [-0.56, 0.56]:
		box(r, "Post", Vector3(0.12, 2.2, 0.22), Vector3(x, 1.1, 0), "wood_light")
	box(r, "Lintel", Vector3(1.24, 0.12, 0.22), Vector3(0, 2.26, 0), "wood_light")
	box(r, "Leaf", Vector3(1.0, 2.14, 0.06), Vector3(0, 1.07, 0), "wood")
	quad(r, "Front", Vector2(1.0, 2.14), Vector3(0, 1.07, 0.035), "door")
	quad(r, "Back", Vector2(1.0, 2.14), Vector3(0, 1.07, -0.035), "door", Vector3(0, 180, 0))
	hit(r, Vector3(1.24, 2.3, 0.22), Vector3(0, 1.15, 0))
	save(r, "door")

	var w := Node3D.new()
	w.name = "Window"
	_window(w)
	save(w, "window")

	# Janela de fachada: venezianas verdes e floreira.
	w = Node3D.new()
	w.name = "WindowShutters"
	_window(w)
	for x: float in [-0.93, 0.93]:
		box(w, "Shutter", Vector3(0.52, 1.1, 0.05), Vector3(x, 0, 0.04), "shutter")
	box(w, "FlowerBox", Vector3(1.2, 0.18, 0.2), Vector3(0, -0.74, 0.14), "terracotta")
	var flowers := ["pink", "yellow", "white", "pink", "tomato"]
	for i in 5:
		ball(w, "Flower", 0.07, Vector3(-0.44 + i * 0.22, -0.6 + (i % 2) * 0.04, 0.14), flowers[i])
		ball(w, "Leaf", 0.08, Vector3(-0.33 + i * 0.22, -0.64, 0.12), "crop_leaf")
	save(w, "window_shutters")

	w = Node3D.new()
	w.name = "Picture"
	box(w, "Frame", Vector3(0.8, 0.6, 0.04), Vector3.ZERO, "wood")
	quad(w, "Canvas", Vector2(0.72, 0.54), Vector3(0, 0, 0.025), "picture")
	save(w, "picture")

	w = Node3D.new()
	w.name = "WallClock"
	quad(w, "Face", Vector2(0.5, 0.5), Vector3(0, 0, 0.02), "clock")
	save(w, "wall_clock")

	w = Node3D.new()
	w.name = "WallLamp"
	box(w, "Bracket", Vector3(0.08, 0.08, 0.22), Vector3(0, 0, 0.11), "dark")
	cyl(w, "Shade", 0.08, 0.16, 0.16, Vector3(0, -0.02, 0.24), "lamp_shade")
	lamp(w, "Light", Vector3(0, -0.2, 0.5), Color(1.0, 0.82, 0.5), 2.2, 8.0)
	save(w, "wall_lamp")


func _window(w: Node3D) -> void:
	box(w, "Frame", Vector3(1.3, 1.1, 0.08), Vector3.ZERO, "wood_light")
	quad(w, "Glass", Vector2(1.14, 0.94), Vector3(0, 0, 0.045), "window")
	box(w, "Sill", Vector3(1.4, 0.06, 0.16), Vector3(0, -0.57, 0.05), "wood_light")


# === quintal e rua ==========================================================

func yard_props() -> void:
	# Cerca de ripas: módulo de 4 m ao longo de X.
	var r := solid("Fence")
	for x: float in [-1.94, 1.94]:
		box(r, "Post", Vector3(0.12, 1.0, 0.12), Vector3(x, 0.5, -0.03), "wood")
	for y: float in [0.32, 0.72]:
		box(r, "Rail", Vector3(4.0, 0.07, 0.04), Vector3(0, y, -0.03), "wood")
	for i in 10:
		var x := -1.8 + i * 0.4
		box(r, "Picket", Vector3(0.2, 0.84, 0.035), Vector3(x, 0.45, 0.02), "wood_light")
		box(r, "Tip", Vector3(0.11, 0.08, 0.035), Vector3(x, 0.91, 0.02), "wood_light")
	hit(r, Vector3(4.0, 1.0, 0.16), Vector3(0, 0.5, 0))
	save(r, "fence")

	# Coqueiro.
	r = solid("Palm")
	var top := Vector3.ZERO
	for i in 5:
		top = Vector3(0.06 * i * i * 0.5, 0.36 + i * 0.7, 0)
		cyl(r, "Trunk", 0.15 - i * 0.008, 0.19 - i * 0.008, 0.76, top, "bark", Vector3(0, 0, -4.0 * i))
	var crown := node(r, "Crown", top + Vector3(0.05, 0.4, 0))
	attach(crown, COMPONENTS + "sway.gd", {"axis": Vector3(0, 0, 1), "degrees": 2.5, "speed": 0.9})
	for i in 7:
		var pivot := node(crown, "Frond", Vector3.ZERO, Vector3(0, i * 51.4, 0))
		box(pivot, "Inner", Vector3(1.3, 0.05, 0.42), Vector3(0.65, 0.13, 0), "palm_leaf", Vector3(0, 0, 12))
		box(pivot, "Outer", Vector3(1.05, 0.05, 0.32), Vector3(1.72, 0.03, 0), "leaves", Vector3(0, 0, -28))
	for i in 3:
		ball(crown, "Coconut", 0.12, Vector3(cos(i * 2.1) * 0.17, -0.14, sin(i * 2.1) * 0.17), "coconut")
	hit(r, Vector3(0.4, 3.4, 0.4), Vector3(0.2, 1.7, 0))
	save(r, "palm")

	# Mangueira.
	r = solid("Tree")
	cyl(r, "Trunk", 0.2, 0.3, 1.8, Vector3(0, 0.9, 0), "bark")
	cyl(r, "Branch", 0.08, 0.12, 0.9, Vector3(0.35, 1.7, 0.1), "bark", Vector3(0, 0, -50))
	var canopy := node(r, "Canopy", Vector3(0, 2.7, 0))
	attach(canopy, COMPONENTS + "sway.gd", {"axis": Vector3(0, 0, 1), "degrees": 1.5, "speed": 0.8})
	ball(canopy, "Leaves", 1.15, Vector3(0, 0, 0), "leaves", Vector3(1, 0.8, 1))
	ball(canopy, "Leaves", 0.85, Vector3(0.8, -0.15, 0.3), "leaves_light")
	ball(canopy, "Leaves", 0.8, Vector3(-0.75, -0.1, -0.2), "leaves")
	ball(canopy, "Leaves", 0.7, Vector3(0.1, 0.55, -0.3), "leaves_light")
	for pos: Vector3 in [Vector3(0.9, -0.85, 0.6), Vector3(0.3, -0.85, 0.85), Vector3(-0.6, -0.75, 0.45), Vector3(1.25, -0.7, 0.0), Vector3(-0.95, -0.7, -0.5)]:
		ball(canopy, "Mango", 0.09, pos, "mango", Vector3(1, 1.3, 1))
	hit(r, Vector3(0.5, 2.0, 0.5), Vector3(0, 1.0, 0))
	save(r, "tree")

	var d := Node3D.new()
	d.name = "Bush"
	ball(d, "Leaves", 0.45, Vector3(0, 0.3, 0), "leaves", Vector3(1, 0.8, 1))
	ball(d, "Leaves", 0.34, Vector3(0.4, 0.24, 0.1), "leaves_light")
	ball(d, "Leaves", 0.3, Vector3(-0.38, 0.2, -0.05), "leaves")
	save(d, "bush")

	d = Node3D.new()
	d.name = "Flowers"
	var petals := ["pink", "yellow", "white", "tomato", "pink", "yellow"]
	for i in 6:
		var pos := Vector3(cos(i * 1.9) * 0.3, 0, sin(i * 1.9) * 0.22)
		box(d, "Stem", Vector3(0.025, 0.26, 0.025), pos + Vector3(0, 0.13, 0), "crop_leaf")
		box(d, "Petal", Vector3(0.1, 0.09, 0.1), pos + Vector3(0, 0.3, 0), petals[i])
	save(d, "flowers")

	d = Node3D.new()
	d.name = "Rock"
	ball(d, "Big", 0.3, Vector3(0, 0.12, 0), "stone", Vector3(1.2, 0.6, 1))
	ball(d, "Small", 0.16, Vector3(0.36, 0.06, 0.12), "gray", Vector3(1.1, 0.6, 1))
	save(d, "rock")

	# Varal com roupa balançando.
	r = solid("Clothesline")
	for x: float in [-1.8, 1.8]:
		cyl(r, "Pole", 0.045, 0.045, 1.9, Vector3(x, 0.95, 0), "wood")
		box(r, "Crossbar", Vector3(0.06, 0.05, 0.5), Vector3(x, 1.85, 0), "wood")
		hit(r, Vector3(0.16, 1.9, 0.16), Vector3(x, 0.95, 0))
	box(r, "Line", Vector3(3.6, 0.015, 0.015), Vector3(0, 1.82, 0), "cream")
	var clothes := [[-1.2, 0.55, 0.6, "yellow"], [-0.45, 0.6, 0.85, "cloth_blue"], [0.3, 0.42, 0.36, "cloth_red"], [1.1, 0.85, 0.9, "fabric_white"]]
	for c: Array in clothes:
		var pivot := node(r, "Cloth", Vector3(c[0], 1.82, 0))
		attach(pivot, COMPONENTS + "sway.gd", {"axis": Vector3(1, 0, 0), "degrees": 7.0, "speed": 1.6})
		box(pivot, "Mesh", Vector3(c[1], c[2], 0.03), Vector3(0, -c[2] * 0.5, 0), c[3])
		for x: float in [-0.3, 0.3]:
			box(pivot, "Peg", Vector3(0.03, 0.07, 0.04), Vector3(c[1] * x, 0.01, 0), "wood_light")
	save(r, "clothesline")

	# Torneira, balde e regador.
	r = solid("WaterTap")
	box(r, "Post", Vector3(0.12, 0.9, 0.12), Vector3(0, 0.45, 0), "stone")
	cyl(r, "Tap", 0.03, 0.03, 0.18, Vector3(0, 0.8, 0.12), "chrome", Vector3(90, 0, 0))
	box(r, "Handle", Vector3(0.12, 0.03, 0.03), Vector3(0, 0.87, 0.1), "tomato")
	cyl(r, "Puddle", 0.3, 0.3, 0.012, Vector3(0.05, 0.008, 0.35), "water")
	cyl(r, "Bucket", 0.17, 0.13, 0.26, Vector3(-0.4, 0.13, 0.25), "gray")
	cyl(r, "BucketWater", 0.15, 0.15, 0.02, Vector3(-0.4, 0.24, 0.25), "water")
	var can := node(r, "WateringCan", Vector3(0.5, 0, 0.2), Vector3(0, -30, 0))
	cyl(can, "Body", 0.15, 0.17, 0.3, Vector3(0, 0.15, 0), "can_green")
	cyl(can, "Spout", 0.03, 0.04, 0.36, Vector3(0.26, 0.26, 0), "can_green", Vector3(0, 0, -55))
	cyl(can, "Rose", 0.07, 0.03, 0.05, Vector3(0.42, 0.37, 0), "can_green", Vector3(0, 0, -55))
	box(can, "Handle", Vector3(0.04, 0.26, 0.03), Vector3(-0.2, 0.2, 0), "can_green")
	box(can, "Grip", Vector3(0.24, 0.03, 0.03), Vector3(-0.08, 0.34, 0), "can_green")
	hit(r, Vector3(0.2, 0.9, 0.2), Vector3(0, 0.45, 0))
	save(r, "water_tap")

	# Vira-lata caramelo deitado, abanando o rabo.
	d = Node3D.new()
	d.name = "Dog"
	box(d, "Body", Vector3(0.3, 0.28, 0.62), Vector3(0, 0.2, 0), "caramel")
	box(d, "Head", Vector3(0.24, 0.22, 0.24), Vector3(0, 0.4, 0.36), "caramel")
	box(d, "Snout", Vector3(0.13, 0.1, 0.14), Vector3(0, 0.35, 0.52), "caramel_light")
	box(d, "Nose", Vector3(0.05, 0.04, 0.03), Vector3(0, 0.39, 0.595), "dark")
	for x: float in [-1.0, 1.0]:
		box(d, "Ear", Vector3(0.07, 0.13, 0.04), Vector3(x * 0.1, 0.52, 0.3), "caramel_dark", Vector3(0, 0, x * -15))
		box(d, "Eye", Vector3(0.035, 0.04, 0.02), Vector3(x * 0.065, 0.44, 0.485), "dark")
		box(d, "FrontPaw", Vector3(0.09, 0.08, 0.26), Vector3(x * 0.1, 0.04, 0.42), "caramel_light")
		box(d, "HindLeg", Vector3(0.1, 0.14, 0.24), Vector3(x * 0.16, 0.07, -0.2), "caramel_dark")
	var tail := node(d, "Tail", Vector3(0, 0.28, -0.3))
	attach(tail, COMPONENTS + "sway.gd", {"axis": Vector3(0, 1, 0), "degrees": 32.0, "speed": 9.0})
	box(tail, "Mesh", Vector3(0.05, 0.05, 0.28), Vector3(0, 0.06, -0.12), "caramel", Vector3(30, 0, 0))
	area(d, "Pet", Vector3(1.2, 1.2, 1.4), Vector3(0, 0.5, 0.1), "Fazer carinho no Caramelo")
	save(d, "dog")

	# Poste de luz da rua.
	r = solid("LampPost")
	cyl(r, "Foot", 0.12, 0.16, 0.3, Vector3(0, 0.15, 0), "lamp_green")
	cyl(r, "Pole", 0.05, 0.07, 3.3, Vector3(0, 1.8, 0), "lamp_green")
	box(r, "Arm", Vector3(0.06, 0.06, 0.7), Vector3(0, 3.4, 0.3), "lamp_green")
	cyl(r, "Shade", 0.08, 0.2, 0.16, Vector3(0, 3.33, 0.62), "lamp_green")
	ball(r, "Bulb", 0.1, Vector3(0, 3.24, 0.62), "lamp_shade")
	lamp(r, "Light", Vector3(0, 3.0, 0.8), Color(1.0, 0.84, 0.55), 3.0, 11.0)
	hit(r, Vector3(0.3, 3.4, 0.3), Vector3(0, 1.7, 0))
	save(r, "lamp_post")


# === canteiro e culturas ====================================================

func garden_plot() -> void:
	var r := Node3D.new()
	r.name = "GardenPlot"
	attach(r, PROPS + "garden_plot.gd")
	box(r, "Soil", Vector3(1.5, 0.16, 1.5), Vector3(0, 0.1, 0), "soil")
	for z: float in [-0.8, 0.8]:
		box(r, "Border", Vector3(1.7, 0.22, 0.1), Vector3(0, 0.11, z), "wood")
	for x: float in [-0.8, 0.8]:
		box(r, "Border", Vector3(0.1, 0.22, 1.5), Vector3(x, 0.11, 0), "wood")
	node(r, "PlantSlot", Vector3(0, 0.18, 0))
	area(r, "Interactable", Vector3(1.6, 1.5, 1.6), Vector3(0, 0.75, 0), "Plantar")
	save(r, "garden_plot")


## Cada cultura tem um nó "Ripe" que só aparece na hora da colheita.
func crops() -> void:
	var r := Node3D.new()
	r.name = "Tomate"
	box(r, "Stake", Vector3(0.04, 1.15, 0.04), Vector3(0.02, 0.57, -0.06), "wood_light")
	ball(r, "Bush", 0.3, Vector3(0, 0.32, 0), "crop_leaf")
	ball(r, "Bush", 0.26, Vector3(0.05, 0.66, 0.02), "leaf_dark")
	ball(r, "Bush", 0.18, Vector3(0, 0.94, 0), "crop_leaf")
	var ripe := node(r, "Ripe")
	for pos: Vector3 in [Vector3(0.26, 0.4, 0.1), Vector3(-0.22, 0.5, 0.16), Vector3(0.12, 0.75, 0.22), Vector3(-0.1, 0.3, 0.27), Vector3(0.25, 0.7, -0.06), Vector3(-0.2, 0.85, 0.05)]:
		ball(ripe, "Tomato", 0.085, pos, "tomato")
	save(r, "tomate", PROPS + "crops/")

	r = Node3D.new()
	r.name = "Alface"
	ripe = node(r, "Ripe")
	for x: float in [-0.35, 0.35]:
		for z: float in [-0.35, 0.35]:
			ball(r, "Head", 0.2, Vector3(x, 0.08, z), "lettuce", Vector3(1, 0.6, 1))
			ball(r, "Heart", 0.12, Vector3(x, 0.16, z), "lettuce_light", Vector3(1, 0.7, 1))
			for i in 4:
				var pivot := node(ripe, "Leaf", Vector3(x, 0.08, z), Vector3(0, i * 90.0 + 45.0, 0))
				box(pivot, "Mesh", Vector3(0.2, 0.03, 0.2), Vector3(0.2, 0.06, 0), "lettuce_light", Vector3(0, 0, 30))
	save(r, "alface", PROPS + "crops/")

	r = Node3D.new()
	r.name = "Mandioca"
	var stem := 0
	for base: Vector3 in [Vector3(0, 0, 0), Vector3(0.3, 0, 0.18), Vector3(-0.26, 0, -0.16)]:
		var h := 1.05 - stem * 0.14
		cyl(r, "Stem", 0.025, 0.035, h, base + Vector3(0, h * 0.5, 0), "cassava_stem")
		for level in 2:
			var whorl := node(r, "Whorl", base + Vector3(0, h - level * 0.28, 0), Vector3(0, stem * 40.0 + level * 36.0, 0))
			for k in 5:
				var pivot := node(whorl, "Leaf", Vector3.ZERO, Vector3(0, k * 72.0, 0))
				box(pivot, "Mesh", Vector3(0.32, 0.015, 0.08), Vector3(0.18, -0.03, 0), "crop_leaf" if level == 0 else "leaf_dark", Vector3(0, 0, -15))
		stem += 1
	ripe = node(r, "Ripe")
	for k in 4:
		cyl(ripe, "Root", 0.035, 0.07, 0.34, Vector3(cos(k * 1.7) * 0.2, 0.05, sin(k * 1.7) * 0.2), "cassava", Vector3(0, -k * 97.0, 72))
	save(r, "mandioca", PROPS + "crops/")

	# Broto genérico para culturas novas sem modelo próprio.
	r = Node3D.new()
	r.name = "Generic"
	cyl(r, "Plant", 0.1, 0.28, 0.9, Vector3(0, 0.45, 0), "crop_leaf", Vector3.ZERO, 6)
	ripe = node(r, "Ripe")
	ball(ripe, "Fruit", 0.24, Vector3(0, 1.05, 0), "white")
	save(r, "generic", PROPS + "crops/")


# === caminhonete ============================================================

## Picape anos 90 com carroceria de madeira. Frente para +X.
func truck() -> void:
	var r := Node3D.new()
	r.name = "Truck"
	attach(r, PROPS + "truck.gd")
	box(r, "Chassis", Vector3(4.5, 0.18, 1.6), Vector3(0, 0.42, 0), "dark")
	box(r, "CabLower", Vector3(1.5, 0.7, 1.9), Vector3(0.85, 0.86, 0), "truck_red")
	box(r, "Hood", Vector3(0.72, 0.5, 1.84), Vector3(1.94, 0.78, 0), "truck_red")
	box(r, "CabTop", Vector3(1.25, 0.56, 1.76), Vector3(0.78, 1.49, 0), "truck_red")
	box(r, "Roof", Vector3(1.33, 0.06, 1.84), Vector3(0.78, 1.8, 0), "cream")
	box(r, "Windshield", Vector3(0.04, 0.42, 1.5), Vector3(1.42, 1.5, 0), "glass")
	box(r, "RearWindow", Vector3(0.04, 0.36, 1.3), Vector3(0.14, 1.5, 0), "glass")
	for z: float in [-1.0, 1.0]:
		box(r, "SideWindow", Vector3(0.85, 0.4, 0.04), Vector3(0.8, 1.5, z * 0.885), "glass")
		box(r, "Stripe", Vector3(1.5, 0.08, 0.02), Vector3(0.85, 0.95, z * 0.955), "cream")
		box(r, "DoorGap", Vector3(0.03, 0.62, 0.02), Vector3(0.2, 0.9, z * 0.955), "truck_red_dark")
		box(r, "DoorHandle", Vector3(0.12, 0.04, 0.03), Vector3(0.42, 1.1, z * 0.96), "chrome")
		box(r, "Headlight", Vector3(0.05, 0.16, 0.22), Vector3(2.31, 0.84, z * 0.72), "headlight")
		box(r, "Taillight", Vector3(0.03, 0.12, 0.14), Vector3(-2.45, 0.8, z * 0.75), "taillight")
		box(r, "BedSide", Vector3(2.5, 0.42, 0.08), Vector3(-1.15, 0.86, z * 0.88), "truck_red")
		for x: float in [-2.3, -1.2, -0.1]:
			box(r, "RailPost", Vector3(0.06, 0.62, 0.06), Vector3(x, 1.37, z * 0.88), "wood_light")
		for y: float in [1.33, 1.6]:
			box(r, "Rail", Vector3(2.3, 0.1, 0.04), Vector3(-1.2, y, z * 0.88), "wood_light")
		for x: float in [1.7, -1.5]:
			cyl(r, "Tire", 0.38, 0.38, 0.26, Vector3(x, 0.38, z * 0.86), "tire", Vector3(90, 0, 0), 10)
			cyl(r, "Hub", 0.17, 0.17, 0.28, Vector3(x, 0.38, z * 0.86), "chrome", Vector3(90, 0, 0))
	box(r, "Grille", Vector3(0.04, 0.26, 1.2), Vector3(2.31, 0.8, 0), "dark")
	box(r, "Bumper", Vector3(0.14, 0.16, 1.96), Vector3(2.34, 0.5, 0), "chrome")
	box(r, "RearBumper", Vector3(0.1, 0.12, 1.9), Vector3(-2.46, 0.48, 0), "chrome")
	box(r, "BedFloor", Vector3(2.5, 0.1, 1.84), Vector3(-1.15, 0.6, 0), "truck_red_dark")
	box(r, "Tailgate", Vector3(0.08, 0.42, 1.84), Vector3(-2.4, 0.86, 0), "truck_red")
	box(r, "BedFront", Vector3(0.08, 0.42, 1.84), Vector3(0.06, 0.86, 0), "truck_red")

	var cargo := node(r, "Cargo", Vector3(-1.15, 0.65, 0))
	var produce := ["tomato", "lettuce", "cassava", "lettuce", "tomato", "orange"]
	var n := 0
	for x: float in [-0.78, 0.0, 0.78]:
		for z: float in [-0.42, 0.42]:
			var c := node(cargo, "Crate", Vector3(x, 0, z))
			box(c, "Box", Vector3(0.68, 0.4, 0.72), Vector3(0, 0.2, 0), "crate")
			for k in 4:
				ball(c, "Produce", 0.12, Vector3(-0.16 + (k % 2) * 0.32, 0.42, -0.17 + (k / 2) * 0.34), produce[n])
			n += 1

	var body := solid("Body")
	r.add_child(body)
	hit(body, Vector3(4.9, 1.2, 1.95), Vector3(-0.05, 0.75, 0))
	hit(body, Vector3(1.3, 0.7, 1.8), Vector3(0.78, 1.5, 0))
	area(r, "CargoBed", Vector3(1.4, 1.8, 2.4), Vector3(-2.9, 0.9, 0), "Caçamba")
	area(r, "DriverDoor", Vector3(1.8, 1.8, 1.2), Vector3(0.9, 0.9, 1.55), "Porta do piloto")
	save(r, "truck")


# === feira ==================================================================

## Barraca de feira. Com `goods`, vem com mercadoria e um feirante (vizinhas);
## sem, traz a vitrine que mostra o estoque do jogador.
func stall(file: String, awning: String, goods: bool) -> void:
	var r := solid("Stall")
	box(r, "Counter", Vector3(3.0, 0.86, 1.0), Vector3(0, 0.43, 0.3), "wood")
	box(r, "CounterTop", Vector3(3.1, 0.08, 1.1), Vector3(0, 0.9, 0.3), "wood_light")
	box(r, "Skirt", Vector3(3.02, 0.5, 0.02), Vector3(0, 0.6, 0.812), awning)
	for x: float in [-1.6, 1.6]:
		for z: float in [-1.0, 1.0]:
			cyl(r, "Pole", 0.05, 0.05, 2.5, Vector3(x, 1.25, z), "pole")
	var roof := node(r, "Awning", Vector3(0, 2.5, 0), Vector3(8, 0, 0))
	box(roof, "Cloth", Vector3(3.7, 0.08, 2.5), Vector3.ZERO, awning)
	box(roof, "Valance", Vector3(3.7, 0.28, 0.04), Vector3(0, -0.14, 1.25), awning)
	for x: float in [-1.05, -0.35, 0.35, 1.05]:
		box(r, "Crate", Vector3(0.62, 0.16, 0.5), Vector3(x, 1.02, 0.3), "crate")
	if goods:
		var kinds := ["yellow", "orange", "lettuce", "tomato"]
		for i in 4:
			for k in 8:
				var pos := Vector3(-1.05 + i * 0.7 - 0.2 + (k % 4) * 0.135, 1.14 + (k / 4) * 0.03, 0.21 + (k / 4) * 0.17)
				ball(r, "Produce", 0.085, pos, kinds[i], Vector3(1.5, 0.7, 0.8) if kinds[i] == "yellow" else Vector3.ONE)
		var seller: Node3D = load("res://scenes/characters/humanoid.tscn").instantiate()
		seller.set("shirt", Color(0.95, 0.95, 0.9))
		seller.set("pants", Color(0.3, 0.3, 0.36))
		seller.set("skin", Color(0.68, 0.46, 0.32) if awning == "stripes_blue" else Color(0.96, 0.78, 0.62))
		seller.set("hair", Color(0.75, 0.74, 0.72) if awning == "stripes_blue" else Color(0.12, 0.09, 0.07))
		seller.set("hat", awning == "stripes_blue")
		_place(r, seller, "Seller", Vector3(0.3, 0, -0.6), Vector3.ZERO)
		box(r, "Sack", Vector3(0.5, 0.6, 0.45), Vector3(-1.1, 0.3, -0.7), "fabric_yellow")
	else:
		var display := node(r, "Display", Vector3(0, 1.12, 0.3))
		attach(display, PROPS + "stall_display.gd")
	hit(r, Vector3(3.0, 1.0, 1.0), Vector3(0, 0.5, 0.3))
	save(r, file)
