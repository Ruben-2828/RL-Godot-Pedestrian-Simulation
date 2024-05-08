@tool

extends Node3D
class_name PedestrianController

@onready var reward_label = $"../Reward"

var pedestrians: Array = []  
var pedestrian_done: Dictionary = {}
var initial_pos: Dictionary = {}
var initial_rot: Dictionary = {}

func _ready():
	get_pedestrians()
	set_pedestrians()
	
	
func set_pedestrians():
	for p in pedestrians:
		initial_pos[p] = p.global_position
		initial_rot[p] = p.rotation

## Returns spawn current position
func get_spawn_position(pedestrian: Pedestrian) -> Vector3:
	return initial_pos[pedestrian]

## Returns spawn current rotation
func get_spawn_rotation(pedestrian: Pedestrian) -> Vector3:
	return initial_rot[pedestrian]
	
	
func get_pedestrians():
	pedestrians = find_children('Pedestrian*')
	for p in pedestrians:
		pedestrian_done[p] = false
	
	
## Set current reward in reward label
func set_reward_label_text(reward: float) -> void:
	var formatted_str = 'Score: %4.4f' % reward
	reward_label.set_text(formatted_str)
	
## check if all pedestrians have finished
func check_end_episode():
	var done = true
	for i in pedestrian_done.values():
		if not i:
			done = false
			break
	if done:
		for pedestrian in pedestrians:
			pedestrian.ai_controller_3d.done = true
			pedestrian.reset()
			pedestrian.enable_pedestrian(pedestrian)
			pedestrian_done[pedestrian] = false
			
## set a single pedestrian as finished
func set_end_episode(pedestrian):
	pedestrian_done[pedestrian] = true
	

