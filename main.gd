extends Node2D

enum State {
	WAITING, PLAYING, DEAD
}

var state = State.WAITING
var highscore = 0

const CLEAR_BONUS_FORMAT = "Clear Bonus +%d!"
const HIGH_SCORE_FORMAT = "High Score: %d"
const LEVEL_FORMAT = "[center]Level %d[/center]"
const TIME_FORMAT = "[center]You lasted [color=lightblue]%d[/color] seconds.[/center]"
const SCORE_FORMAT = "[center]And earned [color=green]%d[/color] points![/center]"
const COMMENTARY_FORMAT = "[center]%s[/center]"
const TIP_FORMAT = "[center]- Tip -\n%s"
const tips = ["The snake can eat bugs.\nIt can block bullets too!",
 "You can touch the snake's body.\nOnly the head is deadly.",
 "You get some points for surviving.\nBut you get more for making the\nsnake eat other enemies.",
 "If you have the snake eat every enemy,\nyou'll get a score bonus."]

var SCORE_TO_COMMENTARY = {
	0 : "You let it catch you, didn't you..?",
	15 : "Give it another try!",
	250 : "Not bad... but you can do better.",
	1000 : "You're getting pretty good!",
	2500 : "Wow! Nice job!",
	5000 : "Hey, that's better than my high score... :(",
	10000 : "Amazing score!!! Incredible!"
}

#                    0,  1   2   3   4   5   6   7   8   9   10  11, 12
#                    -1  5  15  15 15 20 20 20 25 25 25 30 30
const LEVEL_TIMES = [-1, 5, 15, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3]
var MAX_LEVEL = LEVEL_TIMES.size()
var MAX_LEVEL_TIME = 40

var GRID_COLORS = [null, Color(119/255.0, 233/255.0, 71/255.0), Color(202/255.0, 205/255.0, 71/255.0), Color(222/255.0, 181/255.0, 190/255.0),
Color(113/255.0, 225/255.0, 155/255.0), Color(234/255.0, 226/255.0, 155/255.0), Color(203/255.0, 105/255.0, 145/255.0),
Color(231/255.0, 121/255.0, 41/255.0), Color(100/255.0, 28/255.0, 55/255.0), Color(56/255.0, 134/255.0, 170/255.0), 
Color(106/255.0, 88/255.0, 225/255.0), Color(255/255.0, 190/255.0, 62/255.0), Color(0, 0, 0)]
var MAX_GRID_COLOR = Color(0, 0, 0)
var grid_color= GRID_COLORS[1]

const NEXT_LEVEL_TIPS = [
	"null",
	"null", 
	"Avoid Beetle bullets!\n(Snake eats bugs)", 
	"Watch for Dragonflies!",
	"Snake speed up!",
	"Snakes hate poisonous Spiders!",
	"Flee the Hornet!",
	"Watch for frame Ants!",
	"Bullet speed up!",
	"Dodge bouncing Butterflies!",
	"Double trouble!",
	"Snake turrets!",
	"Good luck..."
]
const MAX_LEVEL_TIP = "Keep it up!"

var score = 0
var level = 1

const DEFAULT_SPAWN_COUNT = 2
const MAX_SPAWN_COUNT = 9
var spawn_count = DEFAULT_SPAWN_COUNT
var enemy_pool = []
const BEETLE = preload("res://beetle.tscn")
const BEETLE_SPAWN = SpawnMode.GRID_NO_BORDER
const DRAGONFLY = preload("res://dragonfly.tscn")
const DRAGONFLY_SPAWN = SpawnMode.GRID
const SPIDER = preload("res://spider.tscn")
const SPIDER_SPAWN = SpawnMode.GRID
# HORNET
const HORNET_SPAWN = SpawnMode.BOTTOM
# ANTS
const ANT_SPAWN = SpawnMode.FRAME
# BUTTERFLY
const BUTTERFLY_SPAWN = SpawnMode.GRID

enum SpawnMode {
	GRID, GRID_NO_BORDER, FRAME, BOTTOM
}

const SAFE_SPAWN_DIST = 10
func _spawn_enemy(enemy, spawnmode):
	if spawnmode == SpawnMode.GRID or spawnmode == SpawnMode.GRID_NO_BORDER:
		var tries = 0
		while tries < 25:
			tries += 1
			var rand_pos = Global.rand_grid_pos()
			# if border and GRID NO BETTER, reject
			if spawnmode == SpawnMode.GRID_NO_BORDER and (rand_pos.x == 0 or rand_pos.x == Global.GRID_SIZE.x-1 or rand_pos.y == 0 or rand_pos.y == Global.GRID_SIZE.y-1):
				continue
			
			# if too close to player, reject
			var pellet_grid_pos = Global.to_grid_position($Pellet.position)
			var total_dist = abs(pellet_grid_pos.x - rand_pos.x) + abs(pellet_grid_pos.y - rand_pos.y)
			if total_dist < SAFE_SPAWN_DIST:
				continue
			
			# if already occupied, reject
			if not is_grid_pos_full(rand_pos):
				var bug = enemy.instantiate()
				bug.position = Global.to_global_position(rand_pos)
				queued_bugs.append(bug)
				call_deferred("_spawn_queued_bugs")
				return
	elif spawnmode == SpawnMode.FRAME:
		pass
	elif spawnmode == SpawnMode.BOTTOM:
		pass

var queued_bugs = []
func _spawn_queued_bugs():
	for bug in queued_bugs:
		$Bugs.add_child(bug)
	queued_bugs.clear()

func _spawn_rand_enemies(num):
	for i in range(0, num):
		var enemy_pair = Global.choose_one(enemy_pool)
		_spawn_enemy(enemy_pair[0], enemy_pair[1])

func _ready():
	assert(LEVEL_TIMES.size() == GRID_COLORS.size())
	_update_level()
	$NextLevelInfo.visible = false
	$Grid.self_modulate = grid_color

func _update_level():
	$NextLevelInfo.visible = true
	$NextLevelInfo/ClearBonus.visible = false
	if level >= MAX_LEVEL:
		$UI/Time.text = str(MAX_LEVEL_TIME)
		grid_color = MAX_GRID_COLOR
		$NextLevelInfo.next_level(MAX_LEVEL_TIP)
	else:
		$UI/LevelLabel.text = LEVEL_FORMAT % level
		$UI/Time.text = str(LEVEL_TIMES[level])
		grid_color = GRID_COLORS[level]
		$NextLevelInfo.next_level(NEXT_LEVEL_TIPS[level])
	
	# add enemies and stuff
	var forced_spawns = 0
	
	if level == 1:
		pass
	if level == 2: # beetle
		enemy_pool.append([BEETLE, BEETLE_SPAWN])
	elif level == 3: # dragonfly
		spawn_count += 1 #3
		enemy_pool.append([DRAGONFLY, DRAGONFLY_SPAWN])
		_spawn_enemy(DRAGONFLY, DRAGONFLY_SPAWN)
		forced_spawns = 1
	elif level == 4: # snake speed
		$Sky.next_sky() # day
		$Snakes/Snake.speed_up()
	elif level == 5: # spider
		pass
	elif level == 6: # hornet
		pass
	elif level == 7: # ants
		$Sky.next_sky() # evening
		spawn_count += 1  #4
		forced_spawns = 2
		pass
	elif level == 8: # bullet speed
		pass
	elif level == 9: # butterfly
		forced_spawns = 2
		spawn_count += 1 #5
	elif level == 10: # snake
		$Sky.next_sky() # night
		#speed up too
		pass
	elif level == 11: #snake turrets
		pass
	elif level == 12: #moon
		spawn_count += 1 #6
		pass
	elif level >= 13: #challenge
		$Sky.next_sky() #midnight
		if spawn_count < MAX_SPAWN_COUNT:
			spawn_count += 1
	if level >= 2:
		_spawn_rand_enemies(spawn_count - forced_spawns)

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
		for snake in $Snakes.get_children():
			snake.disable()
		for bug in $Bugs.get_children():
			bug.disable()
		$Pellet.disable()
		_update_dead_info()
		$DeadInfo.on_dead()
		$NextLevelInfo.visible = false

func _on_reset():
	$Snakes/Snake.reset()
	$Pellet.reset()
	$Pellet.enable()
	$Sky.reset()
	state = State.WAITING
	if score > highscore:
		highscore = score
		$StartupInfo/HighScore.text = HIGH_SCORE_FORMAT % highscore
		$StartupInfo/HighScore.visible = true
	score = 0
	spawn_count = DEFAULT_SPAWN_COUNT
	$StartupInfo.on_reset()
	$DeadInfo.on_reset()
	$UI/Score.text = str(0)
	level = 1
	_update_level()
	$NextLevelInfo.visible = false
	for bug in $Bugs.get_children():
		bug.queue_free()
	if $Snakes.find_child("Snake2"):
		$Snakes/Snake2.queue_free()
	for bullet in $Bullets.get_children():
		bullet.queue_free()

func _on_pellet_moved():
	if state == State.WAITING:
		state = State.PLAYING
		time_elapsed = 0
		for snake in $Snakes.get_children():
			snake.enable()
		$StartupInfo.on_playing()

var time_elapsed = 0
var since_second = 0
const GRID_COLOR_WEIGHT = 7
func _process(delta: float) -> void:
	# lerp grid towards color
	var lerp_amt = GRID_COLOR_WEIGHT * delta
	$Grid.self_modulate = Color(lerp($Grid.self_modulate.r, grid_color.r, lerp_amt), lerp($Grid.self_modulate.g, grid_color.g, lerp_amt), lerp($Grid.self_modulate.b, grid_color.b, lerp_amt))
	
	if state == State.PLAYING:
		time_elapsed += delta
		since_second += delta
		if since_second > 1:
			since_second -= 1
			_on_second_passed()
		$UI/Score.text = str(score)

func _input(_event):
	if Input.is_action_just_pressed("reset") and state == State.DEAD:
		_on_reset()

func _on_second_passed():
	score += level
	$UI/Time.text = str(int($UI/Time.text) - 1) 
	if $UI/Time.text == "0":
		level += 1
		_update_level()

func is_grid_pos_full(grid_pos):
	# are there any bug at pos?
	for bug in $Bugs.get_children():
		if Global.to_grid_position(bug.position) == grid_pos:
			return true
	# is snake at pos?
	if is_grid_pos_snake(grid_pos):
		return true
	# is player at pos?
	if Global.to_grid_position($Pellet.position) == grid_pos:
		return true
	return false

func is_grid_pos_snake(grid_pos):
	for snake in $Snakes.get_children():
		if snake.is_snake_at(grid_pos):
			return true
	return false

const FULL_CLEAR_BONUS = 10
func _on_snake_ate_bug():
	score += level * 10
	$UI/Score.text = str(score)
	if $Bugs.get_child_count() == 1: #ate last bug
		var full_clear_bonus = (FULL_CLEAR_BONUS * level) + (int($UI/Time.text) * level)
		score += full_clear_bonus
		$UI/Score.text = str(score) 
		level += 1
		_update_level()
		$NextLevelInfo/ClearBonus.text = CLEAR_BONUS_FORMAT % full_clear_bonus
		$NextLevelInfo/ClearBonus.visible = true
