class_name Simulation
extends Node2D

signal finished(simulation : Simulation, poi_collected : int, elapsed_time : float)

@export var enemy_spawn_rate = 3.0
@export var field_size_factor := 1.0
@export var simulation_time_scale := 1.0
@export var points_of_interest_count := 10
@export var obstacles_count := 5
@export var obstacle_scale_range := Vector2(1.0, 3.0)
@export var spawn_padding := 30

@export_category("Drones")
@export var drone_sight_radius = 300.0
@export var drones_count = 15
@export var drone_spawn_check_increment := 20.0

@export_category("Packed Scenes")
@export var drone_scene : PackedScene
@export var point_of_interest_scene : PackedScene
@export var obstacle_scene : PackedScene
@export var enemy_scene : PackedScene

@onready var camera: Camera = $Camera2D

var field_size : Vector2
var collected_points_of_interest := 0
var alive_drones := 0
var elapsed_time := 0.0

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
	spawn_obstacles()
	
	var enemy_spawn_timer := Timer.new()
	enemy_spawn_timer.wait_time = enemy_spawn_rate
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timeout)
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()
	
	Engine.time_scale = simulation_time_scale

func _process(delta):
	elapsed_time += delta

func _exit_tree():
	Engine.time_scale = 1.0

func spawn_drones(pos : Vector2):
	var points = Utils.generate_spiral_points(pos, 1000, drone_spawn_check_increment)
	var point_i = 0
	for i in range(drones_count):
		while not Utils.can_spawn(get_world_2d().direct_space_state, points[point_i], 30.0) and\
			point_i < points.size(): 
			point_i += 1
		var drone := drone_scene.instantiate() as Drone
		drone.destroyed.connect(_on_drone_destroyed)
		drone.global_position = points[point_i]
		add_child(drone)
		alive_drones += 1
	
func spawn_points_of_interest():
	for i in range(points_of_interest_count):
		var point_of_interest := point_of_interest_scene.instantiate() as PointOfInterest
		point_of_interest.collected.connect(_on_point_of_interest_collected)
		
		var point_radius := 0.0
		for child in point_of_interest.get_children():
			if child is CollisionShape2D:
				point_radius = child.shape.radius * point_of_interest.scale.x
		
		var find_position_attempts := 200
		var spawn_position = Utils.random_vector2(spawn_padding, field_size.x - spawn_padding,\
			spawn_padding, field_size.y - spawn_padding)
		while not Utils.can_spawn(get_world_2d().direct_space_state, spawn_position, point_radius) and\
			find_position_attempts > 0:
			spawn_position = Utils.random_vector2(spawn_padding, field_size.x - spawn_padding,\
				spawn_padding, field_size.y - spawn_padding)
			find_position_attempts -= 1
		
		point_of_interest.global_position = spawn_position
		add_child(point_of_interest)
	
func spawn_obstacles():
	for i in range(obstacles_count):
		var obstacle := obstacle_scene.instantiate() as Node2D
		
		obstacle.scale.x = randf_range(obstacle_scale_range.x, obstacle_scale_range.y)
		obstacle.scale.y = obstacle.scale.x
		
		var obstacle_radius := 0.0
		for child in obstacle.get_children():
			if child is CollisionShape2D:
				obstacle_radius = child.shape.radius * obstacle.scale.x
		
		var find_position_attempts := 200
		var spawn_position = Utils.random_vector2(spawn_padding, field_size.x - spawn_padding,\
			spawn_padding, field_size.y - spawn_padding)
		while not Utils.can_spawn(get_world_2d().direct_space_state, spawn_position,\
			obstacle_radius) and find_position_attempts > 0:
			spawn_position = Utils.random_vector2(spawn_padding, field_size.x - spawn_padding,\
				spawn_padding, field_size.y - spawn_padding)
			find_position_attempts -= 1
				
		obstacle.global_position = spawn_position
		add_child(obstacle)
	
func _on_enemy_spawn_timeout():
	var enemy := enemy_scene.instantiate() as Enemy
	var enemy_radius := 0.0
	for child in enemy.get_children():
		if child is CollisionShape2D:
			enemy_radius = child.shape.radius * enemy.scale.x
	
	var find_position_attempts := 200
	var spawn_position = Utils.random_vector2(spawn_padding, field_size.x - spawn_padding,\
		spawn_padding, field_size.y - spawn_padding)
	while not Utils.can_spawn(get_world_2d().direct_space_state, spawn_position,\
		enemy_radius) and find_position_attempts > 0:
		spawn_position = Utils.random_vector2(spawn_padding, field_size.x - spawn_padding,\
			spawn_padding, field_size.y - spawn_padding)
		find_position_attempts -= 1
	
	if find_position_attempts <= 0:
		enemy.queue_free()
		return
		
	enemy.global_position = spawn_position
	add_child(enemy)
	
	
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

func _on_drone_destroyed():
	alive_drones -= 1
	if alive_drones <= 0:
		finished.emit(self, collected_points_of_interest, elapsed_time)
		queue_free()
