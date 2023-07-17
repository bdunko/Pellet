extends Label

const FORMAT = "+%d"
const FORMAT_BONUS = "Full Clear Bonus!\n+%d"

var alpha_target = 1.0
var speed = 80

func _ready():
	modulate.a = 0.1

func setup(pts):
	text = FORMAT % pts

func setup_bonus(pts):
	text = FORMAT_BONUS % pts
	$VisibleTimer.wait_time = 0.8
	speed = 22

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	modulate.a = lerp(modulate.a, alpha_target, 30 * delta)
	if modulate.a == 0:
		queue_free()
	position.y -= speed * delta

func _on_visible_timer_timeout():
	alpha_target = 0.0
