extends CurriculumPhase

## Number of instances used for each level
@export var instances_per_level: int = Constants.RETRAINING_INSTANCES_PER_LEVEL

## Spawns all the level managers
func spawn_level_managers() -> void:
	
	# Generating three level managers for each level in the curriculum
	for i in range(levels_path.size()):
		for j in range(instances_per_level):
			var level_manager_instance := level_manager_scene.instantiate()
			level_manager_instance.set_name("LevelManager" + str(i) + str(j))
			level_manager_instance.position.x = i * level_position_offset
			level_manager_instance.position.z = j * level_position_offset
			level_managers.append(level_manager_instance)
			add_child(level_manager_instance)
			level_manager_instance.notify_end_episode.connect(check_level_progress)
			level_manager_instance.set_current_level(levels_path[i])

## Set current level for every level manager
func set_current_level() -> void:
	#assert(false, "the set_current_level method is not implemented when extending from CurriculumPhase")
	pass

## Change current level if success condition is reached
func check_level_progress(reward: float) -> void:
	#assert(false, "the check_level_progress method is not implemented when extending from CurriculumPhase")
	pass
