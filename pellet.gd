extends CharacterBody2D

signal dead
signal moved

@export var speed = 100

var enabled = true
@onready var STARTING_POS = position

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

func _physics_process(_delta):
	if enabled:
		get_input()
		move_and_slide()
		if velocity != Vector2.ZERO:
			emit_signal("moved")

func disable():
	enabled = false

func enable():
	enabled = true

func reset():
	position = STARTING_POS

func _on_dead_hitbox_body_entered(_body):
	emit_signal("dead")

func _on_dead_hitbox_area_entered(_area):
	emit_signal("dead")
