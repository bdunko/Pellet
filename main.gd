extends Node2D

const GRID_OFFSET := Vector2(80, 10)
const CELL_SIZE := Vector2(10, 10)
const GRID_SIZE := Vector2(16, 16)
const MAX_PELLETS := 5

func _ready():
	$PelletPreview.visible = false

func _to_grid_index(pos: Vector2) -> Vector2:
	pos -= GRID_OFFSET
	var x = int(pos.x / CELL_SIZE.x)
	var y = int(pos.y / CELL_SIZE.y)
	
	# $HACK$
	if pos.x < 0:
		x = -1
	if pos.y < 0:
		y = -1
	
	return Vector2(x, y)

func _to_position(grid_index: Vector2) -> Vector2:
	var pos = grid_index * 10
	pos += GRID_OFFSET
	pos += CELL_SIZE/2
	return pos

func _is_in_grid(pos: Vector2) -> bool:
	var indices := _to_grid_index(pos)
	return indices.x >= 0 and indices.y >= 0 and indices.x < GRID_SIZE.x and indices.y < GRID_SIZE.y

func _input(event):
	if event is InputEventMouseMotion:
		var grid_index = _to_grid_index(event.position)
		var pos = _to_position(grid_index)
		if _is_in_grid(event.position) and $Pellets.get_child_count() < MAX_PELLETS:
			$PelletPreview.position = pos
			$PelletPreview.visible = true
		else:
			$PelletPreview.visible = false
	elif event is InputEventMouseButton:
		var grid_index = _to_grid_index(event.position)
		var pos = _to_position(grid_index)
		if _is_in_grid(event.position):
			var empty := true
			for child in $Pellets.get_children():
				if child.position == pos:
					empty = false
					break
			if empty == true and $Pellets.get_child_count() < MAX_PELLETS:
				var new_pellet = load("res://pellet.tscn").instantiate()
				new_pellet.position = pos
				$Pellets.add_child(new_pellet)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
