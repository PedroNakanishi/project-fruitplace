extends SceneTree
## Sintetiza os efeitos sonoros e os sons ambiente em res://assets/audio.
## Uso: Godot --headless --path . -s tools/gen_audio.gd
## São .wav comuns (22 kHz mono): dá para trocar qualquer um por uma gravação
## de verdade mantendo o nome do arquivo. Os que começam com "amb_" tocam em loop.

const OUT := "res://assets/audio/"
const RATE := 22050

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 1994
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	ui()
	steps()
	actions()
	people()
	jingles()
	amb_day()
	amb_night()
	amb_market()
	amb_house()
	print("Sons gerados em ", OUT)
	quit()


# --- síntese ---------------------------------------------------------------

func buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Soma uma nota em `b`. A frequência desliza de f0 a f1; `decay` 0 = volume
## constante, maior = some mais rápido.
func tone(b: PackedFloat32Array, at: float, dur: float, f0: float, f1: float, vol: float,
		shape := "sine", decay := 2.0, attack := 0.004) -> void:
	var start := int(at * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	for i in n:
		if start + i >= b.size():
			break
		var t := float(i) / n
		phase = fposmod(phase + lerpf(f0, f1, t) / RATE, 1.0)
		var s: float
		match shape:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"saw":
				s = 2.0 * phase - 1.0
			"tri":
				s = 4.0 * absf(phase - 0.5) - 1.0
			_:
				s = sin(TAU * phase)
		b[start + i] += s * vol * _env(i, n, t, decay, attack)


## Soma ruído filtrado: passa-baixa deslizando de lp0 a lp1; `hp` corta os graves.
func noise(b: PackedFloat32Array, at: float, dur: float, vol: float, lp0: float, lp1 := -1.0,
		hp := 0.0, decay := 2.0, attack := 0.003) -> void:
	var start := int(at * RATE)
	var n := int(dur * RATE)
	var low := 0.0
	var low2 := 0.0
	var ah := 1.0 - exp(-TAU * hp / RATE)
	for i in n:
		if start + i >= b.size():
			break
		var t := float(i) / n
		var cut := lerpf(lp0, lp1 if lp1 > 0.0 else lp0, t)
		low += (rng.randf_range(-1.0, 1.0) - low) * (1.0 - exp(-TAU * cut / RATE))
		var s := low
		if hp > 0.0:
			low2 += (low - low2) * ah
			s = low - low2
		b[start + i] += s * vol * _env(i, n, t, decay, attack)


func _env(i: int, n: int, t: float, decay: float, attack: float) -> float:
	var a := 1.0 if attack <= 0.0 else minf(1.0, i / (attack * RATE))
	var release := minf(1.0, (n - i) / (0.004 * RATE))  # evita estalo no fim
	return a * release * pow(1.0 - t, decay)


## Emenda o fim no começo para o loop não ter estalo.
func loopify(b: PackedFloat32Array, fade: float) -> PackedFloat32Array:
	var n := int(fade * RATE)
	var out := b.slice(0, b.size() - n)
	for i in n:
		var t := float(i) / n
		out[i] = b[i] * sqrt(t) + b[b.size() - n + i] * sqrt(1.0 - t)
	return out


func mix(into: PackedFloat32Array, from: PackedFloat32Array) -> void:
	for i in mini(into.size(), from.size()):
		into[i] += from[i]


func save(name: String, b: PackedFloat32Array, peak := 0.85) -> void:
	var top := 0.0001
	for s in b:
		top = maxf(top, absf(s))
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i] / top * peak, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(OUT + name + ".wav")


# --- efeitos ---------------------------------------------------------------

func ui() -> void:
	var b := buf(0.12)
	tone(b, 0.0, 0.1, 520, 820, 0.5, "tri", 1.5)
	save("ui_open", b, 0.5)
	b = buf(0.12)
	tone(b, 0.0, 0.05, 880, 880, 0.3, "square", 1.5)
	tone(b, 0.04, 0.07, 1320, 1320, 0.3, "square", 2.0)
	save("ui_select", b, 0.45)
	b = buf(0.14)
	tone(b, 0.0, 0.12, 520, 330, 0.5, "tri", 1.5)
	save("ui_cancel", b, 0.45)
	b = buf(0.3)
	tone(b, 0.0, 0.1, 170, 150, 0.5, "square", 1.0)
	tone(b, 0.14, 0.14, 150, 120, 0.5, "square", 1.0)
	save("error", b, 0.45)
	b = buf(0.06)
	tone(b, 0.0, 0.05, 1000, 1150, 0.4, "tri", 2.5)
	save("ui_hover", b, 0.3)
	b = buf(0.5)
	noise(b, 0.0, 0.45, 0.6, 600, 4200, 200, 1.2, 0.12)
	tone(b, 0.0, 0.4, 200, 500, 0.2, "sine", 1.5, 0.1)
	save("whoosh", b, 0.5)
	b = buf(2.4)
	tone(b, 0.0, 2.2, 110, 110, 0.35, "sine", 0.6, 0.6)
	tone(b, 0.0, 2.2, 165, 165, 0.25, "sine", 0.6, 0.8)
	tone(b, 0.6, 1.6, 330, 330, 0.18, "tri", 1.2, 0.3)
	tone(b, 1.0, 1.2, 495, 495, 0.12, "tri", 1.5, 0.2)
	save("cine_sting", b, 0.55)
	b = buf(0.05)
	tone(b, 0.0, 0.03, 1800, 1800, 0.3, "square", 3.0)
	save("type", b, 0.25)


func steps() -> void:
	var b := buf(0.1)
	noise(b, 0.0, 0.07, 1.0, 900, 400, 0.0, 3.0)
	tone(b, 0.0, 0.06, 150, 90, 0.5, "sine", 2.0)
	save("step_wood", b, 0.6)
	b = buf(0.14)
	noise(b, 0.0, 0.13, 1.0, 4000, 2000, 1200, 2.0, 0.02)
	save("step_grass", b, 0.4)
	b = buf(0.08)
	noise(b, 0.0, 0.05, 1.0, 2800, 1200, 300, 3.0)
	tone(b, 0.0, 0.03, 240, 170, 0.3, "sine", 2.0)
	save("step_stone", b, 0.5)


func actions() -> void:
	var b := buf(0.55)  # porta: rangido e batida
	tone(b, 0.0, 0.26, 190, 280, 0.12, "saw", 0.6, 0.05)
	tone(b, 0.0, 0.26, 287, 410, 0.07, "saw", 0.6, 0.05)
	noise(b, 0.3, 0.16, 1.0, 600, 200, 0.0, 3.0)
	tone(b, 0.3, 0.14, 95, 60, 0.7, "sine", 2.0)
	save("door", b, 0.7)

	b = buf(0.5)  # moeda da venda
	tone(b, 0.0, 0.08, 988, 988, 0.4, "square", 1.0)
	tone(b, 0.08, 0.4, 1319, 1319, 0.4, "square", 2.5)
	save("coin", b, 0.5)

	b = buf(0.22)  # compra pelo telefone
	tone(b, 0.0, 0.06, 660, 660, 0.4, "square", 1.0)
	tone(b, 0.07, 0.14, 880, 880, 0.4, "square", 2.0)
	save("buy", b, 0.45)

	b = buf(0.2)  # semente na terra
	noise(b, 0.0, 0.17, 1.0, 800, 300, 0.0, 2.5)
	tone(b, 0.0, 0.1, 130, 70, 0.5, "sine", 2.0)
	save("plant", b, 0.65)

	b = buf(0.8)  # regador
	noise(b, 0.0, 0.75, 1.0, 3200, 1400, 600, 1.2, 0.08)
	for n in 6:
		var f := rng.randf_range(900, 1500)
		tone(b, rng.randf_range(0.1, 0.6), 0.04, f, f * 1.5, 0.12, "sine", 2.0)
	save("water", b, 0.6)

	b = buf(0.18)  # colheita: "pop"
	tone(b, 0.0, 0.09, 380, 920, 0.6, "sine", 1.0)
	tone(b, 0.09, 0.07, 1250, 1250, 0.3, "tri", 2.5)
	save("harvest", b, 0.65)

	b = buf(0.32)  # adubo: saquinho sacudido
	for n in 4:
		noise(b, n * 0.07, 0.05, 1.0, 2600, 1500, 800, 2.0)
	save("fertilize", b, 0.5)

	b = buf(0.5)  # mastigando
	for n in 3:
		noise(b, n * 0.16, 0.07, 1.0, 1900, 900, 300, 2.5)
		tone(b, n * 0.16, 0.05, 210, 130, 0.25, "sine", 2.0)
	save("eat", b, 0.6)

	b = buf(0.42)  # telefone de tecla
	var keys := [[697, 1209], [770, 1336], [852, 1477]]
	for n in 3:
		tone(b, n * 0.13, 0.09, keys[n][0], keys[n][0], 0.3, "sine", 0.0)
		tone(b, n * 0.13, 0.09, keys[n][1], keys[n][1], 0.3, "sine", 0.0)
	save("phone", b, 0.45)

	b = buf(1.5)  # caminhonete arrancando
	for i in b.size():
		var t := float(i) / b.size()
		var f := lerpf(48.0, 82.0, smoothstep(0.0, 0.7, t))
		var ph := fposmod(i * f / RATE, 1.0)
		var rough := 0.6 + 0.4 * sin(TAU * i * f * 0.5 / RATE)
		b[i] = (2.0 * ph - 1.0) * rough * sin(PI * t) * 0.6
	noise(b, 0.0, 1.5, 0.5, 350, 500, 0.0, 0.6, 0.2)
	save("engine", b, 0.7)

	b = buf(0.7)  # desmaio
	tone(b, 0.0, 0.65, 620, 110, 0.5, "tri", 0.8)
	save("faint", b, 0.5)


func people() -> void:
	var b := buf(0.5)  # conversa fiada
	for n in 6:
		var f := rng.randf_range(300, 540)
		tone(b, n * 0.075, 0.055, f, f * rng.randf_range(0.9, 1.15), 0.4, "tri", 1.0)
	save("talk", b, 0.5)

	b = buf(0.4)  # cliente satisfeito
	tone(b, 0.0, 0.08, 660, 660, 0.4, "tri", 1.0)
	tone(b, 0.08, 0.08, 880, 880, 0.4, "tri", 1.0)
	tone(b, 0.16, 0.2, 1100, 1100, 0.4, "tri", 2.0)
	save("happy", b, 0.5)

	b = buf(0.4)  # cliente bufando
	tone(b, 0.0, 0.34, 190, 105, 0.4, "saw", 1.0)
	tone(b, 0.0, 0.34, 95, 60, 0.3, "square", 1.0)
	save("angry", b, 0.5)


func jingles() -> void:
	var b := buf(1.0)  # novo dia
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for n in 4:
		var d := 0.5 if n == 3 else 0.13
		tone(b, n * 0.13, d, notes[n], notes[n], 0.3, "tri", 1.5)
		tone(b, n * 0.13, d, notes[n] * 2.0, notes[n] * 2.0, 0.08, "square", 2.5)
	save("new_day", b, 0.5)

	b = buf(1.3)  # hora de dormir
	notes = [783.99, 659.25, 523.25]
	for n in 3:
		var d := 0.7 if n == 2 else 0.26
		tone(b, n * 0.26, d, notes[n], notes[n], 0.3, "tri", 1.5, 0.02)
	save("night", b, 0.45)


# --- ambientes (loops) -----------------------------------------------------

## Dia no quintal: brisa e passarinhos.
func amb_day() -> void:
	var b := buf(10.5)
	noise(b, 0.0, 10.5, 1.0, 500, 500, 120, 0.0)
	for i in b.size():  # a brisa vai e vem
		b[i] *= 0.6 + 0.4 * sin(TAU * i / (RATE * 5.25))
	for n in 11:
		var at := rng.randf_range(0.6, 9.2)
		var f := rng.randf_range(2400, 4300)
		var vol := rng.randf_range(0.5, 1.4)
		for k in rng.randi_range(2, 5):
			var up := rng.randf_range(0.75, 1.35)
			tone(b, at + k * rng.randf_range(0.09, 0.13), rng.randf_range(0.04, 0.08), f, f * up, vol, "sine", 1.0, 0.01)
	save("amb_day", loopify(b, 0.5), 0.6)


## Noite: grilos (em compasso exato, fecham o loop sozinhos) e um sapo.
func amb_night() -> void:
	var bed := buf(8.5)
	noise(bed, 0.0, 8.5, 1.0, 260, 260, 0.0, 0.0)
	var b := loopify(bed, 0.5)
	for n in 25:
		for k in 3:
			tone(b, n * 0.32 + k * 0.026, 0.014, 4200, 4200, 1.3, "sine", 0.3, 0.002)
	for n in 16:
		for k in 2:
			tone(b, 0.11 + n * 0.5 + k * 0.03, 0.016, 3500, 3500, 0.6, "sine", 0.3, 0.002)
	for at: float in [2.1, 5.7]:
		for k in 3:
			tone(b, at + k * 0.17, 0.11, 120, 100, 0.5, "square", 1.0, 0.01)
	save("amb_night", b, 0.5)


## Feira: burburinho de gente e um pregão de vez em quando.
func amb_market() -> void:
	var b := buf(10.5)
	noise(b, 0.0, 10.5, 1.6, 650, 650, 180, 0.0)
	for i in b.size():
		b[i] *= 0.7 + 0.3 * sin(TAU * i / (RATE * 3.5))
	for n in 70:  # vozes
		var f := rng.randf_range(170, 430)
		tone(b, rng.randf_range(0.6, 9.6), rng.randf_range(0.06, 0.14), f, f * rng.randf_range(0.85, 1.2), rng.randf_range(0.15, 0.4), "tri", 1.0, 0.015)
	for at: float in [2.4, 7.1]:  # pregão
		tone(b, at, 0.22, 392, 440, 0.45, "tri", 0.6, 0.02)
		tone(b, at + 0.24, 0.3, 523, 494, 0.45, "tri", 1.0, 0.02)
	save("amb_market", loopify(b, 0.5), 0.6)


## Casa: tique-taque do relógio e um zumbido baixinho.
func amb_house() -> void:
	var bed := buf(6.5)
	noise(bed, 0.0, 6.5, 0.5, 180, 180, 0.0, 0.0)
	var b := loopify(bed, 0.5)
	tone(b, 0.0, 6.0, 100, 100, 0.03, "sine", 0.0, 0.0)
	for n in 6:
		var f := 2300.0 if n % 2 == 0 else 1800.0
		tone(b, n * 1.0 + 0.2, 0.012, f, f, 0.5, "tri", 1.0, 0.001)
		noise(b, n * 1.0 + 0.2, 0.012, 0.3, 6000, 6000, 2500, 1.0, 0.001)
	save("amb_house", b, 0.4)
