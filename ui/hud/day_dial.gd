class_name DayDial
extends Control
## Ícone de sol/lua que faz a transição quando anoitece.

var _t := 0.0  ## 0 = dia, 1 = noite.
var _tween: Tween
var _night := false


func _init() -> void:
	custom_minimum_size = Vector2(38, 38)


func _process(_delta: float) -> void:
	var night := TimeManager.is_night()
	if night != _night:
		_night = night
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_method(_set_t, _t, 1.0 if night else 0.0, 0.8)
	elif not _night:
		queue_redraw()  # raios girando de dia


func _set_t(v: float) -> void:
	_t = v
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var body := Color(1.0, 0.82, 0.3).lerp(Color(0.85, 0.9, 1.0), _t)
	if _t < 0.99:
		var spin := Time.get_ticks_msec() / 4000.0
		for i in 8:
			var a := spin + i * TAU / 8.0
			var ray := Color(1.0, 0.82, 0.3, 1.0 - _t)
			draw_line(c + Vector2.from_angle(a) * 12.0, c + Vector2.from_angle(a) * 17.0, ray, 2.5)
	draw_circle(c, 9.5, body)
	if _t > 0.01:
		draw_circle(c + Vector2(5, -3) * _t, 8.0 * _t, Color(0.1, 0.06, 0.12, 0.95))
