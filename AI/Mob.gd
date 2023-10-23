extends CharacterBody2D

@onready var detection_area: Area2D = $Pivot/DetectionArea
@onready var _pivot: Node2D = $Pivot
@onready var coll_shape: CollisionShape2D = $MobCollisionShape
@onready var cov: PointLight2D = $Pivot/ConeOfVision
@onready var timer_detected: Timer = $Pivot/TimerDetected
@onready var timer_undetected: Timer = $Pivot/TimerUndetected
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var speed: float = 350.0
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.2
@export var vision_range: float = 500.0
@export var rays_angle_interval: float = deg_to_rad(3.0)
@export var rays_amount: int = 30


var target: CharacterBody2D
var ray_list: Array[RayCast2D]

var curr_state: int = State.STATE_IDLE
enum State {
	STATE_IDLE,
	STATE_SEARCH,
	STATE_PATROL,
	STATE_ATTACK,
	STATE_ALERT,
}

var found_player := false
var timer_to_detect: float = 0.5
var timer_to_alert: float = 1.5
var timer_alert_to_patrol: float = 8.0

func _ready() -> void:
	timer_detected.timeout.connect(_on_timer_detected_timeout)
	timer_undetected.timeout.connect(_on_timer_undetected_timeout)
	_create_rays()


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
		


func state_machine():
	vision_detection()
		
	match curr_state:
		State.STATE_IDLE:
			if found_player:
				curr_state = State.STATE_SEARCH
				timer_detected.start(timer_to_detect)
			cov.color = Color(0.0, 1.0, 0.0, 0.5)
			
		State.STATE_SEARCH:
			cov.color = Color(1.0, 1.0, 0.0, 0.5)
			
		State.STATE_ATTACK:
			cov.color = Color(1.0, 0.0, 0.0, 0.5)
			if found_player:
				timer_detected.start(timer_to_alert) # time restarted
				_set_has_target()
		
		State.STATE_ALERT:
			cov.color = Color(1.0, 1.0, 0.0, 0.5)
			if found_player:
				animation_player.pause()
				timer_undetected.stop()
				curr_state = State.STATE_ATTACK
		
		State.STATE_PATROL:
			cov.color = Color(0.0, 1.0, 0.0, 0.5)
			
			if found_player:
				curr_state = State.STATE_SEARCH
				timer_detected.start(timer_to_detect)
				animation_player.pause()
		_:
			print("UNDEFINED STATE")


func _patrol_rotation():
	pass


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


func _on_timer_detected_timeout() -> void:
	if found_player and curr_state == State.STATE_SEARCH:
		curr_state = State.STATE_ATTACK
	elif curr_state == State.STATE_ATTACK:
		curr_state = State.STATE_ALERT
		timer_undetected.start(timer_alert_to_patrol)
		animation_player.play("state_alert")
	else:
		print("Shouldn't exist")
		curr_state = State.STATE_IDLE


func _on_timer_undetected_timeout() -> void:
	
	curr_state = State.STATE_PATROL
	animation_player.play("state_patrol")
