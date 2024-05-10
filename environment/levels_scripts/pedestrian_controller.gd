@tool

extends Node3D
class_name PedestrianController

@onready var reward_label = $"../Reward"

var level_manager: LevelManager

var pedestrians: Array = []  
var pedestrian_done: Dictionary = {}
var initial_pos: Dictionary = {}
var initial_rot: Dictionary = {}

var random_area: Area3D
var random_rot: bool

var tot_reward: float = 0.0

func init(lm: LevelManager):
	level_manager = lm

func _ready():
	get_pedestrians()

## Get all pedestrians
func get_pedestrians():
	pedestrians = find_children('Pedestrian*')
	for p in pedestrians:
		pedestrian_done[p] = false

## Set initial pos and rot for each pedestrian
func set_pedestrians_initial_state():
	for p in pedestrians:
		initial_pos[p] = p.global_position
		initial_rot[p] = p.rotation if not random_rot else randomize_rot
		

## perform randomization of pedestrian position
func randomize_pos():
	var collision_shape = random_area.find_child("CollisionShapeSpawn") as CollisionShape3D
	var box_shape = collision_shape.shape as BoxShape3D
	var extents = box_shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x, extents.x),
		0.0,  
		randf_range(-extents.z, extents.z)
		)
	return random_pos
	
	
## perform randomization of pedestrian rotation
func randomize_rot():
	var random_rot = randi_range(0, Constants.ROTATION_STEPS - 1) * (360 / Constants.ROTATION_STEPS)
	return Vector3(0.0, random_rot, 0)

## Returns spawn current position
func get_spawn_position(pedestrian: Pedestrian) -> Vector3:
	if random_area != null:
		return initial_pos[pedestrian] + randomize_pos()
	return initial_pos[pedestrian]

## Returns spawn current rotation
func get_spawn_rotation(pedestrian: Pedestrian) -> Vector3:
	if initial_rot[pedestrian] is Vector3:
		return initial_rot[pedestrian]
	return initial_rot[pedestrian].call()
	
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
		pedestrian.ai_controller_3d.reset()
		pedestrian.reset()
		pedestrian_done[pedestrian] = false
		pedestrian.enable_pedestrian()
	# ai controller done for only the first pedestrian to end the episode only one time
	pedestrians[0].ai_controller_3d.done = true
	
	tot_reward = 0
	level_manager._notify_end_episode()
			
## set a single pedestrian as finished
func set_end_episode(pedestrian):
	pedestrian_done[pedestrian] = true
	check_end_episode()
