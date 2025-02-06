class_name Menu
extends Control

@export var window_size := Vector2i(960, 540)  # Customize window size
@export var spacing := Vector2i(50, 50)  # Distance between windows

@export var simulation_scene : PackedScene
@export_range(1, 100) var simulations_count := 20
@export_range(1.0, 20.0, 0.01) var simulation_time_scale := 20.0

var simulations : Array[Simulation]
var simulations_in_progress := false

var total_poi_collected := 0
var total_elapsed_time := 0.0

var start_position := Vector2i(10, 10) 
var current_position := start_position

@onready var screen_size := DisplayServer.screen_get_size()

func _ready():	
	$StartButton.pressed.connect(_on_start_button_pressed)
		
func _on_start_button_pressed():
	if simulations_in_progress:
		return
	
	simulations_in_progress = true
	for i in range(simulations_count):
		create_simulation_window(i)
		
	Engine.time_scale = simulation_time_scale
		
func _on_simulation_finished(simulation : Simulation, window : Window):
	total_poi_collected += simulation.collected_points_of_interest
	total_elapsed_time += simulation.elapsed_time
	simulations.erase(simulation)
	window.hide()
	if simulations.is_empty():
		print("Avarage: " + str(total_poi_collected / simulations_count))
		print("Time: " + str(total_elapsed_time / simulations_count))
		Engine.time_scale = 1.0
		total_poi_collected = 0
		total_elapsed_time = 0
		simulations_in_progress = false
		
	
func create_simulation_window(index: int):
	var sim_window := Window.new()
	sim_window.size = window_size
	sim_window.title = "Simulation " + str(index)
	sim_window.mode = Window.MODE_WINDOWED
	sim_window.position = current_position
	
	var simulation_instance = simulation_scene.instantiate() as Simulation
	simulation_instance.name = "Simulation_" + str(index)
	simulation_instance.finished.connect(_on_simulation_finished.bind(sim_window))
	simulations.append(simulation_instance)
	sim_window.add_child(simulation_instance)
	add_child(sim_window)
	sim_window.show()
	
	# Move to the next window position in the row
	current_position.x += spacing.x

	# If the next window would go off-screen, move to a new row
	if current_position.x + window_size.x > screen_size.x:
		current_position.x = start_position.x  # Reset X to start of row
		current_position.y += spacing.y  # Move to next row
	
