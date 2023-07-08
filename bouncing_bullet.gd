extends CharacterBody2D

var bug_owner

func setup(pos, dir, speed, owned_bug):
	position = pos
	velocity = dir * speed
	bug_owner = owned_bug

var COLLISIONS_BEFORE_FREE = 3
var num_collisions = 0

func _process(delta):
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
		queue_free()
