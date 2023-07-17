extends Node2D

signal ate_bug

signal snake_at
signal snake_not_at

enum Direction {
	UP, DOWN, LEFT, RIGHT, NONE
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
var _enabled = false

@onready var STARTING_POS = position
@onready var STARTING_ROT = rotation_degrees
const QUEUED_SEGMENTS_DEFAULT = 10
var queued_segments = QUEUED_SEGMENTS_DEFAULT


class Pair:
	var pos: Vector2
	var original_dir: Direction
	
	func _init():
		pos = Vector2.ZERO
	
	func setup(p, dir) -> Pair:
		pos = p
		original_dir = dir
		return self

func _dir_to_pellet(grid_pos: Vector2, pellet_pos: Vector2, snake_grid: Array) -> Direction:
	# remember spots we checked for each possible direction
	var checked = []
	
	var to_check = []
	# initial spots to check - up down left right from starting position
	var next_checks = [
		Pair.new().setup(Vector2(grid_pos.x + 1, grid_pos.y), Direction.RIGHT),
		Pair.new().setup(Vector2(grid_pos.x - 1, grid_pos.y), Direction.LEFT),
		Pair.new().setup(Vector2(grid_pos.x, grid_pos.y + 1), Direction.DOWN),
		Pair.new().setup(Vector2(grid_pos.x, grid_pos.y - 1), Direction.UP)
		]
	next_checks.shuffle() #randomize a bit

	# if there is a bug right next to us, greedy snake eats
	for adjacent in next_checks:
		if Global.is_grid_pos_in_grid(adjacent.pos) and not snake_grid[adjacent.pos.x][adjacent.pos.y] and get_parent().get_parent().is_grid_pos_bug(adjacent.pos):
			return adjacent.original_dir
		
	# while we have stuff to check and no solutions
	while next_checks.size() != 0:
		for pair in next_checks: # add each spot to check to a list
			to_check.append(pair)
		next_checks.clear() # clear the list of spots to check in next iteration

		# while we have spots to check on current depth
		while to_check.size() != 0:
			var current_check: Pair = to_check.pop_front()
			# or current_check.pos in checked[current_check.original_dir]
			if not Global.is_grid_pos_in_grid(current_check.pos) or snake_grid[current_check.pos.x][current_check.pos.y] or current_check.pos in checked: # can't go this way
				continue
			
			# mark this spot as checked (for this direction)
			#checked[current_check.original_dir].append(current_check.pos)
			checked.append(current_check.pos)
			
			if current_check.pos == pellet_pos: # if we reached the pellet, this is a solution
				return current_check.original_dir
			else: # append left, up, right, down
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(1, 0), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(-1, 0), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(0, 1), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(0, -1), current_check.original_dir))
	
	return Direction.NONE # no path at all, so don't move

func move(snake_grid):
	if _enabled:
		# store previous before moving
		_previous_head_positions.push_front(position)
		if(_previous_head_positions.size() == 100): #don't track forever
			_previous_head_positions.remove_at(99)
		
		# initial grows
		if(queued_segments != 0):
			_grow_snake()
			queued_segments -= 1
		
		# get my grid position
		var grid_pos = Global.to_grid_position(position)
		
		var pellet_pos = Global.to_grid_position(get_parent().get_parent().find_child("Pellet").position)
		
		# determine next movement
		_direction = _dir_to_pellet(grid_pos, pellet_pos, snake_grid)
		if _direction == Direction.NONE:
			return
			
		# delete self from snake grid
		emit_signal("snake_not_at", grid_pos) #head
		for seg in $Segments.get_children():
			emit_signal("snake_not_at", Global.to_grid_position(seg.position)) #segments
		
		# move according to direction
		grid_pos += _MOVEMENT_BY_DIR[_direction]
		
		# translate back to global and set position
		position = Global.to_global_position(grid_pos)
		
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
		
		# fix rotations
		for i in range(0, segments.size()):
			var segment = segments[i]
			if i == segments.size() - 1: # head 
				segment.find_child("Sprite").rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, position)]
			else:
				var next_segment = segments[i+1]
				segment.find_child("Sprite").rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, next_segment.position)]

		# fix head's rotation
		rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction]
		
		# add updated self back to snake grid
		emit_signal("snake_at", grid_pos) #head
		for seg in $Segments.get_children():
			emit_signal("snake_at", Global.to_grid_position(seg.position)) #segments

func is_snake_at(grid_pos: Vector2):
	if grid_pos == Global.to_grid_position(position):
		return true
	for segment in $Segments.get_children():
		if grid_pos == Global.to_grid_position(segment.position):
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

func _grow_snake():
	# grow snake, add segment at previous location
	var new_segment = load("res://snake_segment.tscn").instantiate()
	new_segment.position = position 
	new_segment.visible = false # initially, hide segment so it appears to 'pop in' next time snake moves
	$Segments.add_child(new_segment)

func _shrink_snake():
	if $Segments.get_child_count() != 0:
		var removed_seg = $Segments.get_child($Segments.get_child_count() - 1)
		$Segments.remove_child(removed_seg)
		removed_seg.queue_free()

func reset():
	$HeadSprite.modulate = color
	_enabled = false
	# free segs
	for segment in $Segments.get_children():
		segment.queue_free()
	# back to start
	position = STARTING_POS
	rotation_degrees = STARTING_ROT
	# clear prev pos
	_previous_head_positions.clear()
	# free segs
	queued_segments = QUEUED_SEGMENTS_DEFAULT


func disable():
	_enabled = false

func enable():
	_enabled = true

const POISON_SEGMENTS_REMOVED = 3
func _on_bug_body_entered(body):
	if body.has_method("poison"): # terrible $HACK$
		for i in range(0, POISON_SEGMENTS_REMOVED):
			_shrink_snake()
			$PoisonTimer.start()
	else:
		$YumTimer.start()
	
	#call_deferred("_grow_snake")
	queued_segments += 1
	body.queue_free()
	emit_signal("ate_bug", body.position)

const POISON_COLOR = Color(109/255.0, 78/255.0, 255/255.0)
const YUM_COLOR = Color(79/255.0, 255/255.0, 67/255.0)
const BASE_COLOR = Color(255/255.0, 133/255.0, 0/255.0)
const BASE_COLOR2 = Color(147/255.0, 255/255.0, 139/255.0)
const BASE_COLOR3 = Color(255/255.0, 255/255.0, 255/255.0)
var color = BASE_COLOR

func set_base_color(c):
	if c == 1:
		color = BASE_COLOR2
	elif c == 2:
		color = BASE_COLOR3
	else:
		color = BASE_COLOR

func _process(delta):
	modulate.a = lerp(modulate.a, 1.0, 20 * delta)
	
	if not $PoisonTimer.is_stopped():
		var c = Color(lerp($HeadSprite.modulate.r, POISON_COLOR.r, 8 * delta), lerp($HeadSprite.modulate.g, POISON_COLOR.g, 10 * delta), lerp($HeadSprite.modulate.b, POISON_COLOR.b, 10 * delta))
		recolor_parts(c)
	elif not $YumTimer.is_stopped():
		var c = Color(lerp($HeadSprite.modulate.r, YUM_COLOR.r, 8 * delta), lerp($HeadSprite.modulate.g, YUM_COLOR.g, 10 * delta), lerp($HeadSprite.modulate.b, YUM_COLOR.b, 10 * delta))
		recolor_parts(c)
	else:
		var c = Color(lerp($HeadSprite.modulate.r, color.r, 8 * delta), lerp($HeadSprite.modulate.g, color.g, 10 * delta), lerp($HeadSprite.modulate.b, color.b, 10 * delta))
		recolor_parts(c)

func recolor_parts(c):
	$HeadSprite.modulate = c
	for seg in $Segments.get_children():
		seg.modulate = c

func _ready():
	$HeadSprite.modulate = color
	modulate.a = 0
