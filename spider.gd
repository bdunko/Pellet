extends CharacterBody2D

func _ready():
	modulate.a = 0
	# random direction
	var roll = Global.RNG.randi_range(0, 3)
	if roll == 0:
		rotation_degrees = 90
	if roll == 1:
		rotation_degrees = -90
	if roll == 2:
		rotation_degrees = 180
	if roll == 3:
		rotation_degrees = 0

func _process(delta):
	modulate.a = lerp(modulate.a, 1.0, 12 * delta)

func disable():
	pass

# Terrible $HACK$
func poison():
	pass
