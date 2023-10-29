extends CharacterBody2D

@onready var mark: Marker2D = $Marker2D

@export var speed: float = 350.0
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.2
@export var vision_range: float = 500.0
@export var rays_angle_interval: float = deg_to_rad(3.0)
@export var rays_amount: int = 30

var target: CharacterBody2D
var ray_list: Array[RayCast2D]
var found_player := false
var timer_to_detect: float = 0.5
var timer_to_alert: float = 1.5
var timer_alert_to_patrol: float = 8.0

func _ready() -> void:
#	timer_detected.timeout.connect(_on_timer_detected_timeout)
#	timer_undetected.timeout.connect(_on_timer_undetected_timeout)
	_create_rays()

func _create_rays() -> void:
	for ray_offset in range(-rays_amount / 2 , rays_amount / 2 + 1 ):
		var angle: float = ray_offset * rays_angle_interval
		var raycast: RayCast2D = RayCast2D.new()
		raycast.target_position = Vector2.RIGHT.rotated(angle) * vision_range
		raycast.collision_mask = 5
		add_child(raycast)


func vision_detection() -> void:
	found_player = false
	for ray in get_children():
		if ray is RayCast2D and ray.is_colliding() and ray.get_collider() is Player:
			ray_list.append(ray)
			found_player = true
			target = ray.get_collider()
			break


func _physics_process(delta) -> void:
	vision_detection()
	if found_player:
		_set_has_target()


func _set_has_target() -> void:
	var direction: Vector2 = Vector2.ZERO
	var desired_velocity: Vector2 = Vector2.ZERO
	var steering: Vector2 = Vector2.ZERO
	
	var target_angle: float = target.global_position.angle_to_point(global_position)
	rotation = lerp_angle(rotation, target_angle, 0.5)
	
	for ray in ray_list:
		ray.force_raycast_update()
	
	direction = to_local(target.global_position).normalized()
	var distance = to_local(target.global_position).length() as int
	print("dir: ", direction)
	if distance > 10:
		desired_velocity = direction * speed
		print("des_vel: ", desired_velocity)
		
		steering = desired_velocity - velocity
		velocity += steering * drag_factor
		move_and_slide()
