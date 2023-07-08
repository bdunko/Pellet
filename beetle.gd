extends Node2D

const BULLET = preload("res://bullet.tscn")
const BULLET_SPEED = 50

func _process(_delta):
	pass
	# rotate in 90d increments

func _on_shot_timer_timeout():
	var bullet = BULLET.instantiate()
	
	var pellet_pos = get_parent().get_parent().find_child("Pellet").position
	var direction = Vector2(pellet_pos.x - position.x, pellet_pos.y - position.y).normalized()
	bullet.setup(position, direction, BULLET_SPEED)
	bullet.position = position
	get_parent().get_parent().find_child("Bullets").add_child(bullet)
