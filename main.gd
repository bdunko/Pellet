extends Node2D

enum State {
	WAITING, PLAYING, DEAD
}

const DEFAULT_BULLET_SPEED = 1
const FAST_BULLET_SPEED = 1.4
var bullet_speed_multiplier = DEFAULT_BULLET_SPEED

var state = State.WAITING
var highscore = 0

const HIGH_SCORE_FORMAT = "High Score: %d"
const LEVEL_FORMAT = "[center]Level %d[/center]"
const TIME_FORMAT = "[center]You lasted [color=lightblue]%d[/color] seconds.[/center]"
const SCORE_FORMAT = "[center]And earned [color=green]%d[/color] points![/center]"
const COMMENTARY_FORMAT = "[center]%s[/center]"
const TIP_FORMAT = "[center]- Tip -\n%s"
const tips = ["The snake can eat bugs.\nIt can block bullets too!",
 "You can touch the snake's body.\nOnly the head is deadly.",
 "You get some points for surviving.\nBut you get more for making the\nsnake eat other enemies.",
 "If you have the snake eat every enemy,\nyou'll get a score bonus.",
 "There's a pretty amazing gimmick if you reach the max level...\nJust saying..."]

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
const LEVEL_TIMES = [-1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
var MAX_LEVEL = LEVEL_TIMES.size()
var MAX_LEVEL_TIME = 30

var GRID_COLORS = [null, Color(119/255.0, 233/255.0, 71/255.0), Color(202/255.0, 205/255.0, 71/255.0), Color(181/255.0, 181/255.0, 71/255.0), Color(222/255.0, 181/255.0, 190/255.0),
Color(113/255.0, 225/255.0, 155/255.0), Color(234/255.0, 226/255.0, 155/255.0), Color(203/255.0, 105/255.0, 145/255.0),
Color(231/255.0, 121/255.0, 41/255.0), Color(100/255.0, 28/255.0, 55/255.0), Color(168/255.0, 85/255.0, 211/255.0), Color(56/255.0, 134/255.0, 170/255.0), 
Color(106/255.0, 88/255.0, 225/255.0), Color(0, 0, 0)]
var MAX_GRID_COLOR = Color(0, 0, 0)
var grid_color= GRID_COLORS[1]

const NEXT_LEVEL_TIPS = [
	"null",
	"null", 
	"Avoid Beetle bullets!\n(Snake eats bugs)", 
	"More Beetles!",
	"Look out for Ants!",
	"Snakes hate poisonous Spiders!",
	"Speed up!",
	"Flee the Hornet!",
	"Double trouble!",
	"Watch for Dragonflies!",
	"Triple trouble!",
	"Speed up!",
	"Bouncing-bullet Moths!",
	"Good luck..."
]
const MAX_LEVEL_TIP = "Keep it up!"

var score = 0
var level = 1

const DEFAULT_SPAWN_COUNT = 1
const MAX_SPAWN_COUNT = 15
var spawn_count = DEFAULT_SPAWN_COUNT
var enemy_pool = [[BEETLE, BEETLE_SPAWN]]
const BEETLE = preload("res://beetle.tscn")
const BEETLE_SPAWN = SpawnMode.GRID_NO_BORDER
const DRAGONFLY = preload("res://dragonfly.tscn")
const DRAGONFLY_SPAWN = SpawnMode.GRID_NO_BORDER
const SPIDER = preload("res://spider.tscn")
const SPIDER_SPAWN = SpawnMode.GRID_NO_BORDER
const HORNET = preload("res://hornet.tscn")
const HORNET_SPAWN = SpawnMode.BOTTOM
const ANT = preload("res://ant.tscn")
const ANT_SPAWN = SpawnMode.FRAME
const MOTH = preload("res://moth.tscn")
const MOTH_SPAWN = SpawnMode.GRID
const SNAKE = preload("res://snake.tscn")
const SNAKE_SPAWN = SpawnMode.GRID
const MOON = preload("res://moon.tscn")
const MOON_SPAWN = SpawnMode.MOON
const MOON_POSITION = Vector2(283, 32)

enum SpawnMode {
	GRID, GRID_NO_BORDER, FRAME, BOTTOM, MOON
}

const SAFE_SPAWN_DIST = 10
func _try_find_legal_position(spawnmode, max_attempts = 25):
	var tries = 0
	while tries < max_attempts:
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
		
		if is_grid_pos_full(rand_pos):
			continue
		
		return rand_pos
	return null

func _spawn_enemy(enemy, spawnmode):
	if spawnmode == SpawnMode.GRID or spawnmode == SpawnMode.GRID_NO_BORDER:
		var rand_pos = _try_find_legal_position(spawnmode)
		if rand_pos != null:
			var bug = enemy.instantiate()
			bug.position = Global.to_global_position(rand_pos)
			queued_bugs.append(bug)
			call_deferred("_spawn_queued_bugs")
			return
	elif spawnmode == SpawnMode.FRAME:
		var tries = 0
		
		while tries < 10:
			tries += 1
			
			# vertical or horizontal?
			var vertical = Global.RNG.randi_range(0, 1) == 1
			var x = -1
			var y = -1
			if vertical:
				x = 0 if Global.RNG.randi_range(0, 1) == 1 else int(Global.GRID_SIZE.x)-1
				y = Global.RNG.randi_range(1, int(Global.GRID_SIZE.y) - 1)
			else:
				x = Global.RNG.randi_range(1, int(Global.GRID_SIZE.x) - 1)
				y = 0 if Global.RNG.randi_range(0, 1) == 1 else int(Global.GRID_SIZE.y)-1
			
			var rand_pos = Vector2(x, y)
			
			# if too close to player, reject
			var pellet_grid_pos = Global.to_grid_position($Pellet.position)
			var total_dist = abs(pellet_grid_pos.x - rand_pos.x) + abs(pellet_grid_pos.y - rand_pos.y)
			if total_dist < SAFE_SPAWN_DIST:
				continue
			#spawn the ant
			var bug = enemy.instantiate()
			bug.position = Global.to_global_position(Vector2(x, y))
			#nudge onto wall...
			if x == 0: #left wall
				bug.position -= Vector2(6, 0)
			elif x == Global.GRID_SIZE.x - 1: #right wall
				bug.position += Vector2(6, 0)
			elif y == 0: #top wall
				bug.position -= Vector2(0, 6)
			else: #bottom wall
				bug.position += Vector2(0, 6)
			bug.setup(vertical)
			queued_bugs.append(bug)
			call_deferred("_spawn_queued_bugs")
			return
	elif spawnmode == SpawnMode.BOTTOM:
		var bug = enemy.instantiate()
		bug.position = Vector2(Global.RNG.randi_range(int(Global.RESOLUTION.x/2) - 80, int(Global.RESOLUTION.y/2) + 80), Global.RESOLUTION.y + 10)
		queued_bugs.append(bug)
		call_deferred("_spawn_queued_bugs")
		return
	elif spawnmode == SpawnMode.MOON:
		var moon = enemy.instantiate()
		moon.position = MOON_POSITION
		queued_bugs.append(moon)
		call_deferred("_spawn_queued_bugs")
		return

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
	assert(LEVEL_TIMES.size() == NEXT_LEVEL_TIPS.size())
	_update_level()
	$NextLevelInfo.visible = false
	$Grid.self_modulate = grid_color

func _spawn_new_snake(speed = 0):
	var rand_pos = _try_find_legal_position(SpawnMode.GRID, 200) #try really hard to spawn this snek
	if rand_pos != null:
		var snek = SNAKE.instantiate()
		snek.position = Global.to_global_position(rand_pos)
		snek.no_free_segments()
		snek.enable()
		for s in speed:
			snek.speed_up()
		snek.ate_bug.connect(on_bug_killed)
		$Snakes.add_child(snek)

func _update_level():
	$NextLevelInfo.visible = true
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
	# terrible horrible code structure $HACK$
	var forced_spawns = 0
	if level == 1:
		pass
	if level == 2:
		enemy_pool.append([BEETLE, BEETLE_SPAWN])
	if level == 3:
		spawn_count += 1 
	elif level == 4:
		enemy_pool.append([ANT, ANT_SPAWN])
		_spawn_enemy(ANT, ANT_SPAWN)
		forced_spawns = 1
	elif level == 5: 
		$Sky.next_sky() #day
		_spawn_enemy(SPIDER, SPIDER_SPAWN)
	elif level == 6:
		enemy_pool.append([SPIDER, SPIDER_SPAWN]) # add spider next time so only 1 spawns on 5
		$Snakes/Snake.speed_up()
	elif level == 7: 
		_spawn_enemy(HORNET, HORNET_SPAWN)
		forced_spawns = 1
	elif level == 8:
		$Sky.next_sky() #evening
		_spawn_new_snake(1)
	elif level == 9:
		enemy_pool.append([DRAGONFLY, DRAGONFLY_SPAWN])
		_spawn_enemy(DRAGONFLY, DRAGONFLY_SPAWN)
		forced_spawns = 1
	elif level == 10:
		_spawn_new_snake(1)
	elif level == 11: 
		$Sky.next_sky() # night
		for snake in $Snakes.get_children():
			snake.speed_up()
	elif level == 12: 
		enemy_pool.append([MOTH, MOTH_SPAWN])
		_spawn_enemy(MOTH, MOTH_SPAWN)
		_spawn_enemy(MOTH, MOTH_SPAWN)
		forced_spawns = 2
		spawn_count += 1 #5
	elif level == 13: #moon
		_spawn_enemy(MOON, MOON_SPAWN)
		spawn_count += 1
		pass
	elif level >= 14: #challenge
		$Sky.next_sky() #midnight
		bullet_speed_multiplier = FAST_BULLET_SPEED
		if level == 14:
			_spawn_enemy(HORNET, HORNET_SPAWN)
			forced_spawns = 1
		if spawn_count < MAX_SPAWN_COUNT:
			spawn_count += 1
		if level == 17:
			_spawn_enemy(MOON, MOON_SPAWN)
		if level == 20:
			_spawn_enemy(MOON, MOON_SPAWN)
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
	enemy_pool.clear()
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
	for bug in $Bugs.get_children():
		bug.queue_free()
	while $Snakes.get_child_count() != 1:
		$Snakes.get_child(1).queue_free()
		$Snakes.remove_child($Snakes.get_child(1))
	for bullet in $Bullets.get_children():
		bullet.queue_free()
	bullet_speed_multiplier = DEFAULT_BULLET_SPEED
	_update_level()
	$NextLevelInfo.visible = false # $HACK$, must be after _update_level

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

var POINTS_TEXT = preload("res://points.tscn")
const FULL_CLEAR_BONUS = 10
func on_bug_killed(bug_pos):
	score += level * 10
	var text = POINTS_TEXT.instantiate()
	text.setup(level * 10)
	text.position = bug_pos - Vector2(50, 0)
	add_child(text)
	$UI/Score.text = str(score)
	if $Bugs.get_child_count() == 1: #ate last bug
		var full_clear_bonus = (FULL_CLEAR_BONUS * level) + (int($UI/Time.text) * level)
		score += full_clear_bonus
		$UI/Score.text = str(score) 
		level += 1
		_update_level()
		var bonus_text = POINTS_TEXT.instantiate()
		bonus_text.setup_bonus(full_clear_bonus)
		bonus_text.position = Vector2(Global.RESOLUTION.x/2 - 50, 15)
		add_child(bonus_text)
	if level >= 14 and $Bugs.get_child_count() < 15:
		_spawn_rand_enemies(1)
