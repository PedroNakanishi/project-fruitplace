extends SceneTree
## Gera as texturas pixeladas (16 px por metro) em res://assets/textures.
## Uso: Godot --headless --path . -s tools/gen_textures.gd
## São PNGs comuns: dá para repintar à mão em qualquer editor de pixel art
## (mantendo nome e tamanho) sem precisar rodar este script de novo.

const OUT := "res://assets/textures/"

var rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	grass()
	soil("soil", Color(0.52, 0.35, 0.21))
	soil("soil_wet", Color(0.31, 0.2, 0.12))
	planks()
	wood("wood", Color(0.55, 0.36, 0.21))
	wood("wood_light", Color(0.8, 0.64, 0.42))
	plaster()
	paving()
	speckled("asphalt", 32, Color(0.27, 0.27, 0.31), 0.12, 0.1)
	speckled("gravel", 16, Color(0.7, 0.66, 0.59), 0.3, 0.22)
	speckled("leaves", 16, Color(0.25, 0.56, 0.25), 0.25, 0.16)
	tile()
	roof()
	stripes("stripes_orange", Color(0.98, 0.52, 0.14))
	stripes("stripes_blue", Color(0.25, 0.62, 0.85))
	stripes("stripes_pink", Color(0.93, 0.4, 0.58))
	rug()
	crate()
	bark()
	fabric()
	gingham()
	window()
	door()
	picture()
	clock()
	mood("mood_feliz", Color(1.0, 0.84, 0.2), 1)
	mood("mood_normal", Color(0.96, 0.92, 0.72), 0)
	mood("mood_triste", Color(0.48, 0.68, 1.0), -1)
	mood("mood_raiva", Color(0.96, 0.32, 0.26), -2)
	print("Texturas geradas em ", OUT)
	quit()


# --- utilitários -----------------------------------------------------------

func new_img(name: String, w: int, h: int, c: Color) -> Image:
	rng.seed = hash(name)
	var i := Image.create(w, h, false, Image.FORMAT_RGBA8)
	i.fill(c)
	return i


func put(i: Image, x: int, y: int, c: Color) -> void:
	i.set_pixel(posmod(x, i.get_width()), posmod(y, i.get_height()), c)


func rect(i: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in h:
		for xx in w:
			put(i, x + xx, y + yy, c)


func shade(c: Color, k: float) -> Color:
	return Color(clampf(c.r * k, 0, 1), clampf(c.g * k, 0, 1), clampf(c.b * k, 0, 1), c.a)


func speckle(i: Image, c: Color, density: float) -> void:
	for y in i.get_height():
		for x in i.get_width():
			if rng.randf() < density:
				i.set_pixel(x, y, c)


func save(i: Image, name: String) -> void:
	i.save_png(OUT + name + ".png")


# --- chão e paredes --------------------------------------------------------

func speckled(name: String, size: int, base: Color, dark: float, light: float) -> void:
	var i := new_img(name, size, size, base)
	speckle(i, shade(base, 0.8), dark)
	speckle(i, shade(base, 1.18), light)
	save(i, name)


func grass() -> void:
	var base := Color(0.37, 0.63, 0.28)
	var i := new_img("grass", 32, 32, base)
	speckle(i, Color(0.33, 0.58, 0.26), 0.2)
	speckle(i, Color(0.42, 0.68, 0.3), 0.1)
	for n in 10:  # folhinhas
		var x := rng.randi_range(0, 31)
		var y := rng.randi_range(0, 31)
		put(i, x, y, Color(0.47, 0.73, 0.32))
		put(i, x, y + 1, Color(0.3, 0.53, 0.24))
	save(i, "grass")


func soil(name: String, base: Color) -> void:
	var i := new_img(name, 16, 16, base)
	for y in 16:
		if y % 4 == 3:
			rect(i, 0, y, 16, 1, shade(base, 0.78))  # sulco
		elif y % 4 == 0:
			rect(i, 0, y, 16, 1, shade(base, 1.1))
	speckle(i, shade(base, 0.7), 0.1)
	speckle(i, shade(base, 1.25), 0.06)
	save(i, name)


func planks() -> void:
	var base := Color(0.72, 0.5, 0.31)
	var i := new_img("planks", 32, 32, base)
	for row in 4:
		var y0 := row * 8
		var tone := shade(base, rng.randf_range(0.9, 1.08))
		rect(i, 0, y0, 32, 8, tone)
		for n in 5:  # veios da madeira
			var gx := rng.randi_range(0, 31)
			var gy := y0 + rng.randi_range(1, 6)
			for k in rng.randi_range(2, 5):
				put(i, gx + k, gy, shade(tone, 0.9))
		rect(i, 0, y0 + 7, 32, 1, shade(base, 0.66))  # fresta entre tábuas
		rect(i, (row * 13 + 5) % 32, y0, 1, 7, shade(base, 0.7))  # emenda
	save(i, "planks")


func wood(name: String, base: Color) -> void:
	var i := new_img(name, 16, 16, base)
	for x in 16:
		rect(i, x, 0, 1, 16, shade(base, rng.randf_range(0.9, 1.08)))
	for n in 6:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		for k in rng.randi_range(2, 5):
			put(i, x, y + k, shade(base, 0.8))
	save(i, name)


func plaster() -> void:
	var base := Color(0.95, 0.94, 0.91)
	var i := new_img("plaster", 32, 32, base)
	speckle(i, shade(base, 0.94), 0.14)
	speckle(i, Color(1, 1, 1), 0.06)
	for n in 3:  # manchinhas
		var x := rng.randi_range(0, 31)
		var y := rng.randi_range(0, 31)
		for k in 3:
			put(i, x + k, y + (k % 2), shade(base, 0.88))
	save(i, "plaster")


func paving() -> void:
	var base := Color(0.8, 0.77, 0.7)
	var i := new_img("paving", 32, 32, base)
	var tones := {}
	for y in 32:
		for x in 32:
			var row := y / 8
			var sx := posmod(x + (row % 2) * 8, 32)
			var block := row * 4 + sx / 16
			if not tones.has(block):
				tones[block] = rng.randf_range(0.92, 1.06)
			var c := shade(base, tones[block])
			if y % 8 == 7 or sx % 16 == 15:
				c = shade(base, 0.72)  # rejunte
			i.set_pixel(x, y, c)
	speckle(i, shade(base, 0.9), 0.05)
	save(i, "paving")


func tile() -> void:
	var a := Color(0.94, 0.91, 0.83)
	var b := Color(0.82, 0.55, 0.42)
	var i := new_img("tile", 16, 16, a)
	for y in 16:
		for x in 16:
			var c := a if (x / 8 + y / 8) % 2 == 0 else b
			if x % 8 == 7 or y % 8 == 7:
				c = Color(0.66, 0.62, 0.56)
			elif x % 8 == 0 or y % 8 == 0:
				c = shade(c, 1.06)
			i.set_pixel(x, y, c)
	save(i, "tile")


func roof() -> void:
	var base := Color(0.8, 0.4, 0.24)
	var i := new_img("roof", 16, 16, base)
	for y in 16:
		for x in 16:
			var row := y / 4
			var c := base
			match y % 4:
				0:
					c = shade(base, 1.15)
				3:
					c = shade(base, 0.68)
			if (x + (row % 2) * 2) % 4 == 3 and y % 4 != 0:
				c = shade(base, 0.8)
			i.set_pixel(x, y, c)
	speckle(i, shade(base, 0.9), 0.06)
	save(i, "roof")


# --- tecidos e objetos -----------------------------------------------------

func stripes(name: String, color: Color) -> void:
	var cream := Color(0.98, 0.95, 0.87)
	var i := new_img(name, 16, 16, cream)
	for x in 16:
		if (x / 4) % 2 == 0:
			rect(i, x, 0, 1, 16, color if x % 4 != 3 else shade(color, 0.86))
	save(i, name)


func rug() -> void:
	var base := Color(0.2, 0.5, 0.6)
	var i := new_img("rug", 48, 32, base)
	var cream := Color(0.96, 0.9, 0.74)
	var orange := Color(0.95, 0.55, 0.22)
	for y in 32:
		for x in 48:
			var edge := mini(mini(x, 47 - x), mini(y, 31 - y))
			if edge < 2:
				i.set_pixel(x, y, cream)
			elif edge == 3:
				i.set_pixel(x, y, shade(base, 0.7))
			elif (x + y) % 2 == 0:
				i.set_pixel(x, y, shade(base, 0.93))
	for cx: int in [12, 24, 36]:
		for dy in range(-7, 8):
			for dx in range(-7, 8):
				var d := absi(dx) + absi(dy)
				if d <= 3:
					i.set_pixel(cx + dx, 16 + dy, cream)
				elif d <= 6:
					i.set_pixel(cx + dx, 16 + dy, orange)
	save(i, "rug")


func crate() -> void:
	var base := Color(0.8, 0.62, 0.4)
	var i := new_img("crate", 16, 16, base)
	for y in 16:
		for x in 16:
			var c := shade(base, 1.0 + 0.05 * ((x * 7 + y * 3) % 3 - 1))
			if y % 5 == 4:
				c = shade(base, 0.62)  # vão entre as ripas
			if x == 0 or x == 15 or y == 0 or y == 15:
				c = shade(base, 0.52)
			i.set_pixel(x, y, c)
	save(i, "crate")


func bark() -> void:
	var base := Color(0.48, 0.34, 0.21)
	var i := new_img("bark", 16, 16, base)
	for y in 16:
		if y % 4 == 3:
			rect(i, 0, y, 16, 1, shade(base, 0.72))
	speckle(i, shade(base, 1.2), 0.1)
	speckle(i, shade(base, 0.8), 0.1)
	save(i, "bark")


func fabric() -> void:
	var i := new_img("fabric", 16, 16, Color(0.94, 0.94, 0.94))
	for y in 16:
		for x in 16:
			if (x + y) % 2 == 0:
				i.set_pixel(x, y, Color(0.87, 0.87, 0.87))
	save(i, "fabric")


func gingham() -> void:
	var i := new_img("gingham", 16, 16, Color(0.98, 0.96, 0.92))
	for y in 16:
		for x in 16:
			match (x / 4) % 2 + (y / 4) % 2:
				1:
					i.set_pixel(x, y, Color(0.96, 0.6, 0.58))
				2:
					i.set_pixel(x, y, Color(0.85, 0.22, 0.2))
	save(i, "gingham")


func window() -> void:
	var frame := Color(0.96, 0.93, 0.85)
	var i := new_img("window", 16, 16, frame)
	for y in range(1, 15):
		for x in range(1, 15):
			if x == 7 or x == 8 or y == 7 or y == 8:
				continue
			i.set_pixel(x, y, Color(0.52, 0.76, 0.95).lerp(Color(0.74, 0.9, 0.99), y / 15.0))
	for k in 4:  # brilho no vidro
		i.set_pixel(2 + k, 5 - k, Color(1, 1, 1))
		i.set_pixel(10 + k, 13 - k, Color(0.9, 0.97, 1))
	save(i, "window")


func door() -> void:
	var base := Color(0.47, 0.3, 0.17)
	var i := new_img("door", 16, 32, base)
	for x in 16:
		rect(i, x, 0, 1, 32, shade(base, rng.randf_range(0.94, 1.05)))
	for p: Array in [[3, 3, 10, 11], [3, 17, 10, 12]]:  # almofadas
		rect(i, p[0], p[1], p[2], p[3], shade(base, 0.74))
		rect(i, p[0] + 1, p[1] + 1, p[2] - 2, p[3] - 2, shade(base, 1.12))
	for y in 32:
		i.set_pixel(0, y, shade(base, 0.6))
		i.set_pixel(15, y, shade(base, 0.6))
	rect(i, 0, 0, 16, 1, shade(base, 0.6))
	rect(i, 13, 15, 2, 2, Color(0.93, 0.77, 0.3))  # maçaneta
	save(i, "door")


func picture() -> void:
	var i := new_img("picture", 16, 12, Color(0.4, 0.26, 0.15))
	for y in range(1, 11):
		for x in range(1, 15):
			var c := Color(0.6, 0.83, 0.97)
			if y >= 8:
				c = Color(0.3, 0.6, 0.85)  # mar
			elif y >= 5 + absi(x - 5) / 2:
				c = Color(0.33, 0.62, 0.3)  # morro
			i.set_pixel(x, y, c)
	rect(i, 11, 2, 2, 2, Color(1.0, 0.86, 0.3))  # sol
	save(i, "picture")


func clock() -> void:
	var i := new_img("clock", 16, 16, Color(0, 0, 0, 0))
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d <= 7.6:
				i.set_pixel(x, y, Color(0.3, 0.2, 0.14) if d > 6.2 else Color(0.97, 0.95, 0.88))
	rect(i, 7, 3, 1, 5, Color(0.15, 0.15, 0.18))  # ponteiro dos minutos
	rect(i, 8, 8, 3, 1, Color(0.15, 0.15, 0.18))  # ponteiro das horas
	i.set_pixel(7, 8, Color(0.8, 0.2, 0.2))
	save(i, "clock")


# --- humor dos clientes ----------------------------------------------------

## `mouth`: 1 sorriso, 0 reto, -1 triste (com lágrima), -2 raiva (sobrancelhas).
func mood(name: String, color: Color, mouth: int) -> void:
	var i := new_img(name, 16, 16, Color(0, 0, 0, 0))
	var dark := Color(0.14, 0.1, 0.12)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d <= 7.6:
				i.set_pixel(x, y, dark if d > 6.5 else (shade(color, 1.12) if y < 6 else color))
	rect(i, 5, 5, 1, 3, dark)
	rect(i, 10, 5, 1, 3, dark)
	match mouth:
		1:
			rect(i, 5, 11, 6, 1, dark)
			i.set_pixel(4, 10, dark)
			i.set_pixel(11, 10, dark)
		0:
			rect(i, 5, 10, 6, 1, dark)
		_:
			rect(i, 5, 10, 6, 1, dark)
			i.set_pixel(4, 11, dark)
			i.set_pixel(11, 11, dark)
	if mouth == -1:
		rect(i, 11, 8, 1, 2, Color(0.85, 0.95, 1.0))  # lágrima
	if mouth == -2:
		for k in 3:
			i.set_pixel(3 + k, 3 + k, dark)
			i.set_pixel(12 - k, 3 + k, dark)
	save(i, name)
