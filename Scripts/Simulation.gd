class_name Simulation
extends Node2D

signal finished(simulation : Simulation, is_forced : bool)

@export var enemy_spawn_rate = 3.0
@export var field_size_factor := 1.0
@export var points_of_interest_count := 10
@export var obstacles_count := 5
@export var obstacle_scale_range := Vector2(0.3, 1.3)
@export var enemy_scale_range := Vector2(0.5, 1.3)
@export var spawn_padding := 50

@export_category("Genetic Algorithm")
@export var separation_weight_range := Vector2(50000, 500000)
@export var cohesion_weight_range := Vector2(2, 10)
@export var alignment_weight_range := Vector2(0, 2)
@export var wander_weight_range := Vector2(0, 5)
@export var obstacle_avoidance_weight_range := Vector2(0, 5)
@export var poi_attraction_weight_range := Vector2(0, 100)
@export var enemy_repulsion_weight_range := Vector2(2, 20)

@export_category("Drones")
@export var drones_count = 10
@export var drone_spawn_check_increment := 20.0

@export_group("Flocking Behavior")
@export_range(50000, 500000, 100) var separation_weight := 100000.0
@export_range(2, 10.0, 0.05) var cohesion_weight := 5.0
@export_range(0.1, 2.0, 0.05) var alignment_weight := 0.5
@export_range(0.5, 5.0, 0.1) var wander_weight = 3.0

@export_group("Environment Reaction")
@export_range(0, 5.0, 0.1) var obstacle_avoidance_weight := 10.0
@export_range(0, 100.0, 0.5) var poi_attraction_weight := 50.0
@export_range(2, 20.0, 0.2) var enemy_repulsion_weight := 10.0

@export_category("Packed Scenes")
@export var drone_scene : PackedScene
@export var point_of_interest_scene : PackedScene
@export var obstacle_scene : PackedScene
@export var enemy_scene : PackedScene

@onready var camera: Camera = $Camera2D

var field_size : Vector2
var collected_points_of_interest : Array[PointOfInterest]
var elapsed_time := 0.0
var alive_drones := 0

func force_stop_simulation():
	finished.emit(self, true)
	queue_free()

func set_weights(weights : Array[float]):
	if weights.size() != 7:
		print("Incorrect number of weights")
		return
	separation_weight = weights[0]
	cohesion_weight = weights[1]
	alignment_weight = weights[2]
	wander_weight = weights[3]
	obstacle_avoidance_weight = weights[4]
	poi_attraction_weight = weights[5]
	enemy_repulsion_weight = weights[6]

func _ready():
	var field := StaticBody2D.new()
	var field_collision := CollisionPolygon2D.new()
	field_collision.polygon = generate_field_boundaries()
	field.collision_layer = 2
	field.add_child(field_collision)
	field.add_to_group("Environment")
	
	add_child(field)
	
	camera.position = Vector2(field_size.x / 2.0, field_size.y / 2.0)
	
	spawn_drones(%DronesStart.position)
	spawn_points_of_interest()
	spawn_obstacles()
	
	var enemy_spawn_timer := Timer.new()
	enemy_spawn_timer.wait_time = enemy_spawn_rate
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timeout)
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()
	
func _process(delta):
	elapsed_time += delta

func spawn_drones(pos : Vector2):
	var points = Utils.generate_spiral_points(pos, 1000, drone_spawn_check_increment)
	var point_i = 0
	for i in range(drones_count):
		while not Utils.can_spawn(get_world_2d().direct_space_state, points[point_i], 30.0) and\
			point_i < points.size(): 
			point_i += 1
		var drone := drone_scene.instantiate() as Drone
		drone.separation_weight = remap(separation_weight, 0, 1, separation_weight_range.x, separation_weight_range.y)
		drone.cohesion_weight = remap(cohesion_weight, 0, 1, cohesion_weight_range.x, cohesion_weight_range.y)
		drone.alignment_weight = remap(alignment_weight, 0, 1, alignment_weight_range.x, alignment_weight_range.y)
		drone.wander_weight = remap(wander_weight, 0, 1, wander_weight_range.x, wander_weight_range.y)
		drone.obstacle_avoidance_weight = remap(obstacle_avoidance_weight, 0, 1, obstacle_avoidance_weight_range.x, obstacle_avoidance_weight_range.y)
		drone.poi_attraction_weight = remap(poi_attraction_weight, 0, 1, poi_attraction_weight_range.x, poi_attraction_weight_range.y)
		drone.enemy_repulsion_weight = remap(enemy_repulsion_weight, 0, 1, enemy_repulsion_weight_range.x, enemy_repulsion_weight_range.y)
		drone.destroyed.connect(_on_drone_destroyed)
		drone.position = points[point_i]
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
		
		point_of_interest.position = spawn_position
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
				
		obstacle.position = spawn_position
		add_child(obstacle)
	
func _on_enemy_spawn_timeout():
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.scale.x *= randf_range(enemy_scale_range.x, enemy_scale_range.y)
	enemy.scale.y = enemy.scale.x
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
		
	enemy.position = spawn_position
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
	Utils.add_unique(collected_points_of_interest, point_of_interest)

func _on_drone_destroyed():
	alive_drones -= 1
	if alive_drones <= 0:
		finished.emit(self, false)
		queue_free()
