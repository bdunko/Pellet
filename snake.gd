extends Node2D

signal dead

enum Direction {
	UP, DOWN, LEFT, RIGHT
}

var _direction := Direction.UP

var _ROTATION_DEGREES_BY_DIR = {
	Direction.UP : 0,
	Direction.DOWN : 180,
	Direction.RIGHT : 90,
	Direction.LEFT: -90
}

var _MOVEMENT_BY_DIR = {
	Direction.UP : Vector2(0, -1),
	Direction.DOWN : Vector2(0, 1),
	Direction.LEFT : Vector2(-1, 0),
	Direction.RIGHT : Vector2(1, 0)
}

func _move():
	# get my grid position
	var grid_pos = Global.to_grid_position(position)
	
	# determine the closest pellet
	var pellets = get_parent().find_child("Pellets")
	var closest_distance = 999
	var closest_pellet = null
	for pellet in pellets.get_children():
		var pellet_grid_pos = Global.to_grid_position(pellet.position)
		
		var x_distance = abs(grid_pos.x - pellet_grid_pos.x)
		var y_distance = abs(grid_pos.y - pellet_grid_pos.y)
		var total_distance = x_distance + y_distance

		if total_distance < closest_distance:
			closest_distance = total_distance
			closest_pellet = pellet

	# if we have a pellet, update according to pellet
	if closest_pellet != null:
		# calculate snake's x and y dist from pellet
		var pellet_grid_pos = Global.to_grid_position(closest_pellet.position)
		var x_diff = grid_pos.x - pellet_grid_pos.x
		var y_diff = grid_pos.y - pellet_grid_pos.y
		# move towards the pellet, in the direction that is farther
		if abs(x_diff) > abs(y_diff):
			if x_diff > 0: 
				_direction = Direction.LEFT
			elif x_diff < 0: 
				_direction = Direction.RIGHT
		else:
			if y_diff > 0: # up
				_direction = Direction.UP
			elif y_diff < 0:
				_direction = Direction.DOWN
			
	# move according to direction
	grid_pos += _MOVEMENT_BY_DIR[_direction]
	
	# check if we hit a wall
	if not Global.is_grid_pos_in_grid(grid_pos):
		emit_signal("dead")
		return
	
	# translate back to global and set position
	position = Global.to_global_position(grid_pos)
	position.y -= 1 # move up a bit more for the tongue
	
	_update_sprite_rotation()

func _update_sprite_rotation():
	$HeadSprite.rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction]

func _on_pellet_hitbox_area_entered(area: Area2D):
	area.get_parent().queue_free()
