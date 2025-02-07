class_name PointOfInterest
extends StaticBody2D

signal collected(point_of_interest : PointOfInterest)

func _ready():
	$Area2D.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D):
	if body.is_in_group("Drone"):
		collected.emit(self)
		queue_free()
