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
@export var value_boost: float = 4.0
@export var value_cooldown: float = 10.0

@onready var timer_boost: Timer = $TimerBoost
@onready var timer_cooldown: Timer = $TimerCooldown
@onready var ui_speed: Label = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/LabelSpeed
@onready var ui_timeleft: Label = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/LabelTimeleft
@onready var ui_cooldown: Label = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/LabelCooldown

var boost_available: bool = true
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
	
	if Input.is_action_just_pressed("move_boost") and boost_available:
		boost_available = false
		speed = speed_boost
		ui_speed.text = str(speed)
		timer_boost.start(value_boost)
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired_velocity: Vector2 = speed * direction
	var steering: Vector2 = desired_velocity - velocity 
	velocity += steering * drag_factor
	move_and_slide()


func _on_timer_boost_timeout() -> void:
	speed = speed_normal
	ui_speed.text = str(speed)
	timer_cooldown.start(value_cooldown)


func _on_timer_cooldown_timeout() -> void:
	boost_available = true
