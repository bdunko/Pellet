extends CharacterBody2D

var SPEED = 20

var disabled = false

func _ready():
	modulate.a = 0

func _process(delta):
	# transparency
	modulate.a = lerp(modulate.a, 1.0, 12 * delta)
	
	if not disabled:
		#rotate to face player
		var pellet_pos = get_parent().get_parent().find_child("Pellet").position
		var x_diff = position.x - pellet_pos.x
		var y_diff = position.y - pellet_pos.y

		if abs(x_diff) > abs(y_diff): # face left or right
			if x_diff > 0: 
				rotation_degrees = -90
			else:
				rotation_degrees = 90
		else: # face up or down
			if y_diff > 0:
				rotation_degrees = 0
			else:
				rotation_degrees = 180
		
		# hunt towards player
		var direction = Vector2(pellet_pos.x - position.x, pellet_pos.y - position.y).normalized()
		velocity = direction * SPEED
		move_and_collide(velocity * delta)

func disable():
	disabled = true

# TERRIBLE $HACK$
func DONT_COUNT():
	pass
