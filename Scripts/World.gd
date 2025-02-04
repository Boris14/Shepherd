class_name World
extends Node2D

@export var enemy_spawn_rate = 0.15
@export var field_size_factor := 1.0
@export var simulation_time_scale := 1.0
@export var points_of_interest_count = 10
@export var points_of_interest_spawn_padding := 20

@export_category("Drones")
@export var drone_sight_radius = 300.0
@export var drones_count = 15
@export var drone_spawn_check_increment := 20.0

@export_category("Packed Scenes")
@export var drone_scene : PackedScene
@export var point_of_interest_scene : PackedScene

@onready var camera: Camera = $Camera2D

var field_size : Vector2
var collected_points_of_interest := 0

func _ready():
	var field := StaticBody2D.new()
	var field_collision := CollisionPolygon2D.new()
	field_collision.polygon = generate_field_boundaries()
	field.collision_layer = 2
	field.add_child(field_collision)
	field.add_to_group("Environment")
	
	get_tree().current_scene.add_child(field)
	
	camera.global_position = %DronesStart.global_position
	
	spawn_drones(%DronesStart.position)
	spawn_points_of_interest()
	
	Engine.time_scale = simulation_time_scale

func _exit_tree():
	Engine.time_scale = 1.0

func generate_spiral_points(origin: Vector2, points_count: int, increment: int) -> Array:
	var result = []
	var x := origin.x
	var y := origin.y
	var dx := 0
	var dy := -1
	
	var step_count = 0
	var turn_count = 0
	
	for i in range(points_count):
		result.append(Vector2(x, y))
		
		if step_count == turn_count / 2 + 1:
			step_count = 0
			turn_count += 1
			
			var temp = dx
			dx = -dy
			dy = temp
		
		x += dx * increment
		y += dy * increment
		step_count += 1
		
	return result


func spawn_drones(pos : Vector2):
	var points = generate_spiral_points(pos, 1000, drone_spawn_check_increment)
	var point_i = 0
	for i in range(drones_count):
		while not can_spawn(points[point_i]) and point_i < points.size(): 
			point_i += 1
		var drone := drone_scene.instantiate() as Drone
		drone.global_position = points[point_i]
		add_child(drone)
	
func spawn_points_of_interest():
	for i in range(points_of_interest_count):
		var point_of_interest := point_of_interest_scene.instantiate() as PointOfInterest
		point_of_interest.collected.connect(_on_point_of_interest_collected)
		point_of_interest.position.x = randf_range(points_of_interest_spawn_padding,\
			field_size.x - points_of_interest_spawn_padding)
		point_of_interest.position.y = randf_range(points_of_interest_spawn_padding,\
			field_size.y - points_of_interest_spawn_padding)
		add_child(point_of_interest)
		
func can_spawn(pos : Vector2, drone_radius := 15.0) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = drone_radius
	params.shape = circle_shape
	params.transform = Transform2D(0, pos)
	var hits : Array = get_world_2d().direct_space_state.intersect_shape(params)
	return hits.size() == 0
	
func generate_field_boundaries() -> PackedVector2Array:
	field_size = DisplayServer.window_get_size() * field_size_factor
	var result : PackedVector2Array
	result.append(Vector2(0, 0))
	result.append(Vector2(0, field_size.y))
	result.append(Vector2(field_size.x, field_size.y))
	result.append(Vector2(field_size.x, 0))
	result.append(Vector2(-100, 0))
	result.append(Vector2(field_size.x, -100))
	result.append(Vector2(field_size.x + 100, field_size.y))
	result.append(Vector2(-100, field_size.y + 100))
	return result

func _draw() -> void:
	var field_rect : Rect2
	field_rect.position = Vector2(0, 0)
	field_rect.end = Vector2(field_size.x, field_size.y)
	draw_rect(field_rect, Color.BLACK)

func _on_point_of_interest_collected(point_of_interest : PointOfInterest):
	collected_points_of_interest += 1
