extends Node2D

signal dead

enum Direction {
	UP, DOWN, LEFT, RIGHT
}

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

var _direction := Direction.UP
var _previous_head_positions := []

class Pair:
	var pos: Vector2
	var original_dir: Direction
	
	func _init():
		pos = Vector2.ZERO
	
	func setup(p, dir) -> Pair:
		pos = p
		original_dir = dir
		return self

func _dir_to_pellet(grid_pos: Vector2, pellet_pos: Vector2) -> Direction:
	assert(not _is_snake_at(grid_pos))
	
	var depth = 0
	var checked = []
	var to_check = []
	var next_checks = [
		Pair.new().setup(Vector2(grid_pos.x + 1, grid_pos.y), Direction.RIGHT),
		Pair.new().setup(Vector2(grid_pos.x - 1, grid_pos.y), Direction.LEFT),
		Pair.new().setup(Vector2(grid_pos.x, grid_pos.y + 1), Direction.DOWN),
		Pair.new().setup(Vector2(grid_pos.x, grid_pos.y - 1), Direction.UP)
		]
	next_checks.shuffle()
	
	while next_checks.size() != 0:
		for pair in next_checks:
			to_check.append(pair)
		next_checks.clear()
		
		while to_check.size() != 0:
			var current_check: Pair = to_check.pop_front()
			if not Global.is_grid_pos_in_grid(current_check.pos) or _is_snake_at(current_check.pos) or current_check.pos in checked: # can't go this way
				continue
			
			checked.append(current_check.pos)
			
			if current_check.pos == pellet_pos:
				return current_check.original_dir # found a path
			else: # append left, up, right, down
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(1, 0), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(-1, 0), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(0, 1), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(0, -1), current_check.original_dir))
				
	
	assert(false)
	return Direction.UP # couldn't find path

func _move():
	# store previous before moving
	_previous_head_positions.push_front(position)
	if(_previous_head_positions.size() == 100): #don't track forever
		_previous_head_positions.remove_at(99)
	
	# get my grid position
	var grid_pos = Global.to_grid_position(position)
	
	var pellet_pos = Global.to_grid_position(get_parent().find_child("Pellet").position)
	
	# determine next movement
	_direction = _dir_to_pellet(grid_pos, pellet_pos)
	
	# move according to direction
	grid_pos += _MOVEMENT_BY_DIR[_direction]
	
	# check if we hit a wall
	if not Global.is_grid_pos_in_grid(grid_pos):
		emit_signal("dead")
		return
	
	# translate back to global and set position
	position = Global.to_global_position(grid_pos)
	position.y -= 1 # move up a bit more for the tongue
	
	
	# move each segment to position of segment in front of it, from back to front
	var segments = $Segments.get_children()
	segments.reverse()
	for i in range(0, segments.size()):
		var segment = segments[i]
		segment.visible = true
		# special case: if last segment, move to head's previous
		if i == segments.size() - 1:
			segment.position = _previous_head_positions[0]
		else: # otherwise move to next segment
			var next_segment = segments[i+1]
			segment.position = next_segment.position
			segment.rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, next_segment.position)]
	
	# fix rotations
	for i in range(0, segments.size()):
		var segment = segments[i]
		if i == segments.size() - 1: # head case
			segment.rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, position)]
		else:
			var next_segment = segments[i+1]
			segment.rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, next_segment.position)]
	
	# fix head's rotation
	$HeadSprite.rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction]

func _is_snake_at(grid_pos: Vector2):
	var pos = Global.to_grid_position(grid_pos)
	for segment in $Segments.get_children():
		if pos == segment.position:
			return true
	return false

func _direction_to(point_from: Vector2, point_to: Vector2) -> Direction:
	if point_from.x == point_to.x:
		if point_from.y > point_to.y:
			return Direction.UP
		else:
			return Direction.DOWN
	else:
		if point_from.x < point_to.x:
			return Direction.RIGHT
		else:
			return Direction.LEFT

func _on_pellet_hitbox_area_entered(area: Area2D):
	area.get_parent().queue_free()
	# grow snake, add segment at previous location
	var new_segment = load("res://snake_segment.tscn").instantiate()
	new_segment.position = position 
	new_segment.visible = false # initially, hide segment so it appears to 'pop in' next time snake moves
	$Segments.add_child(new_segment)
