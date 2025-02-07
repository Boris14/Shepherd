class_name Enemy
extends CharacterBody2D

@export var speed := 80

var seen_drones : Array[Drone]
var target_drone : Drone

@onready var vision_area = $VisionArea

func _ready():
	vision_area.body_entered.connect(_on_body_entered)
	vision_area.body_exited.connect(_on_body_exited)
	
	velocity = Vector2(randf(), randf()).normalized() * speed
	
func _physics_process(delta):
	for drone in seen_drones:
		if target_drone == null or\
		global_position.distance_squared_to(drone.global_position) <\
		global_position.distance_squared_to(target_drone.global_position):
			target_drone = drone
	
	if target_drone != null:
		velocity = (target_drone.global_position - global_position).normalized() * speed
		
	rotation = velocity.angle()
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is Drone:
			collider.destroy()
		elif collider is Enemy or collider is Node and collider.is_in_group("Environment"):
			velocity = collision.get_normal() * speed
	
	
func _on_body_entered(body : Node2D):
	if body is Drone:
		Utils.add_unique(seen_drones, body)

func _on_body_exited(body : Node2D):
	if body is Drone:
		seen_drones.erase(body)
