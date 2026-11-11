extends Node
## Efeitos sonoros e som ambiente.
## Os arquivos ficam em res://assets/audio (gerados por tools/gen_audio.gd).
## Para trocar um som, basta substituir o .wav mantendo o nome.

const DIR := "res://assets/audio/"
const VOICES := 8
const SFX_DB := -6.0
const AMBIENCE_DB := -15.0
const FADE_SECONDS := 1.0
const STEP_SOUNDS := {&"house": &"step_wood", &"backyard": &"step_grass", &"market": &"step_stone"}

var _cache := {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _ambience: Array[AudioStreamPlayer] = []
var _active := 0
var _ambience_id := &""
var _fade: Tween


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -60.0
		add_child(p)
		_ambience.append(p)
	SceneRouter.map_changed.connect(func(_id: StringName) -> void: _update_ambience())
	TimeManager.hour_passed.connect(func(_h: int) -> void: _update_ambience())
	TimeManager.day_started.connect(func(_d: int) -> void: play(&"new_day"))
	EventBus.sale_completed.connect(func(_amount: int) -> void: play(&"coin"))
	EventBus.customer_left.connect(func(happy: bool) -> void: play(&"happy" if happy else &"angry"))
	PlayerStats.player_fainted.connect(func() -> void: play(&"faint"))


func _exit_tree() -> void:
	stop_all()


## Silencia tudo (ao fechar o jogo).
func stop_all() -> void:
	if _fade:
		_fade.kill()
	for p: AudioStreamPlayer in _voices + _ambience:
		p.stop()
		p.stream = null
	_ambience_id = &""


## Toca um efeito. `pitch_jitter` varia um pouco o tom para não soar repetido.
func play(id: StringName, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	var stream := _stream(id)
	if stream == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = stream
	p.volume_db = SFX_DB + volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## Passo do jogador, com o som do piso do mapa atual.
func step() -> void:
	play(STEP_SOUNDS.get(SceneRouter.current_id, &"step_stone"), -9.0, 0.15)


func _stream(id: StringName) -> AudioStream:
	if not _cache.has(id):
		var path := DIR + String(id) + ".wav"
		var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if s is AudioStreamWAV and String(id).begins_with("amb_"):
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		_cache[id] = s
	return _cache[id]


func _ambience_for(map_id: StringName) -> StringName:
	match map_id:
		&"house":
			return &"amb_house"
		&"market":
			return &"amb_night" if TimeManager.is_night() else &"amb_market"
		&"backyard":
			return &"amb_night" if TimeManager.is_night() else &"amb_day"
	return &""


## Troca o som ambiente com um fade cruzado.
func _update_ambience() -> void:
	var id := _ambience_for(SceneRouter.current_id)
	if id == _ambience_id:
		return
	_ambience_id = id
	var old := _ambience[_active]
	_active = 1 - _active
	var now := _ambience[_active]
	now.stream = _stream(id)
	if now.stream:
		now.play()
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
	_fade.tween_property(old, "volume_db", -60.0, FADE_SECONDS)
	_fade.tween_property(now, "volume_db", AMBIENCE_DB if now.stream else -60.0, FADE_SECONDS)
	_fade.chain().tween_callback(old.stop)
