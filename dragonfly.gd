extends CharacterBody2D

const BULLET = preload("res://bullet.tscn")
const BULLET_SPEED = 90

var disabled = false
var SPEED = 60

func _ready():
	# pick a direction...
	var roll = Global.RNG.randi_range(0, 3)
	if roll == 0:
		velocity = Vector2(SPEED, 0)
		rotation_degrees = 90
	if roll == 1:
		velocity = Vector2(-SPEED, 0)
		rotation_degrees = -90
	if roll == 2:
		velocity = Vector2(0, SPEED)
		rotation_degrees = 180
	if roll == 3:
		velocity = Vector2(0, -SPEED)
		rotation_degrees = 0

func _process(delta):
	if not disabled:
		var collide = move_and_collide(velocity * delta)
		if collide: #flip direction
			velocity.x = -velocity.x
			velocity.y = -velocity.y
			if velocity.x != 0:
				rotation_degrees = -rotation_degrees
			else:
				if velocity.y > 0:
					rotation_degrees = 180
				else:
					rotation_degrees = 0

func disable():
	disabled = true
