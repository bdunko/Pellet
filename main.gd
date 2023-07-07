extends Node2D

func _ready():
	$PelletPreview.visible = false

func _input(event):
	if event is InputEventMouseMotion:
		var grid_index = Global.to_grid_position(event.position)
		var pos = Global.to_global_position(grid_index)
		if Global.is_global_pos_in_grid(event.position) and $Pellets.get_child_count() < Global.MAX_PELLETS:
			$PelletPreview.position = pos
			$PelletPreview.visible = true
		else:
			$PelletPreview.visible = false
	elif event is InputEventMouseButton:
		var grid_pos = Global.to_grid_position(event.position)
		if Global.is_grid_pos_in_grid(grid_pos):
			# check pellet limit
			if $Pellets.get_child_count() >= Global.MAX_PELLETS:
				return;
			
			# make sure snake isn't here
			if Global.to_grid_position($Snake.position) == grid_pos:
				return;
			
			# make sure there isn't already a pellet here
			for child in $Pellets.get_children():
				if Global.to_grid_position(child.position) == grid_pos:
					return
			
			var new_pellet = load("res://pellet.tscn").instantiate()
			new_pellet.position = Global.to_global_position(grid_pos)
			$Pellets.add_child(new_pellet)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_snake_dead():
	print("You lose!")
