extends CharacterBody2D

@export var speed: float = 300.0
@export_range(0.01, 1.0, 0.01) var drag_factor: float = 0.2

@export var vision_range: float = 500.0
@export var rays_angle_interval: float = deg_to_rad(3.0)
@export var rays_amount: int = 30

@onready var detection_area: Area2D = $DetectionArea
@onready var _pivot: Node2D = $Pivot
@onready var coll_shape: CollisionShape2D = $MobCollisionShape

var target: CharacterBody2D
var ray_list: Array[RayCast2D]

func _draw() -> void:
	
	var cov_angle: float = rays_angle_interval * rays_amount / 2.0
	var cov_upper_point: Vector2 = Vector2.RIGHT.rotated(cov_angle) * vision_range
	var cov_lower_point: Vector2 = Vector2.RIGHT.rotated(-cov_angle) * vision_range
	
	var center = Vector2(0, 0)
	var radius = 500
	var angle_from =  rad_to_deg(-cov_angle) 
	var angle_to = rad_to_deg(cov_angle)
	var color = Color(0.0, 1.0, 0.0, 0.5)
	draw_circle_arc_poly(center, radius, angle_from, angle_to, color)


func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PackedVector2Array()
	points_arc.push_back(center)
	var colors = PackedColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_polygon(points_arc, colors)


func _ready() -> void:
	_create_rays()


func _create_rays() -> void:
	for ray_offset in range(-rays_amount / 2 , rays_amount / 2 + 1 ):
		var angle: float = ray_offset * rays_angle_interval
		var raycast: RayCast2D = RayCast2D.new()
		raycast.target_position = Vector2.RIGHT.rotated(angle) * vision_range
		raycast.collision_mask = 5
		_pivot.add_child(raycast)


func _physics_process(_delta: float) -> void: 
	var found_player := false
	for ray in _pivot.get_children():
		if ray is RayCast2D and ray.is_colliding() and ray.get_collider() is Player:
			ray_list.append(ray)
			found_player = true
			target = ray.get_collider()
			break
		
	if found_player:
		_set_has_target()


func _set_has_target() -> void:
	var direction: Vector2 = Vector2.ZERO
	_pivot.look_at(target.global_position)
	coll_shape.look_at(target.global_position)
	queue_redraw()
	
	
	for ray in ray_list:
		ray.force_raycast_update()
		
	direction = to_local(target.global_position).normalized()
	var desired_velocity: Vector2 = direction * speed
	var steering = desired_velocity - velocity
	velocity += steering * drag_factor
	move_and_slide()
