extends CharacterBody2D

var disabled = false
var SPEED = 45
const BULLET = preload("res://bouncing_bullet.tscn")
const BULLET_SPEED = 60

func _ready():
	# pick a diagonal...
	var roll = Global.RNG.randi_range(0, 3)
	if roll == 0:
		velocity = Vector2(SPEED/3.0, SPEED)
		rotation_degrees = -180
	if roll == 1:
		velocity = Vector2(-SPEED/3.0, SPEED)
		rotation_degrees = -180
	if roll == 2:
		velocity = Vector2(SPEED/3.0, -SPEED)
		rotation_degrees = 0
	if roll == 3:
		velocity = Vector2(-SPEED/3.0, -SPEED)
		rotation_degrees = 0

func _process(delta):
	if not disabled:
		var collision: KinematicCollision2D = move_and_collide(velocity * delta)
		if collision:
			var reflect = collision.get_remainder().bounce(collision.get_normal())
			velocity = velocity.bounce(collision.get_normal())
			if velocity.y > 0:
				rotation_degrees = -180
			else:
				rotation_degrees = 0
			move_and_collide(reflect)

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