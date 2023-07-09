extends CharacterBody2D

const BULLET = preload("res://bullet.tscn")
const BULLET_SPEED = 80

var disabled = false
var SPEED = 40
var vertical = false

func _ready():
	modulate.a = 0

func setup(is_vertical):
	vertical = is_vertical
	
	var roll = Global.RNG.randi_range(0, 1)
	
	if is_vertical: # up/down ant
		if roll == 0:
			velocity = Vector2(0, SPEED)
			rotation_degrees = 180
		elif roll == 1:
			velocity = Vector2(0, -SPEED)
			rotation_degrees = 0
	else: # left/right ant
		if roll == 0:
			velocity = Vector2(SPEED, 0)
			rotation_degrees = 90
		elif roll == 1:
			velocity = Vector2(-SPEED, 0)
			rotation_degrees = -90

func _process(delta):
	# transparency
	modulate.a = lerp(modulate.a, 1.0, 12 * delta)
	
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
