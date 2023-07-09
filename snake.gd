extends Node2D

signal ate_bug

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
var _enabled = false

@onready var STARTING_POS = position
@onready var STARTING_ROT = rotation_degrees
const FREE_SEGMENTS_MAX = 10
var free_segments = FREE_SEGMENTS_MAX

@onready var BASE_SPEED = $Timer.wait_time
const MORE_SPEED = 0.19

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
			if not Global.is_grid_pos_in_grid(current_check.pos) or get_parent().get_parent().is_grid_pos_snake(current_check.pos) or current_check.pos in checked: # can't go this way
				continue
			
			checked.append(current_check.pos)
			
			if current_check.pos == pellet_pos:
				return current_check.original_dir # found a path
			else: # append left, up, right, down
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(1, 0), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(-1, 0), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(0, 1), current_check.original_dir))
				next_checks.append(Pair.new().setup(current_check.pos + Vector2(0, -1), current_check.original_dir))
	
	# couldn't find path, pick a legal direction
	return Direction.UP 

func _move():
	if _enabled:
		# store previous before moving
		_previous_head_positions.push_front(position)
		if(_previous_head_positions.size() == 100): #don't track forever
			_previous_head_positions.remove_at(99)
		
		# initial grows
		if(free_segments != 0):
			_grow_snake()
			free_segments -= 1
		
		# get my grid position
		var grid_pos = Global.to_grid_position(position)
		
		var pellet_pos = Global.to_grid_position(get_parent().get_parent().find_child("Pellet").position)
		
		# determine next movement
		_direction = _dir_to_pellet(grid_pos, pellet_pos)
		
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
			if i == segments.size() - 1: # head case
				segment.find_child("Sprite").rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, position)]
			else:
				var next_segment = segments[i+1]
				segment.find_child("Sprite").rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction_to(segment.position, next_segment.position)]
		
		# fix head's rotation
		rotation_degrees = _ROTATION_DEGREES_BY_DIR[_direction]

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
	$HeadSprite.modulate = BASE_COLOR
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
	free_segments = FREE_SEGMENTS_MAX
	$Timer.wait_time = BASE_SPEED

func speed_up():
	$Timer.wait_time = MORE_SPEED

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
	
	call_deferred("_grow_snake")
	body.queue_free()
	emit_signal("ate_bug", body.position)

const POISON_COLOR = Color(109/255.0, 78/255.0, 255/255.0)
const YUM_COLOR = Color(79/255.0, 255/255.0, 67/255.0)
const BASE_COLOR = Color(255/255.0, 133/255.0, 0/255.0)

func _process(delta):
	modulate.a = lerp(modulate.a, 1.0, 20 * delta)
	
	if not $PoisonTimer.is_stopped():
		var color = Color(lerp($HeadSprite.modulate.r, POISON_COLOR.r, 8 * delta), lerp($HeadSprite.modulate.g, POISON_COLOR.g, 10 * delta), lerp($HeadSprite.modulate.b, POISON_COLOR.b, 10 * delta))
		set_color(color)
	elif not $YumTimer.is_stopped():
		var color = Color(lerp($HeadSprite.modulate.r, YUM_COLOR.r, 8 * delta), lerp($HeadSprite.modulate.g, YUM_COLOR.g, 10 * delta), lerp($HeadSprite.modulate.b, YUM_COLOR.b, 10 * delta))
		set_color(color)
	else:
		var color = Color(lerp($HeadSprite.modulate.r, BASE_COLOR.r, 8 * delta), lerp($HeadSprite.modulate.g, BASE_COLOR.g, 10 * delta), lerp($HeadSprite.modulate.b, BASE_COLOR.b, 10 * delta))
		set_color(color)

func set_color(color):
	$HeadSprite.modulate = color
	for seg in $Segments.get_children():
		seg.modulate = color

func no_free_segments():
	free_segments = 1

func _ready():
	$HeadSprite.modulate = BASE_COLOR
	modulate.a = 0
