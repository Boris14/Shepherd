class_name Master
extends Node2D

@export var simulation_scene : PackedScene
@export var simulations_count := 1

var simulations : Array[Simulation]

func _ready():
	for i in range(simulations_count):
		var simulation = simulation_scene.instantiate() as Simulation
		simulation.finished.connect(_on_simulation_finished)
		simulation.visible = i == 0
		add_child(simulation)
		simulations.append(simulation)
		
func _on_simulation_finished(simulation : Simulation, poi_collected : int, elapsed_time : float):
	print("Collected: " + str(poi_collected))
	print("Time: " + str(elapsed_time))
	simulations.erase(simulation)
	if simulations.is_empty():
		get_tree().quit()
	
