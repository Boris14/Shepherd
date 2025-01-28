class_name World
extends Node2D

@export var POI_count = 10
@export var enemy_spawn_rate = 0.15
@export var drone_sight_radius = 300.0
@export var drones_count = 15
@export var drone_scene : PackedScene
@export var drone_spawn_check_increment := 20.0

@onready var camera: Camera = $Camera2D

func _ready():
	camera.global_position = $DronesStart.global_position
	$FieldBoundaries/CollisionPolygon2D.polygon = generate_field_boundaries()
	spawn_drones(%DronesStart.position)


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


func spawn_drones(pos : Vector2, drone_count := 10):
	var points = generate_spiral_points(pos, 1000, drone_spawn_check_increment)
	
	var point_i = 0
	for i in range(drone_count):
		while not can_spawn(points[point_i]) and point_i < points.size(): 
			point_i += 1
		var drone := drone_scene.instantiate() as Drone
		drone.global_position = points[point_i]
		add_child(drone)
	
		
func can_spawn(pos : Vector2, drone_radius := 15.0) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = drone_radius
	params.shape = circle_shape
	params.transform = Transform2D(0, pos)
	var hits : Array = get_world_2d().direct_space_state.intersect_shape(params)
	return hits.size() == 0
	
func generate_field_boundaries() -> PackedVector2Array:
	var screen_size = DisplayServer.window_get_size()
	var result : PackedVector2Array
	result.append(Vector2(0, 0))
	result.append(Vector2(0, screen_size.y))
	result.append(Vector2(screen_size.x, screen_size.y))
	result.append(Vector2(screen_size.x, 0))
	result.append(Vector2(-10, 0))
	result.append(Vector2(screen_size.x, -10))
	result.append(Vector2(screen_size.x + 10, screen_size.y))
	result.append(Vector2(-10, screen_size.y + 10))
	return result

func _draw() -> void:
	var field_rect : Rect2
	field_rect.position = Vector2(0, 0)
	field_rect.end = DisplayServer.window_get_size()
	draw_rect(field_rect, Color.AQUA)
