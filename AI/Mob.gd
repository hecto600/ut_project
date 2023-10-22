extends CharacterBody2D

@export var speed: float = 300.0
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.2

@export var vision_range: float = 500.0
@export var rays_angle_interval: float = deg_to_rad(3.0)
@export var rays_amount: int = 30

@onready var detection_area: Area2D = $DetectionArea
@onready var _pivot: Node2D = $Pivot
@onready var coll_shape: CollisionShape2D = $MobCollisionShape
@onready var cov: PointLight2D = $ConeOfVision
@onready var detection_time: Timer = $DetectionTime

var target: CharacterBody2D
var ray_list: Array[RayCast2D]
var points_arc = PackedVector2Array()
var curr_state: int = State.STATE_IDLE
enum State {
	STATE_IDLE,
	STATE_SEARCH,
	STATE_PATROL,
	STATE_ATTACK,
	STATE_ALERT,
}
var found_player := false
var timer_value: float = 0.5

func _ready() -> void:
	detection_time.timeout.connect(_on_detection_time_timeout)
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
				detection_time.start(timer_value)
			cov.color = Color(0.0, 1.0, 0.0, 0.5)
			
		State.STATE_SEARCH:
			cov.color = Color(1.0, 1.0, 0.0, 0.5)
			
		State.STATE_ATTACK:
			if found_player:
				detection_time.start(timer_value + 1.0) # time restarted
			_set_has_target()
			
		_:
			print("UNDEFINED STATE")


func _physics_process(_delta: float) -> void: 
	state_machine()


func _set_has_target() -> void:
	var direction: Vector2 = Vector2.ZERO
	_pivot.look_at(target.global_position)
	coll_shape.look_at(target.global_position)
	
	cov.look_at(target.global_position)
	
	for ray in ray_list:
		ray.force_raycast_update()
		
	direction = to_local(target.global_position).normalized()
	var desired_velocity: Vector2 = direction * speed
	var steering = desired_velocity - velocity
	velocity += steering * drag_factor
	move_and_slide()


func _on_detection_time_timeout():
	if found_player:
		cov.color = Color(1.0, 0.0, 0.0, 0.5)
		curr_state = State.STATE_ATTACK
	else:
		curr_state = State.STATE_IDLE
