extends Node2D

signal dead

func _move():
	# get my grid position
	var grid_pos = Global.to_grid_position(position)
	
	var pellets = get_parent().find_child("Pellets")
	var closest_distance = 999
	var closest_pellet = null
	for pellet in pellets.get_children():
		var pellet_grid_pos = Global.to_grid_position(pellet.position)
		print(pellet_grid_pos)
		
		var x_distance = abs(grid_pos.x - pellet_grid_pos.x)
		var y_distance = abs(grid_pos.y - pellet_grid_pos.y)
		var total_distance = x_distance + y_distance

		if total_distance < closest_distance:
			closest_distance = total_distance
			closest_pellet = pellet


	
	
	# move up by 1 (for now)
	# TOOD - move towards nearest pellet
	grid_pos.y -= 1
	
	# check if we hit a wall
	if not Global.is_grid_pos_in_grid(grid_pos):
		emit_signal("dead")
		return
	
	# translate back to global and set position
	position = Global.to_global_position(grid_pos)
	position.y -= 1 # move up a bit more for the tongue

func _on_pellet_hitbox_area_entered(area: Area2D):
	area.get_parent().queue_free()
