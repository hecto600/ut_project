class_name Player
extends CharacterBody2D

@export var speed: float = 450.0
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.12

func _ready():
	pass # Replace with function body.


func _physics_process(_delta: float):
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var desired_velocity: Vector2 = speed * direction
	var steering: Vector2 = desired_velocity - velocity 
	velocity += steering * drag_factor
	move_and_slide()
