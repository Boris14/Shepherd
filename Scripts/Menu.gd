class_name Menu
extends Control

@export_category("Simulation Windows")
@export var window_spacing := Vector2i(50, 50)  # Distance between windows
@export var window_border_size := 25
@export var window_border_color := Color.WHITE

@export_category("Simulations")
@export var simulation_scene : PackedScene
@export_range(1, 100) var train_simulations_count := 20
@export_range(1.0, 20.0, 0.01) var train_simulation_time_scale := 20.0

@export_category("Genetic Algorithm")
@export_range(0, 1.0, 0.01) var crossover_rate := 0.8
@export_range(0, 1.0, 0.01) var mutation_rate := 0.3
@export_range(0, 0.8, 0.01) var mutation_strength := 0.3
@export var survival_time_weight := 1.0
@export var collected_points_of_interest_weight := 10.0
@export var generations_count := 3

var population : Array
var fitness : Array[float]
var generation := 0

var simulations_in_progress : Array[Simulation]

var total_poi_collected := 0
var total_elapsed_time := 0.0

var best_weights : Array[float]

var window_start_position := Vector2i(10, 10) 
var current_window_position := window_start_position

@onready var screen_size := DisplayServer.screen_get_size()
@onready var window_size := DisplayServer.window_get_size()

func _ready():	
	$TrainButton.pressed.connect(_on_train_button_pressed)
	$SimulationButton.pressed.connect(_on_simulation_button_pressed)
	
	var genetic_text := "Population Size: " + str(train_simulations_count) + "\n"
	genetic_text += "Generations: " + str(generations_count) + "\n "
	$GeneticBoxContainer/GeneticParameters.text = genetic_text
	
	for i in range(7):
		best_weights.append(randf())
		
	display_weights(best_weights)

func _on_train_button_pressed():
	if simulations_in_progress.size() > 0:
		return
	
	initialize_population()
	run_population_simulations()
	Engine.time_scale = train_simulation_time_scale
		
		
func _on_simulation_button_pressed():
	if simulations_in_progress.size() > 0:
		return
	
	create_simulation_window(_on_individual_simulation_finished, best_weights)
		
	
func create_simulation_window(on_finished :Callable, weights = null, index := -1) -> Simulation:	
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
	if weights != null:
		simulation_instance.set_weights(weights)
	simulation_instance.name = "Simulation"
	if index > 0:
		simulation_instance.name += "_" + str(index)
	simulation_instance.finished.connect(on_finished.bind(sim_window, index))
	sim_window.add_child(simulation_instance)
	sim_window.close_requested.connect(simulation_instance.force_stop_simulation)
	add_child(sim_window)
	sim_window.show()
	simulations_in_progress.append(simulation_instance)
	
	return simulation_instance
	
func initialize_population():
	population.clear()
	fitness.clear()
	for i in range(train_simulations_count):
		var individual : Array[float]
		for j in range(7):
			individual.append(randf())
		population.append(individual)
		fitness.append(0)
		
func run_population_simulations():
	for i in range(population.size()):
		var simulation = create_simulation_window(_on_train_simulation_finished, population[i], i)

func fitness_function(simulation : Simulation):
	return survival_time_weight * simulation.elapsed_time +\
		collected_points_of_interest_weight * simulation.collected_points_of_interest.size()

func _tournament_selection(k = 3):
	var candidates = []
	for i in range(k):
		candidates.append(randi() % train_simulations_count)
	
	var best_index = candidates[0]
	for i in candidates:
		if fitness[i] > fitness[best_index]:
			best_index = i

	return population[best_index]

func _crossover(parent1 : Array[float], parent2 : Array[float]):
	var num_weights := parent1.size()
	if randf() < crossover_rate:
		var point = randi() % num_weights
		var child1 = parent1.slice(0, point) + parent2.slice(point, num_weights)
		var child2 = parent2.slice(0, point) + parent1.slice(point, num_weights)
		return [child1, child2]
	return [parent1, parent2]

func _mutate(individual : Array[float]):
	for i in range(individual.size()):
		if randf() < mutation_rate:
			individual[i] += randf_range(-mutation_strength, mutation_strength)
			individual[i] = clamp(individual[i], 0, 1.0)
	return individual

func _generate_new_population():
	var new_population = []
	while new_population.size() < train_simulations_count:
		var parent1 = _tournament_selection()
		var parent2 = _tournament_selection()
		var offspring = _crossover(parent1, parent2)
		new_population.append(_mutate(offspring[0]))
		new_population.append(_mutate(offspring[1]))
	
	population = new_population.slice(0, train_simulations_count) 
	generation += 1

func show_best_individual():
	Engine.time_scale = 1.0
	var best_index := 0
	for i in range(fitness.size()):
		if fitness[i] > fitness[best_index]:
			best_index = i
	var simulation = create_simulation_window(_on_individual_simulation_finished, population[best_index])
	display_weights(population[best_index])

func _on_individual_simulation_finished(simulation : Simulation, is_forced : bool, window : Window, index : int):
	simulations_in_progress.erase(simulation)
	window.queue_free()


func _on_train_simulation_finished(simulation : Simulation, is_forced : bool, window : Window, index : int):
	if not is_forced:
		fitness[index] = fitness_function(simulation)
	simulations_in_progress.erase(simulation)
	window.queue_free()
	if simulations_in_progress.size() <= 0:
		if generation >= generations_count:
			generation = 0
			show_best_individual()
		else:
			_generate_new_population()
			run_population_simulations()
			
func display_weights(weights : Array[float]):
	if weights.size() != 7:
		return
	var text := "Separation: " + str(weights[0]).substr(0, 4) + "\n"
	text += "Cohesion: " + str(weights[1]).substr(0, 4) + "\n"
	text += "Alignment: " + str(weights[2]).substr(0, 4) + "\n"
	text += "Wander: " + str(weights[3]).substr(0, 4) + "\n"
	text += "Obstacle Avoidance: " + str(weights[4]).substr(0, 4) + "\n"
	text += "POI Attraction: " + str(weights[5]).substr(0, 4) + "\n"
	text += "Enemy Repulsion: " + str(weights[6]).substr(0, 4) + "\n "
	$WeightsBoxContainer/Weights.text = text
