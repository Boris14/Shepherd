class_name Drone
extends CharacterBody2D

signal destroyed()

@export_range(0, 50) var min_speed := 20.0 
@export_range(50, 400) var max_speed := 80.0
@export_range(0, 180) var vision_angle := 120
@export_flags_2d_physics var obstacle_collision_mask = 1
@export_range(1, 45, 1) var obstacle_check_delta := 10.0

@export_group("Wander Behavior")
## Distance in front of the drone
@export_range(10, 100.0, 0.5) var wander_circle_distance = 50.0
## Radius of the wander circle
@export_range(5, 40.0, 0.2) var wander_circle_radius = 20.0
## How fast the angle changes
@export_range(0.05, 0.8, 0.01) var wander_change = 0.3
var wander_angle = randf_range(0, TAU)  # Random initial direction

var separation_weight := 100000.0
var cohesion_weight := 5.0
var alignment_weight := 0.5
var obstacle_avoidance_weight := 10.0
var poi_attraction_weight := 50.0
var enemy_repulsion_weight := 10.0
var wander_weight = 3.0

var seen_drones : Array[Drone]
var seen_obstacles : Array[CollisionObject2D]
var seen_points_of_interest : Array[PointOfInterest]
var seen_enemies : Array[Enemy]

var acceleration : Vector2

@onready var vision_area = $VisionArea

func get_forward_vector() -> Vector2:
	return Vector2.RIGHT.rotated(rotation)

func _ready() -> void:
	vision_area.body_entered.connect(_body_entered_vision)
	vision_area.body_exited.connect(_body_exited_vision)
	velocity.angle()
	velocity = Vector2(randf(), randf())
	velocity = velocity.normalized() * max_speed

func _physics_process(delta: float) -> void:
	acceleration = Vector2.ZERO
	
	acceleration += separation() * separation_weight
	acceleration += cohesion() * cohesion_weight
	acceleration += alignment() * alignment_weight
	
	acceleration += avoid_obstacles() * obstacle_avoidance_weight
	
	if seen_enemies.size() > 0:
		acceleration += enemy_repulsion() * enemy_repulsion_weight
	elif seen_points_of_interest.size() > 0:
		acceleration += poi_attraction() * poi_attraction_weight
	else:
		acceleration += wander() * wander_weight
	
	velocity += acceleration * delta
	
	velocity = velocity.limit_length(max_speed)
	if velocity.length() < min_speed:
		velocity = velocity.normalized() * min_speed
		
	rotation = velocity.angle()
	
	move_and_slide()
	queue_redraw()


func separation() -> Vector2:
	var result := Vector2.ZERO
	for drone in seen_drones:
		var repuslive_dir = (global_position - drone.global_position).normalized()
		result += repuslive_dir / global_position.distance_squared_to(drone.global_position)
	return result
	
func cohesion() -> Vector2:
	if seen_drones.is_empty():
		return Vector2.ZERO
		
	var sum_positions := Vector2.ZERO
	for drone in seen_drones:
		sum_positions += drone.global_position
	return sum_positions / seen_drones.size() - global_position
	
func alignment() -> Vector2:
	if seen_drones.is_empty():
		return Vector2.ZERO
		
	var total_velocity := Vector2.ZERO
	for drone in seen_drones:
		total_velocity += drone.velocity
	return total_velocity / seen_drones.size() - velocity

func avoid_obstacles():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position,\
		global_position + velocity, obstacle_collision_mask, [self])
	var turn_angle := 0.0
	var turn_direction := 1
	var increase_angle := true
	var result = space_state.intersect_ray(query)
	while not result.is_empty() and abs(turn_angle) < vision_angle:
		if increase_angle:
			turn_angle += obstacle_check_delta
			increase_angle = false
		else:
			turn_direction *= -1
			increase_angle = true
		query.to = global_position + velocity.rotated(turn_angle * turn_direction)
		result = space_state.intersect_ray(query)
	return velocity.rotated(turn_angle * turn_direction)

func poi_attraction() -> Vector2:
	if seen_points_of_interest.is_empty():
		return Vector2.ZERO

	var closest_point = seen_points_of_interest.front()
	var closest_distance := global_position.distance_to(closest_point.global_position)
	for point in seen_points_of_interest:
		var distance = global_position.distance_to(point.global_position)
		if distance < closest_distance:
			closest_point = point
			closest_distance = distance
	return closest_point.global_position - global_position

func enemy_repulsion() -> Vector2:
	if seen_enemies.is_empty():
		return Vector2.ZERO
	
	var closest_enemy = seen_enemies.front()
	var closest_distance := global_position.distance_to(closest_enemy.global_position)
	for enemy in seen_enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	return global_position - closest_enemy.global_position
	

func wander() -> Vector2:
	var circle_center = velocity.normalized() * wander_circle_distance
	wander_angle += randf_range(-wander_change, wander_change)
	
	var displacement = Vector2(wander_circle_radius, 0).rotated(wander_angle)
	
	var wander_force = circle_center + displacement
	return wander_force.normalized() * max_speed

	
func _body_entered_vision(body : Node2D):
	if body == self:
		return
		
	var body_angle = get_forward_vector().angle_to(body.global_position - global_position)
	if body_angle > vision_angle:
		return
		
	if body is Drone:
		seen_drones.append(body)
	elif body is Enemy:
		seen_enemies.append(body)
	elif body is PointOfInterest:
		body.collected.connect(_on_point_of_interest_collected)
		seen_points_of_interest.append(body)

func _body_exited_vision(body : Node2D):
	if body is Drone:
		seen_drones.erase(body)
	elif body is Enemy:
		seen_enemies.erase(body)
	elif body is PointOfInterest:
		body.collected.disconnect(_on_point_of_interest_collected)
		seen_points_of_interest.erase(body)
		
func _on_point_of_interest_collected(point_of_interest : PointOfInterest):
	seen_points_of_interest.erase(point_of_interest)
		
func destroy():
	destroyed.emit()
	queue_free()
		
func _draw():
	#draw_circle(velocity.normalized() * wander_circle_distance, wander_circle_radius, Color.GREEN)
	return
	draw_line(Vector2.ZERO, acceleration, Color.RED)
