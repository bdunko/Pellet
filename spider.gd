extends CharacterBody2D

func _ready():
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

func disable():
	pass

# Terrible $HACK$
func poison():
	pass
