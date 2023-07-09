extends CharacterBody2D

const BULLET = preload("res://moon_bullet.tscn")
const BULLET_SPEED = 100

var disabled = false

var SHOT_PREVIEW_MODULATE = 0.7

func _ready():
	modulate.a = 0

func _process(delta):
	# transparency
	modulate.a = lerp(modulate.a, 1.0, 12 * delta)
	
	if not disabled:
		if $ShotTimer.time_left <= 0.2:
			modulate.b = lerp(modulate.b, SHOT_PREVIEW_MODULATE, 20 * delta)
		else:
			modulate.b = lerp(modulate.b, 1.0, 30 * delta)

func _on_shot_timer_timeout():
	if not disabled:
		var bullet = BULLET.instantiate()
		var pellet_pos = get_parent().get_parent().find_child("Pellet").position
		var direction = Vector2(pellet_pos.x - position.x, pellet_pos.y - position.y).normalized()
		bullet.setup(position, direction, BULLET_SPEED * get_parent().get_parent().bullet_speed_multiplier, self)
		bullet.position = position
		get_parent().get_parent().find_child("Bullets").add_child(bullet)

func disable():
	disabled = true
