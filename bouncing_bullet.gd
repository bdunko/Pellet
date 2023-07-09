extends CharacterBody2D

var bug_owner

func setup(pos, dir, speed, owned_bug):
	position = pos
	velocity = dir * speed
	bug_owner = owned_bug

var COLLISIONS_BEFORE_FREE = 3
var num_collisions = 0
var mod_target = 1.0

func _process(delta):
	modulate.a = lerp(modulate.a, mod_target, 20 * delta)
	modulate.r = lerp(modulate.r, mod_target, 20 * delta)
	modulate.g = lerp(modulate.g, mod_target, 20 * delta)
	if modulate.r == 0:
		queue_free()
		
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		_update_num_collisions()
		var reflect = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal())
		if velocity.y > 0:
			rotation_degrees = -180
		else:
			rotation_degrees = 0
		move_and_collide(reflect)

func _on_collide_with_bug(body): #hmm... rethink this
	if body != bug_owner:
		_update_num_collisions()

func _update_num_collisions():
	num_collisions += 1
	if num_collisions == COLLISIONS_BEFORE_FREE:
		call_deferred("_begin_destroy")

func _begin_destroy():
	mod_target = 0.0
	$CollisionShape2D.disabled = true
	velocity = Vector2.ZERO
