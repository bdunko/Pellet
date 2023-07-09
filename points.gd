extends Label

const FORMAT = "+%d"

var alpha_target = 1.0

func _ready():
	modulate.a = 0.1

func setup(pts):
	text = FORMAT % pts

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	modulate.a = lerp(modulate.a, alpha_target, 30 * delta)
	if modulate.a == 0:
		queue_free()
	position.y -= 80 * delta

func _on_visible_timer_timeout():
	alpha_target = 0.0
