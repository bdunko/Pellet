extends CharacterBody2D

func setup(pos, dir, speed):
	position = pos
	velocity = dir * speed

func _process(delta):
	if move_and_collide(velocity  * delta) != null:
		queue_free()
