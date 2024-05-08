@tool

extends Node3D
class_name PedestrianController

@onready var reward_label = $"../Reward"

var level_manager: LevelManager

var pedestrians: Array = []  
var pedestrian_done: Dictionary = {}
var initial_pos: Dictionary = {}
var initial_rot: Dictionary = {}

var tot_reward: float = 0.0

func init(lm: LevelManager):
	level_manager = lm

func _ready():
	get_pedestrians()
	set_pedestrians_initial_state()

## Get all pedestrians
func get_pedestrians():
	pedestrians = find_children('Pedestrian*')
	for p in pedestrians:
		pedestrian_done[p] = false

## Set initial pos and rot for each pedestrian
func set_pedestrians_initial_state():
	for p in pedestrians:
		initial_pos[p] = p.global_position
		initial_rot[p] = p.rotation

## Returns spawn current position
func get_spawn_position(pedestrian: Pedestrian) -> Vector3:
	return initial_pos[pedestrian]

## Returns spawn current rotation
func get_spawn_rotation(pedestrian: Pedestrian) -> Vector3:
	return initial_rot[pedestrian]
	
## Set current reward in reward label
func set_reward_label_text(reward: float) -> void:
	tot_reward += reward
	var formatted_str = 'Score: %4.4f' % tot_reward
	reward_label.set_text(formatted_str)
	
## Check if all pedestrians have finished
func check_end_episode():
	
	for i in pedestrian_done.values():
		if not i:
			return
	
	for pedestrian in pedestrians:
		pedestrian.ai_controller_3d.done = true
		pedestrian.ai_controller_3d.reset()
		pedestrian.reset()
		pedestrian.enable_pedestrian()
		pedestrian_done[pedestrian] = false
	
	tot_reward = 0
	level_manager._notify_end_episode()
			
## set a single pedestrian as finished
func set_end_episode(pedestrian):
	pedestrian_done[pedestrian] = true
	check_end_episode()
