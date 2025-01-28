class_name Drone
extends CharacterBody2D

@export var speed := 200.0 

@onready var vision_area = $VisionArea
@onready var ray_cast = $RayCast2D as RayCast2D

var observed_drones : Array[Drone]

func _ready() -> void:
	ray_cast.enabled = true
	
	velocity = Vector2(randf(), randf())
	velocity = velocity.normalized() * speed
	
	vision_area.body_entered.connect(_body_entered_vision)
	vision_area.body_exited.connect(_body_exited_vision)
	
func _physics_process(delta: float) -> void:
	rotation = velocity.angle()
	move_and_slide()

func _body_entered_vision(body : Node2D):
	print(body.name)
	if body is Drone:
		observed_drones.append(body)
	elif body.is_in_group("Environment"):
		ray_cast.force_raycast_update()
		if ray_cast.is_colliding():
			velocity = ray_cast.get_collision_normal() * speed
			print(velocity)
		
func _body_exited_vision(body : Node2D):
	if body is Drone:
		observed_drones.erase(body)

func _draw():
	draw_line(ray_cast.position, ray_cast.target_position, Color.AQUAMARINE)
	return
	for drone in observed_drones:
		draw_line(global_position, drone.global_position, Color.BLUE)
