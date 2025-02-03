class_name Drone
extends CharacterBody2D

@export var speed := 200.0 
@export_flags_2d_physics var obstacle_collision_mask = 1

@onready var vision_area = $VisionArea

var seen_drones : Array[Drone]
var seen_obstacles : Array[CollisionObject2D]

var desired_velocity : Vector2 
var max_desired_velocity_angle := PI / 2

func _ready() -> void:
	vision_area.body_entered.connect(_body_entered_vision)
	vision_area.body_exited.connect(_body_exited_vision)
	velocity.angle()
	velocity = Vector2.RIGHT #Vector2(randf(), randf())
	velocity = velocity.normalized() * speed
	desired_velocity = Vector2.DOWN * speed

func _physics_process(delta: float) -> void:
	avoid_obstacles()
	velocity = velocity.lerp(desired_velocity, delta)
	rotation = velocity.angle()
	move_and_slide()
	queue_redraw()


func avoid_obstacles():
	var space_state = get_world_2d().direct_space_state
	var ray_end = global_position + Vector2(200, 0).rotated(velocity.angle())
	var query = PhysicsRayQueryParameters2D.create(global_position, ray_end, obstacle_collision_mask, [self])
	var result = space_state.intersect_ray(query)
	
	if not result.is_empty():
		Utils.add_unique(seen_obstacles, result.collider)
		desired_velocity = (velocity + result.normal * speed).normalized() * speed
		desired_velocity = Utils.limit_vector_by_angle(velocity, desired_velocity, max_desired_velocity_angle)

func _body_entered_vision(body : Node2D):
	if body is Drone:
		seen_drones.append(body)
	elif body.is_in_group("Environment"):
		return
		seen_obstacles.append(body)
		var space_state = get_world_2d().direct_space_state
		var end = global_position + Vector2(200, 0).rotated(velocity.angle())
		var query = PhysicsRayQueryParameters2D.create(global_position, end)
		query.collision_mask = 2
		query.exclude = [self]

		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			desired_velocity = (velocity + result.normal * speed).normalized() * speed
		
func _body_exited_vision(body : Node2D):
	if body is Drone:
		seen_drones.erase(body)
	elif body.is_in_group("Environment"):
		return
		seen_obstacles.erase(body)
		if seen_obstacles.is_empty():
			pass#desired_velocity = velocity.normalized() * speed

func _draw():
	draw_string(ThemeDB.fallback_font, Vector2(0,100), str(seen_obstacles.size())) 
	pass
