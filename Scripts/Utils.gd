class_name Utils
extends Object

static func add_unique(arr : Array, value):
	if value not in arr: 
		arr.append(value)

static func limit_vector_by_angle(origin : Vector2, desired : Vector2, angle_rad : float) -> Vector2:
	var result := desired
	var desired_angle = origin.angle_to(desired)
	 
	if abs(desired_angle) > angle_rad:
		var angle_sign = desired_angle / abs(desired_angle)
		result = origin.rotated(angle_rad * angle_sign).normalized() * desired.length()
		
	return result
