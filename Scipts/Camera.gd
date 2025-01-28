class_name Camera
extends Camera2D

@export var drag_sensitivity := 3.0
@export var zoom_sensitivity := 0.03
@export var max_zoom := 1.5
@export var min_zoom := 0.3

var is_dragging := false
var drag_start_position := Vector2.ZERO
var target_position := Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_dragging:
		global_position = lerp(global_position, target_position, 0.2)
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:  # Mouse button down
				is_dragging = true
				drag_start_position = get_global_mouse_position()
				target_position = global_position
			else:  # Mouse button released
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoom_sensitivity, zoom_sensitivity)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoom_sensitivity, zoom_sensitivity)
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)

	# Handle mouse motion while dragging
	if event is InputEventMouseMotion and is_dragging:
		var current_mouse_position = get_global_mouse_position()
		var drag_offset = (drag_start_position - current_mouse_position) * drag_sensitivity
		target_position = global_position + drag_offset
		drag_start_position = current_mouse_position

func _draw() -> void:
	pass
