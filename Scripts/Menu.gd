class_name Menu
extends Control

@export var window_spacing := Vector2i(50, 50)  # Distance between windows
@export var window_border_size := 25
@export var window_border_color := Color.WHITE

@export var simulation_scene : PackedScene
@export_range(1, 100) var train_simulations_count := 20
@export_range(1.0, 20.0, 0.01) var train_simulation_time_scale := 20.0

var simulations : Array[Simulation]
var simulations_count := 0
var simulation_in_progress := false

var total_poi_collected := 0
var total_elapsed_time := 0.0

var window_start_position := Vector2i(10, 10) 
var current_window_position := window_start_position

@onready var screen_size := DisplayServer.screen_get_size()
@onready var window_size := DisplayServer.window_get_size()

func _ready():	
	$TrainButton.pressed.connect(_on_train_button_pressed)
	$SimulationButton.pressed.connect(_on_simulation_button_pressed)

func _on_train_button_pressed():
	if simulation_in_progress:
		return
	
	simulation_in_progress = true
	for i in range(train_simulations_count):
		create_simulation_window(i)
		simulations_count += 1
		
	Engine.time_scale = train_simulation_time_scale
		
func _on_simulation_button_pressed():
	if simulation_in_progress:
		return
	
	simulation_in_progress = true
	simulations_count = 1
	create_simulation_window()


func _on_simulation_finished(simulation : Simulation, is_forced : bool, window : Window):
	if not is_forced:
		total_poi_collected += simulation.collected_points_of_interest.size()
		total_elapsed_time += simulation.elapsed_time
	else:
		simulations_count -= 1
	simulations.erase(simulation)
	window.hide()
	if simulations.is_empty():
		var avarage_poi_collected := total_poi_collected
		var avarage_elapsed_time := total_elapsed_time
		if simulations_count > 0:
			avarage_poi_collected /= simulations_count
			avarage_elapsed_time /= simulations_count
		elif is_forced:
			avarage_poi_collected = simulation.collected_points_of_interest.size()
			avarage_elapsed_time = simulation.elapsed_time
		print("Avarage: " + str(avarage_poi_collected))
		print("Time: " + str(avarage_elapsed_time))
		Engine.time_scale = 1.0
		total_poi_collected = 0
		total_elapsed_time = 0
		simulations_count = 0
		simulation_in_progress = false
		
	
func create_simulation_window(index := -1):	
	var sim_window := Window.new()
	sim_window.size = window_size + Vector2i(window_border_size, window_border_size)
	sim_window.title = "Simulation "
	sim_window.mode = Window.MODE_WINDOWED
	sim_window.unresizable = true
	
	if index > 0:
		sim_window.title += str(index)
		sim_window.position = current_window_position
		
		# Offset windows so they don't overlap
		current_window_position.x += window_spacing.x
		if current_window_position.x + window_size.x > screen_size.x:
			current_window_position.x = window_start_position.x
			current_window_position.y += window_spacing.y
	else:
		sim_window.position = screen_size / 2 - window_size / 2
	
	var rect = ColorRect.new()
	rect.color = window_border_color
	rect.size = window_size + Vector2i(window_border_size, window_border_size)
	rect.position = -Vector2(window_border_size / 2, window_border_size / 2)
	sim_window.add_child(rect)
	
	var simulation_instance = simulation_scene.instantiate() as Simulation
	simulation_instance.name = "Simulation"
	if index > 0:
		simulation_instance.name += "_" + str(index)
	simulation_instance.finished.connect(_on_simulation_finished.bind(sim_window))
	simulations.append(simulation_instance)
	sim_window.add_child(simulation_instance)
	sim_window.close_requested.connect(simulation_instance.force_stop_simulation)
	add_child(sim_window)
	sim_window.show()
