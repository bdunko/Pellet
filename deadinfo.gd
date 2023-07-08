extends Node2D

var active = false

func on_dead():
	active = true

func on_reset():
	active = false

func _process(delta):
	if active:
		modulate.a = lerp(modulate.a, 1.0, 10.0 * delta)
	else:
		modulate.a = lerp(modulate.a, 0.0, 10.0 * delta)
