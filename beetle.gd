extends CharacterBody2D

const BULLET = preload("res://bullet.tscn")
const BULLET_SPEED = 35

var disabled = false

var SHOT_PREVIEW_MODULATE = 0.5

func _ready():
	modulate.a = 0

func _process(delta):
	# transparency
	modulate.a = lerp(modulate.a, 1.0, 12 * delta)
	
	if not disabled:
		if $ShotTimer.time_left <= 0.2:
			modulate.r = lerp(modulate.r, SHOT_PREVIEW_MODULATE, 20 * delta)
		else:
			modulate.r = lerp(modulate.r, 1.0, 30 * delta)
	
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

func _on_shot_timer_timeout():
	if not disabled:
		var bullet = BULLET.instantiate()
		
		var pellet_pos = get_parent().get_parent().find_child("Pellet").position
		var direction = Vector2(pellet_pos.x - position.x, pellet_pos.y - position.y).normalized()
		bullet.setup(position, direction, BULLET_SPEED * get_parent().get_parent().bullet_speed_multiplier, self)
		bullet.position = position
		get_parent().get_parent().find_child("Bullets").add_child(bullet)
		bullet.shot.connect(get_parent().get_parent().on_bullet_shot)
		bullet.shoot()

func disable():
	disabled = true
