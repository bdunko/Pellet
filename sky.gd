extends Node2D

@onready var current_sky_index = get_child_count() - 1 #4

func next_sky():
	if current_sky_index == 0:
		return
	current_sky_index -= 1

func _process(delta):
	for index in get_child_count():
		var sky = get_child(index)
		if index <= current_sky_index: # we should be visible
			sky.self_modulate.a = lerp(sky.self_modulate.a, 1.0, 5 * delta)
		if index > current_sky_index: # we should be invisible
			sky.self_modulate.a = lerp(sky.self_modulate.a, 0.0, 5 * delta)	

func reset():
	current_sky_index = get_child_count() - 1
	for bg in get_children():
		bg.self_modulate.a = 1
