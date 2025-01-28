class_name Drone
extends CharacterBody2D

@export var speed := 200.0

func _ready() -> void:
	velocity = Vector2(randf(), randf())
	velocity = velocity.normalized() * speed
	
func _physics_process(delta: float) -> void:
	move_and_slide()
