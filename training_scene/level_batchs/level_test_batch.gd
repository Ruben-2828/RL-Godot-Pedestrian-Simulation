extends LevelBatch

var end_episode_count: int = 0 
const number_of_episode:= Constants.DEFAULT_NUMBER_OF_EPISODE

func spawn_level_managers() -> void:
	# Generating batch of level managers
	for i in range(batch_size):
		var level_manager_instance := level_manager_scene.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		level_manager_instance.notify_end_episode.connect(_on_notify_end_episode)
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)
		level_manager_instance.set_level(level)

func _on_notify_end_episode():
	end_episode_count += 1
	check_end_level()

func check_end_level():
	if end_episode_count >= number_of_episode:
		finish()
