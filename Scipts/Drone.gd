class_name Drone
extends CharacterBody2D

@export var min_speed := 20.0 
@export var max_speed := 200.0
@export_range(0, 180) var vision_angle := 120
@export_flags_2d_physics var obstacle_collision_mask = 1

@onready var vision_area = $VisionArea

var seen_drones : Array[Drone]
var seen_obstacles : Array[CollisionObject2D]

var desired_velocity : Vector2 
var max_desired_velocity_angle := PI / 3

func get_forward_vector() -> Vector2:
	return Vector2.RIGHT.rotated(rotation)

func _ready() -> void:
	vision_area.body_entered.connect(_body_entered_vision)
	vision_area.body_exited.connect(_body_exited_vision)
	velocity.angle()
	velocity = Vector2(randf(), randf())
	velocity = velocity.normalized() * max_speed

func _physics_process(delta: float) -> void:
	var flocking_velocity = separation() + cohesion(.1) + alignment(.5)
	if flocking_velocity.length() > 0:
		desired_velocity = flocking_velocity.normalized() * max_speed
	
	#var desired_speed = desired_velocity.length()
	#if desired_speed < max_speed:
		#desired_speed = lerp(desired_velocity.length(), max_speed, delta)	
	#desired_velocity = desired_velocity.normalized() * desired_speed
		
	avoid_obstacles()
	
	var new_velocity = velocity.lerp(desired_velocity, delta)
	var speed = new_velocity.length()
	if speed < max_speed:
		speed = lerp(speed, max_speed, delta)
		new_velocity = new_velocity.normalized() * speed
	velocity = new_velocity
	rotation = velocity.angle()
	move_and_slide()

func separation(factor := 1600.0) -> Vector2:
	var result := Vector2.ZERO
	for drone in seen_drones:
		var repuslive_dir = (global_position - drone.global_position).normalized()
		result += repuslive_dir / global_position.distance_squared_to(drone.global_position)
	return result * factor
	
func cohesion(factor := 0.5) -> Vector2:
	if seen_drones.is_empty():
		return Vector2.ZERO
		
	var sum_positions := Vector2.ZERO
	for drone in seen_drones:
		sum_positions += drone.global_position
	return (sum_positions / seen_drones.size() - global_position) * factor
	
func alignment(factor := 1.0) -> Vector2:
	if seen_drones.is_empty():
		return Vector2.ZERO
		
	var total_velocity := Vector2.ZERO
	for drone in seen_drones:
		total_velocity += drone.velocity
	return (total_velocity / seen_drones.size() - velocity) * factor
	

func avoid_obstacles(obstacle_check_delta := 10.0):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + desired_velocity, obstacle_collision_mask, [self])
	var turn_angle := 0.0
	var turn_direction := 1
	var increase_angle := true
	var result = space_state.intersect_ray(query)
	while not result.is_empty():
		if increase_angle:
			turn_angle += obstacle_check_delta
			increase_angle = false
		else:
			turn_direction *= -1
			increase_angle = true
		query.to = global_position + desired_velocity.rotated(turn_angle * turn_direction)
		result = space_state.intersect_ray(query)
	desired_velocity = desired_velocity.rotated(turn_angle * turn_direction)
	queue_redraw()


func _body_entered_vision(body : Node2D):
	if body == self:
		return
		
	var body_angle = get_forward_vector().angle_to(body.global_position - global_position)
	if body_angle > vision_angle:
		return
		
	if body is Drone:
		seen_drones.append(body)

		
func _body_exited_vision(body : Node2D):
	if body is Drone:
		seen_drones.erase(body)
		
func _draw():
	draw_line(Vector2.ZERO, desired_velocity, Color.RED)
