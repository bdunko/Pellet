extends Node2D

func _ready():
	$PelletPreview.visible = false

func _input(event):
	if event is InputEventMouseMotion:
		var grid_index = Global.to_grid_index(event.position)
		var pos = Global.to_global_position(grid_index)
		if Global.is_in_grid(event.position) and $Pellets.get_child_count() < Global.MAX_PELLETS:
			$PelletPreview.position = pos
			$PelletPreview.visible = true
		else:
			$PelletPreview.visible = false
	elif event is InputEventMouseButton:
		var grid_index = Global.to_grid_index(event.position)
		var pos = Global.to_global_position(grid_index)
		if Global.is_in_grid(event.position):
			var empty := true
			for child in $Pellets.get_children():
				if child.position == pos:
					empty = false
					break
			if empty == true and $Pellets.get_child_count() < Global.MAX_PELLETS:
				var new_pellet = load("res://pellet.tscn").instantiate()
				new_pellet.position = pos
				$Pellets.add_child(new_pellet)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
