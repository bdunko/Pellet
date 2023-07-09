extends CharacterBody2D

var bug_owner

var mod_target = 1.0

func setup(pos, dir, speed, owned_bug):
	position = pos
	velocity = dir * speed
	bug_owner = owned_bug

func _process(delta):
	modulate.a = lerp(modulate.a, mod_target, 20 * delta)
	modulate.r = lerp(modulate.r, mod_target, 20 * delta)
	modulate.g = lerp(modulate.g, mod_target, 20 * delta)
	if modulate.r == 0:
		queue_free()
	
	if position.x < -30 or position.x > Global.RESOLUTION.x or position.y < -30 or position.y > Global.RESOLUTION.y:
		call_deferred("_begin_destroy")
	
	move_and_collide(velocity  * delta) 

func _on_collide_with_bug(_body):
	print("bug")
	pass
	#maybe something crazy later

func _begin_destroy():
	mod_target = 0.0
	$CollisionShape2D.disabled = true
	velocity = Vector2.ZERO
