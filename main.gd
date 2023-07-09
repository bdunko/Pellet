extends Node2D

# $HACK$ GOD CLASS $HACK$

enum State {
	WAITING, PLAYING, DEAD
}

const DEFAULT_BULLET_SPEED = 1
const FAST_BULLET_SPEED = 1.3
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
 "Have you noticed?\nEnemies flash before shooting.",
 "There's something pretty amazing at level 15...\nJust saying...",
 "Bugs will block bullets shot\nby other bugs."]

var SCORE_TO_COMMENTARY = {
	0 : "You let it catch you, didn't you..?",
	15 : "Give it another try!",
	250 : "Not bad... but you can do better.",
	1000 : "You're getting pretty good!",
	2500 : "Wow! Nice job!",
	5000 : "Amazing score! Incredible!",
	10000 : "Hey, that's better than my high score... :(",
	25000 : "Unbelievable score... are you cheating?"
}

const LEVEL_TIMES = [-1, 5, 15, 15, 15, 20, 20, 20, 20, 25, 25, 25, 30, 30, 30, 30]
#const LEVEL_TIMES = [-1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

var MAX_LEVEL = LEVEL_TIMES.size()
var MAX_LEVEL_TIME = 30

var GRID_COLORS = [null, Color(119/255.0, 233/255.0, 71/255.0), Color(202/255.0, 205/255.0, 71/255.0), Color(222/255.0, 181/255.0, 190/255.0),
Color(113/255.0, 225/255.0, 155/255.0), Color(234/255.0, 226/255.0, 155/255.0), Color(203/255.0, 105/255.0, 145/255.0),
Color(219/255.0, 146/255.0, 94/255.0), Color(224/255.0, 117/255.0, 157/255.0),Color(168/255.0, 85/255.0, 211/255.0), 
Color(209/255.0, 82/255.0, 73/255.0), Color(178/255.0, 222/255.0, 91/255.0), Color(91/255.0, 222/255.0, 215/255.0), 
Color(163/255.0, 111/255.0, 222/255.0), Color(222/255.0, 109/255.0, 131/255.0), Color(45/255.0, 45/255.0, 45/255.0)]
var MAX_GRID_COLOR = Color(15/255.0, 15/255.0, 15/255.0)
var grid_color= GRID_COLORS[1]

const NEXT_LEVEL_TIPS = [
	"null",
	"null", 
	"Avoid Beetle bullets!\n(Snake eats bugs)", 
	"Nice job!",
	"Watch for Dragonflies!",
	"Dragonflying!!",
	"Snakes hate poisonous Spiders!",
	"Speed up!",
	"Look out for Ants!",
	"Double trouble!",
	"Flee the Hornet!",
	"No pressure...",
	"Triple trouble!",
	"Bullet-bouncing Moths?",
	"Speed up!",
	"Uh oh..."
]
const MAX_LEVEL_TIP = "How much harder can it get...?"

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
	
	# 1 spawn per level
	spawn_count = max(2, min(int(level/2.0), MAX_SPAWN_COUNT))
	max_ants = max(1, min(int(level/6.0), MAX_ANTS_MAX))
	
	# add enemies and stuff
	# terrible horrible code structure $HACK$
	var forced_spawns = 0
	if level == 1:
		pass
	elif level == 2:
		enemy_pool.append([BEETLE, BEETLE_SPAWN])
	elif level == 4:
		enemy_pool.append([DRAGONFLY, DRAGONFLY_SPAWN])
		_spawn_enemy(DRAGONFLY, DRAGONFLY_SPAWN)
		forced_spawns = 1
	elif level == 5:
		$Sky.next_sky() #day
		_spawn_enemy(DRAGONFLY, DRAGONFLY_SPAWN)
		forced_spawns = 1
	elif level == 6: 
		_spawn_enemy(SPIDER, SPIDER_SPAWN)
		forced_spawns = 1
	elif level == 7:
		enemy_pool.append([SPIDER, SPIDER_SPAWN]) # add spider next time so only 1 spawns on 5
		speed_up()
	elif level == 8: 
		enemy_pool.append([ANT, ANT_SPAWN]) # add ants after
		_spawn_enemy(ANT, ANT_SPAWN)
		forced_spawns = 1
	elif level == 9:
		$Sky.next_sky() #evening
		$Board.next_board()
		_spawn_new_snake(1)
	elif level == 10:
		_spawn_enemy(HORNET, HORNET_SPAWN)
		forced_spawns = 1
	elif level == 12:
		$Sky.next_sky() # night
		$Board.next_board()
		_spawn_new_snake(2)
	elif level == 13: 
		enemy_pool.append([MOTH, MOTH_SPAWN])
		_spawn_enemy(MOTH, MOTH_SPAWN)
		_spawn_enemy(MOTH, MOTH_SPAWN)
		forced_spawns = 2
		spawn_count += 1 #5
	elif level == 14: 
		speed_up()
	elif level == 15: #moon
		bullet_speed_multiplier = FAST_BULLET_SPEED
		_spawn_enemy(MOON, MOON_SPAWN)
		spawn_count += 1
		pass
	elif level >= 16: #challenge
		$Sky.next_sky() #midnight
		# speed up moon
		if level == 20:
			for bug in $Bugs.get_children():
				if bug.has_method("IS_MOON"): #$HACK$
					bug.fire_faster()
	if level >= 2:
		$NextLevelSound.play()
		_spawn_rand_enemies(spawn_count - forced_spawns)

var score = 0
var level = 1

const MAX_ANTS_MAX = 3 #too annoying otherwise
var max_ants = 1
const DEFAULT_SPAWN_COUNT = 2
const MAX_SPAWN_COUNT = 8
var spawn_count = DEFAULT_SPAWN_COUNT
var enemy_pool = []
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
const SNAKE_SPAWN = SpawnMode.GRID_NO_BORDER # $HACK$ lol because it always go right
const MOON = preload("res://moon.tscn")
const MOON_SPAWN = SpawnMode.MOON
const MOON_POSITION = Vector2(281,43)

enum SpawnMode {
	GRID, GRID_NO_BORDER, FRAME, BOTTOM, MOON
}

const SAFE_SPAWN_DIST = 8 #dont' spawn next to player if possible
func _try_find_legal_position(spawnmode, max_attempts = 25):
	var tries = 0
	while tries < max_attempts:
		tries += 1
		var rand_pos = Global.rand_grid_pos()
		# if border and GRID NO BETTER, reject
		if spawnmode == SpawnMode.GRID_NO_BORDER and (rand_pos.x == 0 or rand_pos.x == Global.GRID_SIZE.x-1 or rand_pos.y == 0 or rand_pos.y == Global.GRID_SIZE.y-1):
			continue
		
		# prevent bugs spawning on top of other queued up bugs
		var fail = false
		for queued_bug in queued_bugs:
			if Global.to_grid_position(queued_bug.position) == rand_pos:
				fail = true
				break
		if fail:
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

func _num_ants():
	var count = 0
	for bug in $Bugs.get_children():
		# $HACK$
		if bug.has_method("IS_ANT"):
			count += 1
	for bug in queued_bugs:
		if bug.has_method("IS_ANT"):
			count += 1
	return count

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
				y = Global.RNG.randi_range(2, int(Global.GRID_SIZE.y) - 2)
			else:
				x = Global.RNG.randi_range(2, int(Global.GRID_SIZE.x) - 2)
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
				bug.position -= Vector2(4, 0)
			elif x == Global.GRID_SIZE.x - 1: #right wall
				bug.position += Vector2(4, 0)
			elif y == 0: #top wall
				bug.position -= Vector2(0, 4)
			else: #bottom wall
				bug.position += Vector2(0, 4)
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
		while enemy_pair[0] == ANT and _num_ants() >= max_ants:
			enemy_pair = Global.choose_one(enemy_pool) #reroll ants if too many
		_spawn_enemy(enemy_pair[0], enemy_pair[1])

func _ready():
	assert(LEVEL_TIMES.size() == GRID_COLORS.size())
	assert(LEVEL_TIMES.size() == NEXT_LEVEL_TIPS.size())
	_update_level()
	$NextLevelInfo.visible = false
	$Grid.self_modulate = grid_color

@onready var BASE_SPEED = 0.42
const MORE_SPEED = 0.36
const MOST_SPEED = 0.30
var speed_level = 0

func _spawn_new_snake(color = 0):
	var rand_pos = _try_find_legal_position(SNAKE_SPAWN, 200) #try really hard to spawn this snek
	if rand_pos != null:
		var snek = SNAKE.instantiate()
		snek.position = Global.to_global_position(rand_pos)
		snek.no_free_segments()
		snek.enable()
		snek.set_base_color(color)
		snek.ate_bug.connect(on_bug_killed)
		queued_snakes.append(snek)
		call_deferred("_add_queued_snakes")

var queued_snakes = []
func _add_queued_snakes():
	for snake in queued_snakes:
		$Snakes.add_child(snake)
	queued_snakes.clear()

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
		$DieSound.play()
		state = State.DEAD
		for snake in $Snakes.get_children():
			snake.disable()
		for bug in $Bugs.get_children():
			bug.disable()
		for bullet in $Bullets.get_children():
			bullet.disable()
		$Pellet.disable()
		_update_dead_info()
		$DeadInfo.on_dead()
		$NextLevelInfo.visible = false

func speed_up():
	speed_level += 1
	if speed_level == 1:
		$Timer.wait_time = MORE_SPEED
	else:
		$Timer.wait_time = MOST_SPEED

func _on_reset():
	$TransitionSound.play()
	speed_level = 0
	$Timer.wait_time = BASE_SPEED
	max_ants = 1
	enemy_pool.clear()
	$Snakes/Snake.reset()
	$Pellet.reset()
	$Pellet.enable()
	$Sky.reset()
	$Board.reset()
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
	$EatSound.play()
	score += level * 10
	var text = POINTS_TEXT.instantiate()
	text.setup(level * 10)
	text.position = bug_pos - Vector2(50, 0)
	add_child(text)
	$UI/Score.text = str(score)
	
	# horrible $HACK$, so moon and hornets don't count...
	var real_bugs = 0
	for bug in $Bugs.get_children():
		if bug.has_method("DONT_COUNT"):
			continue
		real_bugs += 1
	
	if real_bugs == 1: #ate last bug
		var full_clear_bonus = (FULL_CLEAR_BONUS * level) + (int($UI/Time.text) * level)
		score += full_clear_bonus
		$UI/Score.text = str(score) 
		level += 1
		_update_level()
		var bonus_text = POINTS_TEXT.instantiate()
		bonus_text.setup_bonus(full_clear_bonus)
		bonus_text.position = Vector2(Global.RESOLUTION.x/2 - 50, 15)
		add_child(bonus_text)


func _on_timer_timeout():
	for s in $Snakes.get_children():
		s.move()
	if state == State.PLAYING:
		$MoveSound.play()
		
func on_bullet_shot():
	$BulletSound.play()

func on_moon_bullet_shot():
	$MoonBulletSound.play()

var music_state = 1
func _on_music_control_pressed():
	if music_state == 0:
		music_state = 1
		$MusicButton.text = "Music 1"
		$Music1.play(0)
		AudioServer.set_bus_mute(2, false)
		AudioServer.set_bus_mute(3, true)
		AudioServer.set_bus_mute(4, true)
		AudioServer.set_bus_mute(5, true)
		AudioServer.set_bus_mute(6, true)
		AudioServer.set_bus_mute(7, true)
	elif music_state == 1:
		music_state = 2
		$Music2.play(0)
		$MusicButton.text = "Music 2"
		AudioServer.set_bus_mute(2, true)
		AudioServer.set_bus_mute(3, false)
		AudioServer.set_bus_mute(4, true)
		AudioServer.set_bus_mute(5, true)
		AudioServer.set_bus_mute(6, true)
		AudioServer.set_bus_mute(7, true)
	elif music_state == 2:
		music_state = 3
		$Music3.play(0)
		$MusicButton.text = "Music 3"
		AudioServer.set_bus_mute(2, true)
		AudioServer.set_bus_mute(3, true)
		AudioServer.set_bus_mute(4, false)
		AudioServer.set_bus_mute(5, true)
		AudioServer.set_bus_mute(6, true)
		AudioServer.set_bus_mute(7, true)
	elif music_state == 3:
		music_state = 4
		$Music4.play(0)
		$MusicButton.text = "Music 4"
		AudioServer.set_bus_mute(2, true)
		AudioServer.set_bus_mute(3, true)
		AudioServer.set_bus_mute(4, true)
		AudioServer.set_bus_mute(5, false)
		AudioServer.set_bus_mute(6, true)
		AudioServer.set_bus_mute(7, true)
	elif music_state == 4:
		music_state = 5
		$Music5.play(0)
		$MusicButton.text = "Music 5"
		AudioServer.set_bus_mute(2, true)
		AudioServer.set_bus_mute(3, true)
		AudioServer.set_bus_mute(4, true)
		AudioServer.set_bus_mute(5, true)
		AudioServer.set_bus_mute(6, false)
		AudioServer.set_bus_mute(7, true)
	elif music_state == 5:
		music_state = 6
		$Music6.play(0)
		$MusicButton.text = "Music 6"
		AudioServer.set_bus_mute(2, true)
		AudioServer.set_bus_mute(3, true)
		AudioServer.set_bus_mute(4, true)
		AudioServer.set_bus_mute(5, true)
		AudioServer.set_bus_mute(6, true)
		AudioServer.set_bus_mute(7, false)
	elif music_state == 6:
		music_state = 0
		AudioServer.set_bus_mute(2, true)
		AudioServer.set_bus_mute(3, true)
		AudioServer.set_bus_mute(4, true)
		AudioServer.set_bus_mute(5, true)
		AudioServer.set_bus_mute(6, true)
		AudioServer.set_bus_mute(7, true)
		$Music1.play()
		$MusicButton.text = "Music Off"
