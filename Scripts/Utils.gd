class_name Utils
extends Object

static func add_unique(arr : Array, value):
	if value not in arr: 
		arr.append(value)

static func generate_spiral_points(origin: Vector2, points_count: int, increment: int) -> Array:
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

static func can_spawn(space_state : PhysicsDirectSpaceState2D, \
	position : Vector2, body_radius : float) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = body_radius
	params.shape = circle_shape
	params.transform = Transform2D(0, position)
	var hits : Array = space_state.intersect_shape(params)
	return hits.size() == 0

static func random_vector2(min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	return Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

static func limit_vector_by_angle(origin : Vector2, desired : Vector2, angle_rad : float) -> Vector2:
	var result := desired
	var desired_angle = origin.angle_to(desired)
	 
	if abs(desired_angle) > angle_rad:
		var angle_sign = desired_angle / abs(desired_angle)
		result = origin.rotated(angle_rad * angle_sign).normalized() * desired.length()
		
	return result
