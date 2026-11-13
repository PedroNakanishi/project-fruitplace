class_name ItemIcons
extends RefCounted
## Ícones 16x16 dos itens, desenhados por código (pixel art) a partir da cor
## do item. Para usar arte própria, basta colocar res://assets/icons/<id>.png.

const SIZE := 16
const OUTLINE := Color(0.12, 0.07, 0.1)

static var _cache := {}


static func get_icon(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var custom := "res://assets/icons/%s.png" % id
	var tex: Texture2D
	if ResourceLoader.exists(custom):
		tex = load(custom)
	else:
		tex = ImageTexture.create_from_image(_outline(_draw(id)))
	_cache[id] = tex
	return tex


static func _draw(id: StringName) -> Image:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var s := String(id)
	if s.begins_with("semente_"):
		var crop := Catalog.crop(StringName(s.trim_prefix("semente_")))
		_seed_packet(img, crop.color if crop else Color.GRAY)
		return img
	match s:
		"tomate":
			_disc(img, 8, 9, 5.5, Color(0.86, 0.2, 0.16))
			_disc(img, 6, 7, 1.5, Color(1, 0.6, 0.55))
			_rect(img, 6, 3, 5, 2, Color(0.3, 0.7, 0.25))
			_rect(img, 8, 2, 1, 2, Color(0.25, 0.55, 0.2))
		"alface":
			_disc(img, 8, 9, 6, Color(0.45, 0.78, 0.25))
			_disc(img, 8, 9, 4, Color(0.6, 0.88, 0.35))
			_disc(img, 8, 9, 2, Color(0.8, 0.95, 0.5))
		"mandioca":
			for i in 11:
				var w := maxi(1, 4 - i / 3)
				_rect(img, 3 + i, 9 - w / 2 - i / 4, 2, w, Color(0.62, 0.42, 0.24))
			_rect(img, 2, 8, 3, 4, Color(0.75, 0.58, 0.38))
			_rect(img, 12, 3, 2, 2, Color(0.45, 0.3, 0.18))
		"esterco":
			_sack(img, Color(0.5, 0.38, 0.26), Color(0.35, 0.25, 0.16))
			_disc(img, 8, 10, 2, Color(0.3, 0.2, 0.12))
		"npk":
			_sack(img, Color(0.3, 0.5, 0.85), Color(0.2, 0.35, 0.65))
			_rect(img, 6, 8, 4, 4, Color(0.95, 0.95, 0.85))
		"lanche":
			_rect(img, 2, 5, 12, 3, Color(0.88, 0.65, 0.35))
			_rect(img, 3, 8, 10, 2, Color(0.9, 0.45, 0.45))
			_rect(img, 2, 10, 12, 3, Color(0.88, 0.65, 0.35))
		"prato_feito":
			_disc(img, 8, 9, 7, Color(0.95, 0.95, 0.92))
			_disc(img, 6, 8, 2.5, Color(0.95, 0.9, 0.7))
			_disc(img, 10, 8, 2.5, Color(0.3, 0.2, 0.15))
			_rect(img, 5, 11, 6, 2, Color(0.8, 0.5, 0.25))
		"feijoada":
			_rect(img, 2, 6, 12, 7, Color(0.25, 0.22, 0.25))
			_rect(img, 3, 5, 10, 2, Color(0.35, 0.25, 0.2))
			_rect(img, 1, 7, 2, 2, Color(0.2, 0.18, 0.2))
			_rect(img, 13, 7, 2, 2, Color(0.2, 0.18, 0.2))
			_rect(img, 5, 3, 1, 2, Color(0.9, 0.9, 0.9, 0.7))
			_rect(img, 9, 2, 1, 3, Color(0.9, 0.9, 0.9, 0.7))
		_:
			_rect(img, 3, 3, 10, 10, Color(0.7, 0.7, 0.75))
	return img


static func _seed_packet(img: Image, c: Color) -> void:
	_rect(img, 4, 2, 8, 12, Color(0.95, 0.9, 0.78))
	_rect(img, 4, 2, 8, 2, c.darkened(0.2))
	_rect(img, 6, 6, 4, 5, c)
	_rect(img, 7, 5, 2, 1, Color(0.3, 0.7, 0.25))


static func _sack(img: Image, c: Color, dark: Color) -> void:
	_rect(img, 4, 4, 8, 10, c)
	_rect(img, 4, 12, 8, 2, dark)
	_rect(img, 5, 2, 6, 3, c.lightened(0.1))
	_rect(img, 6, 3, 4, 1, dark)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(maxi(y, 0), mini(y + h, SIZE)):
		for xx in range(maxi(x, 0), mini(x + w, SIZE)):
			img.set_pixel(xx, yy, c)


static func _disc(img: Image, cx: int, cy: int, r: float, c: Color) -> void:
	for y in SIZE:
		for x in SIZE:
			if Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, c)


## Contorno escuro de 1 pixel em volta da silhueta, para o ícone destacar do fundo.
static func _outline(img: Image) -> Image:
	var out := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			if img.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, img.get_pixel(x, y))
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n := Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < SIZE and n.y < SIZE and img.get_pixel(n.x, n.y).a > 0.0:
					out.set_pixel(x, y, OUTLINE)
					break
	return out
