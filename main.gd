extends Node2D

enum State {
	WAITING, PLAYING, DEAD
}

var state = State.WAITING

const TIME_FORMAT = "[center]You lasted [color=lightblue]%d[/color] seconds.[/center]"
const SCORE_FORMAT = "[center]And earned [color=green]%d[/color] points![/center]"
const COMMENTARY_FORMAT = "[center]%s[/center]"
const TIP_FORMAT = "[center]- Tip -\n%s"
const tips = ["You can touch the snake's body.\nOnly the head is deadly.", "You get some points for surviving.\nBut you get more for making the\nsnake eat other enemies."]

var SCORE_TO_COMMENTARY = {
	0 : "You let it catch you, didn't you..?",
	15 : "Give it another try!",
	250 : "Not bad... but you can do better.",
	1000 : "You're getting pretty good!",
	2500 : "Wow! Nice job!",
	5000 : "Hey, that's better than my high score... :(",
	10000 : "Amazing score!!! Incredible!"
}

var score = 0

func _commentary_for_score():
	var comment = ""
	for key in SCORE_TO_COMMENTARY.keys():
		if score >= key:
			comment = SCORE_TO_COMMENTARY[key]
		else:
			return comment

func _update_dead_info():
	$DeadInfo/Time.text = TIME_FORMAT % int(time_elapsed)
	$DeadInfo/Score.text = SCORE_FORMAT % score
	$DeadInfo/Tip.text = TIP_FORMAT % Global.choose_one(tips)
	$DeadInfo/Commentary.text = COMMENTARY_FORMAT % _commentary_for_score()

func _on_pellet_dead():
	if state != State.DEAD:
		state = State.DEAD
		$Snake.disable()
		$Pellet.disable()
		_update_dead_info()
		$DeadInfo.visible = true

func _on_reset():
	$Snake.reset()
	$Pellet.reset()
	$Pellet.enable()
	state = State.WAITING
	score = 0
	$StartupInfo.visible = true
	$DeadInfo.visible = false
	$UI/Score.text = str(0)
	$UI/Time.text = str(15)

func _on_pellet_moved():
	if state == State.WAITING:
		state = State.PLAYING
		time_elapsed = 0
		$Snake.enable()
		$StartupInfo.visible = false

var time_elapsed = 0
var since_score = 0
func _process(delta: float) -> void:
	if state == State.PLAYING:
		time_elapsed += delta
		since_score += delta
		if since_score > 1:
			since_score -= 1
			score += 1
		$UI/Score.text = str(score)

func _input(_event):
	if Input.is_action_just_pressed("reset") and state == State.DEAD:
		_on_reset()
