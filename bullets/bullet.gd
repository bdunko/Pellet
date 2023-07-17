extends CharacterBody2D

var bug_owner

var mod_target = 1.0

var disabled = false

signal shot

#$HACK$
func shoot():
	emit_signal("shot")

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
	
	if not disabled:
		var collide = move_and_collide(velocity  * delta) 
		if collide != null:
			call_deferred("_begin_destroy")


func _on_collide_with_bug(body):
	if body != bug_owner:
		call_deferred("_begin_destroy")

func _begin_destroy():
	mod_target = 0.0
	$CollisionShape2D.disabled = true
	velocity = Vector2.ZERO

func disable():
	disabled = true
	$AnimatedSprite2D.stop()
