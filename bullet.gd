extends CharacterBody2D

var bug_owner

func setup(pos, dir, speed, owned_bug):
	position = pos
	velocity = dir * speed
	bug_owner = owned_bug

func _process(delta):
	var collide = move_and_collide(velocity  * delta) 
	if collide != null:
		queue_free()

func _on_collide_with_bug(body):
	if body != bug_owner:
		queue_free()
