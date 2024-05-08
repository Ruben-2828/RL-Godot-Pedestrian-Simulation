@tool

extends Node3D
class_name LevelManager

## Signal emmitted on episode end
signal notify_end_episode(reward: float)


## Set all the level elements (pedestrians, targets, ai controllers...)
func set_level(level_scene: PackedScene) -> void:
	
	# Instantiating level scene
	var level = level_scene.instantiate()
	level.set_name("Level")
	add_child(level)
	
	# Setup pedestrian
	var pedestrians = level.find_children("Pedestrian*", "Pedestrian")
	for pedestrian in pedestrians:
		pedestrian.speed_max = Constants.MAX_SPEED if level.can_move else 0.0
	
	# Setup objective
	var objective = level.find_child("Objective")
	if objective != null:
		for pedestrian in pedestrians:
			objective.custom_body_entered.connect(pedestrian._on_objective_entered)
	
	# Setup final target
	var level_goal = level.find_child("FinalTarget")
	for pedestrian in pedestrians:
		level_goal.body_entered.connect(pedestrian._on_final_target_entered)
	
	# Setup random target when end episode
	var random_target = level.find_child("RandomTarget")
	if random_target != null: notify_end_episode.connect(random_target.get_end_episode)

	# Setup random spawn when end episode
	var random_spawn = level.find_child("RandomSpawn")
	if random_spawn != null: notify_end_episode.connect(random_spawn.get_end_episode)
	
	# Setup random objective when end episode
	var random_objective = level.find_child("RandomObjective")
	if random_objective != null: notify_end_episode.connect(random_objective.get_end_episode)
	
	# Setup random passage when end episode
	var random_passage = level.find_child("RandomPassage")
	if random_passage != null: notify_end_episode.connect(random_passage.get_end_episode)
	
	# Setup intermediate targets
	var targets := []
	targets.append_array(level.find_children("Target*", "Area3D"))
	targets.append_array(level.find_children("ObliqueTarget*", "Area3D"))
	#print(targets)
	for t in targets:
		for pedestrian in pedestrians:
			t.custom_body_entered.connect(pedestrian._on_target_entered)
	
	# Setup ai controller
	for pedestrian in pedestrians:
		var ai_controller = pedestrian.find_child("AIController3D")
		ai_controller.set_reset_after(level.max_steps)
		
	# Setup pedestrians controller
	var pedestrian_controller = level.find_child("PedestrianController")
	pedestrian_controller.init(self)
	

## Function called to emit signal for episode ending
func _notify_end_episode() -> void:
	notify_end_episode.emit()
