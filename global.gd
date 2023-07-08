extends Node

const GRID_OFFSET := Vector2(80, 10)
const CELL_SIZE := Vector2(10, 10)
const GRID_SIZE := Vector2(16, 16)
const MAX_PELLETS := 5
const RESOLUTION := Vector2(320, 180)

func to_grid_position(pos: Vector2) -> Vector2:
	pos -= GRID_OFFSET
	var x = int(pos.x / CELL_SIZE.x)
	var y = int(pos.y / CELL_SIZE.y)
	
	# $HACK$
	if pos.x < 0:
		x = -1
	if pos.y < 0:
		y = -1
	
	return Vector2(x, y)

func to_global_position(grid_index: Vector2) -> Vector2:
	var pos = grid_index * 10
	pos += GRID_OFFSET
	pos += CELL_SIZE/2
	return pos

func is_grid_pos_in_grid(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.y >= 0 and grid_pos.x < GRID_SIZE.x and grid_pos.y < GRID_SIZE.y

func is_global_pos_in_grid(pos: Vector2) -> bool:
	var indices := Global.to_grid_position(pos)
	return indices.x >= 0 and indices.y >= 0 and indices.x < GRID_SIZE.x and indices.y < GRID_SIZE.y

func rand_grid_pos() -> Vector2:
	return Vector2(RNG.randi_range(0, int(GRID_SIZE.x - 1)), RNG.randi_range(0, int(GRID_SIZE.y -1)))

var RNG = RandomNumberGenerator.new()

func choose_one(options: Array[Variant]):
	assert(options.size() != 0, "No options in array!")
	return options[RNG.randi_range(0, options.size()-1)]
