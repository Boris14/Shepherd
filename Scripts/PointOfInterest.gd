class_name PointOfInterest
extends Area2D

signal collected(point_of_interest : PointOfInterest)

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D):
	if body.is_in_group("Drone"):
		collected.emit(self)
		queue_free()
