extends Node2D

var active = true

func on_reset():
	active = true

func on_playing():
	active = false

func _process(delta):
	if active:
		modulate.a = lerp(modulate.a, 1.0, 15.0 * delta)
	else:
		modulate.a = lerp(modulate.a, 0.0, 15.0 * delta)
