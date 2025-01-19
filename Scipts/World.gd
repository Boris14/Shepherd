class_name World
extends Node2D

@export var POI_count = 10
@export var enemy_spawn_rate = 0.15
@export var drone_sight_radius = 300.0
@export var drones_count = 15
@export var drone_scene : PackedScene


func _ready():
	var drone = drone_scene.instantiate() as Drone
	add_child(drone)	
	drone.position = %DronesStart.position
