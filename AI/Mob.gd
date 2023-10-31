extends CharacterBody2D

@onready var detection_sound_area: Area2D = $Pivot/DetectionArea
@onready var _pivot: Node2D = $Pivot
@onready var coll_shape: CollisionShape2D = $MobCollisionShape
@onready var cov: PointLight2D = $Pivot/ConeOfVision
@onready var timer_detected: Timer = $Pivot/TimerDetected
@onready var timer_undetected: Timer = $Pivot/TimerUndetected
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hud: Control = $CanvasLayer/HUD
@onready var hearing_shape: CollisionShape2D = $Pivot/DetectionArea/HearingDetectionShape

@export var speed: float = 350.0
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.2
@export var vision_range: float = 500.0
@export var rays_angle_interval: float = deg_to_rad(3.0)
@export var rays_amount: int = 30


var target: CharacterBody2D
var ray_list: Array[RayCast2D]

var curr_state: int = State.STATE_IDLE
var already_detected: bool = false

enum State {
	STATE_IDLE,
	STATE_SEARCH,
	STATE_PATROL,
	STATE_ATTACK,
	STATE_ALERT,
}

var found_player: bool = false
var heard_player: bool = false
var in_noise_range: bool = false

var timer_to_detect: float = 0.75
var timer_to_detect_sound: float = 2.0
var timer_to_attack: float = 4.0
var timer_alert_to_patrol: float = 6.0

func _ready() -> void:
	timer_detected.timeout.connect(_on_timer_detected_timeout)
	timer_undetected.timeout.connect(_on_timer_undetected_timeout)
	detection_sound_area.body_entered.connect(_on_detection_sound_area_body_entered)
	detection_sound_area.body_exited.connect(_on_detection_sound_area_body_exited)
	_create_rays()

func _draw():
	draw_circle(Vector2.ZERO, hearing_shape.get_shape().radius, Color(Color.AQUA, 0.05))

func _create_rays() -> void:
	for ray_offset in range(-rays_amount / 2 , rays_amount / 2 + 1 ):
		var angle: float = ray_offset * rays_angle_interval
		var raycast: RayCast2D = RayCast2D.new()
		raycast.target_position = Vector2.RIGHT.rotated(angle) * vision_range
		raycast.collision_mask = 5
		_pivot.add_child(raycast)


func vision_detection() -> void:
	found_player = false
	for ray in _pivot.get_children():
		if ray is RayCast2D and ray.is_colliding() and ray.get_collider() is Player:
			ray_list.append(ray)
			found_player = true
			target = ray.get_collider()
			break


func noise_detection() -> void:
	heard_player = false
	if target != null and target.speed == target.speed_boost and in_noise_range:
		heard_player = true
		_pivot.look_at(target.global_position)
		coll_shape.look_at(target.global_position)
		
		if curr_state == State.STATE_IDLE or curr_state == State.STATE_PATROL:
			curr_state = State.STATE_SEARCH
			animation_player.pause()
			timer_detected.start(timer_to_detect)
			
	


func state_machine():
	vision_detection()
	noise_detection()
	
	print(curr_state)
		
	match curr_state:
		State.STATE_IDLE:
			hud.get_node("Panel/VBox/State mode").text = "Idle mode"
			hud.get_node("Panel/VBox/State timer").text = "N.A."
			cov.color = Color(Color.GREEN, 0.5)
			
			if found_player or heard_player:
				curr_state = State.STATE_SEARCH
				timer_detected.start(timer_to_detect)
				
		State.STATE_SEARCH:
#			hud.visible = true
			hud.get_node("Panel/VBox/State mode").text = "Search mode"
			hud.get_node("Panel/VBox/State timer").text = str(timer_detected.time_left).pad_decimals(2).pad_zeros(2)
			cov.color = Color(Color.YELLOW, 0.5)
			
		State.STATE_ATTACK:
			cov.color = Color(Color.RED, 0.5)
			
			if found_player or heard_player:
				timer_detected.start(timer_to_attack) # time restarted
				_set_has_target()
				hud.get_node("Panel/VBox/State mode").text = "Attack mode"
				hud.get_node("Panel/VBox/State timer").text = str(timer_detected.wait_time).pad_decimals(2).pad_zeros(2)

			else:
				hud.get_node("Panel/VBox/State timer").text = str(timer_detected.time_left).pad_decimals(2).pad_zeros(2)
		
		State.STATE_ALERT:
			cov.color = Color(Color.ORANGE, 0.5)
			if found_player or heard_player:
				curr_state = State.STATE_ATTACK
				animation_player.pause()
				timer_undetected.stop()
				timer_detected.start(timer_to_attack) 
			else:
				hud.get_node("Panel/VBox/State timer").text = str(timer_undetected.time_left).pad_decimals(2).pad_zeros(2)
		
		State.STATE_PATROL:
			cov.color = Color(Color.GREEN_YELLOW, 0.5)
			hud.get_node("Panel/VBox/State mode").text = "Patrol mode"
			hud.get_node("Panel/VBox/State timer").text = "N.A."
			
			if found_player or heard_player:
				curr_state = State.STATE_SEARCH
				timer_detected.start(timer_to_detect)
				animation_player.pause()
		_:
			print("UNDEFINED STATE")


func _on_timer_detected_timeout() -> void:
	if found_player or heard_player and curr_state == State.STATE_SEARCH:
		already_detected = true
		curr_state = State.STATE_ATTACK
		timer_detected.start(timer_to_attack)
		hud.get_node("Panel/VBox/State mode").text = "Attack mode"
		
	elif curr_state == State.STATE_ATTACK:
		curr_state = State.STATE_ALERT
		timer_undetected.start(timer_alert_to_patrol)
		animation_player.play("state_alert")
		hud.get_node("Panel/VBox/State mode").text = "Alert mode"
		
	elif not already_detected:
		curr_state = State.STATE_IDLE
#		hud.visible = false
		
	elif already_detected:
		curr_state = State.STATE_PATROL
		animation_player.play("state_patrol")
#		hud.visible = false


func _on_timer_undetected_timeout() -> void:
	curr_state = State.STATE_PATROL
	animation_player.play("state_patrol")
#	hud.visible = false


func _on_detection_sound_area_body_entered(body: CharacterBody2D) -> void:
	in_noise_range = true
	if body is Player:
		target = body


func _on_detection_sound_area_body_exited(body: CharacterBody2D) -> void:
	in_noise_range = false


func _physics_process(_delta: float) -> void: 
	state_machine()


func _set_has_target() -> void:
	var direction: Vector2 = Vector2.ZERO
	var desired_velocity: Vector2 = Vector2.ZERO
	var steering: Vector2 = Vector2.ZERO
		
	_pivot.look_at(target.global_position)
	coll_shape.look_at(target.global_position)
	
	for ray in ray_list:
		ray.force_raycast_update()
	
	direction = to_local(target.global_position).normalized()
	var distance = to_local(target.global_position).length() as int
	
	if distance > 180:
		desired_velocity = direction * speed
		steering = desired_velocity - velocity
		velocity += steering * drag_factor
		move_and_slide()


