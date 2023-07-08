extends Node2D

const TIP_FORMAT = "%s"

var active = false

func next_level(tip):
	$Tip.text = TIP_FORMAT % tip
	$Timer.start()
	active = true

func _process(delta):
	if active:
		modulate.a = lerp(modulate.a, 1.0, 8.0 * delta)
	else:
		modulate.a = lerp(modulate.a, 0.0, 8.0 * delta)


func _on_timer_timeout():
	active = false
