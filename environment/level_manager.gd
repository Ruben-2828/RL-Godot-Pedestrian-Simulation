@tool

extends Node3D
class_name LevelManager

## Signal emmitted on episode end
signal notify_end_episode(passed: bool, reward: float)

@onready var player = $"Player"

var level_start_area: Node3D
var level_goal: Node3D
var level: Node3D = null

## Returns spawn current position
func get_spawn_position() -> Vector3:
	return level_start_area.global_position

## Returns spawn current rotation
func get_spawn_rotation() -> Vector3:
	return level_start_area.rotation

## Set current reward in reward label
func set_reward_label_text(reward: float) -> void:
	var label = level.find_child('Reward')
	var formatted_str = 'reward: %4.4f' % reward
	label.set_text(formatted_str)

## Removes old level, and add the new one
func set_current_level(scene: PackedScene) -> void:
	
	if level != null:
		level.queue_free()
	
	# Instantiating level scene
	level = scene.instantiate()
	level.set_name("CurrentLevel")
	add_child(level)
	
	# Setup spawn
	level_start_area = level.find_child("Spawn")
	
	# Setup final target
	level_goal = level.find_child("FinalTarget")
	level_goal.body_entered.connect(player._on_final_target_entered)
	
	# Setup intermediate targets
	var targets := []
	targets.append_array(level.find_children("Target*", "Area3D"))
	targets.append_array(level.find_children("ObliqueTarget*", "Area3D"))
	#print(targets)
	for t in targets:
		t.custom_body_entered.connect(player._on_target_entered)
	
	# Setup ai controller
	var ai_controller = player.find_child("AIController3D")
	ai_controller.set_reset_after(level.max_steps)
		
	player.reset()

## Function called to emit signal for episode ending
func _notify_end_episode(passed: bool, reward: float) -> void:
	notify_end_episode.emit(passed, reward)
