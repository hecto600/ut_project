class_name Player
extends CharacterBody2D

@export var speed_normal: float = 450.0
@export var speed_boost: float = 800.0:
	get:
		return speed_boost
		
@export var speed: float = 450.0:
	get: 
		return speed
	set(value):
		speed = value
		
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.12
@export var time_boost: float = 4.0
@export var time_cooldown: float = 5.0

@onready var timer_boost: Timer = $TimerBoost
@onready var timer_cooldown: Timer = $TimerCooldown
@onready var ui_speed: Label = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/LabelSpeed
@onready var ui_timeleft: Label = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/LabelTimeleft
@onready var ui_cooldown: Label = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/LabelCooldown
@onready var sprite: Sprite2D = $Sprite2D

var boost_available: bool = true
const DIRECTION_TO_FRAME := {
	Vector2.RIGHT: 0,
	Vector2.UP: 1,
}

func _ready():
	timer_boost.timeout.connect(_on_timer_boost_timeout)
	timer_cooldown.timeout.connect(_on_timer_cooldown_timeout)
	ui_speed.text = str(speed)

func _process(_delta):
	
	if snapped(timer_boost.time_left, 0.01) > 0:
		ui_timeleft.text = str(timer_boost.time_left).pad_zeros(2).pad_decimals(2)
	else:
		ui_timeleft.text = "N.A."
	if snapped(timer_cooldown.time_left,0.01) > 0:
		ui_cooldown.text = str(timer_cooldown.time_left).pad_zeros(2).pad_decimals(2)
	else:
		ui_cooldown.text = "Boost available"
		
func _physics_process(_delta: float):
	
	if Input.is_action_pressed("move_boost") and boost_available:
		boost_available = false
		speed = speed_boost
		ui_speed.text = str(speed)
		timer_boost.start(time_boost)
		
	if Input.is_action_just_released("move_boost"):
		boost_available = true
		speed = speed_normal
		ui_speed.text = str(speed)
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired_velocity: Vector2 = speed * direction
	var steering: Vector2 = desired_velocity - velocity 
	velocity += steering * drag_factor
	move_and_slide()
	
	match direction:
		Vector2.UP:
			sprite.frame = 1
			sprite.flip_v = 0
			
		Vector2.LEFT:
			sprite.frame = 0
			sprite.flip_h = 1
			
		Vector2.RIGHT:
			sprite.frame = 0
			sprite.flip_h = 0
			
		Vector2.DOWN:
			sprite.frame = 1
			sprite.flip_v = 1

func _on_timer_boost_timeout() -> void:
	speed = speed_normal
	ui_speed.text = str(speed)
	timer_cooldown.start(time_cooldown)


func _on_timer_cooldown_timeout() -> void:
	boost_available = true
