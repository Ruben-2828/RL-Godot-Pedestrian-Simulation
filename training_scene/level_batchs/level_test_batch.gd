extends LevelBatch

var end_episode_count: int = 0 
const number_of_episode:= Constants.DEFAULT_NUMBER_OF_EPISODE

var pedpy_log_file

func _ready():
	pedpy_log_file = FileAccess.open("res://output/pedpy_logs/" + name + ".txt", FileAccess.WRITE)
	init_sample_file()
	
	spawn_level_managers()

func spawn_level_managers() -> void:
	# Generating batch of level managers
	for i in range(batch_size):
		var level_manager_instance := level_manager_scene.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		level_manager_instance.notify_end_episode.connect(_on_notify_end_episode)
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)
		level_manager_instance.set_level(level, pedpy_log_file)

#Initialize the sample file	
func init_sample_file():
	pedpy_log_file.store_line("# framerate: %s fps" % 
		(Engine.physics_ticks_per_second / Constants.SPEED_UP / Constants.TICKS_BETWEEN_LOG))
	pedpy_log_file.store_line("# id frame x/m y/m z/m")

func _on_notify_end_episode():
	end_episode_count += 1
	check_end_level()

func check_end_level():
	if end_episode_count >= number_of_episode:
		finish()
		
## Close file when the node is removed from the scene
func _exit_tree():
	if pedpy_log_file:
		pedpy_log_file.close()
