extends Node

@export var level: PackedScene
var batch_size: int = Constants.TESTING_BATCH_SIZE

var level_manager_scene: PackedScene = preload("res://environments/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: float = Constants.LEVELS_BATCH_OFFSET

var end_episode_count: int = 0 
const number_of_episode:= Constants.DEFAULT_NUMBER_OF_EPISODE

var pedpy_log_file: FileAccess
var path = Constants.PATH_PEDPY_LOGS

@onready var sync = $Sync

## Called when the node enters the scene tree for the first time
func _ready():
	
	pedpy_log_file = FileAccess.open(path + name + ".txt", FileAccess.WRITE)
	init_sample_file()
	spawn_level_managers()
	
	sync.onnx_model_path = get_parent().onnx_model_path


## Spawns the level managers according to batch size
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

## Initialize the sample file	
func init_sample_file():
	pedpy_log_file.store_line("# framerate: %s fps" % 
		(float(Constants.PHYSICS_TICKS_PER_SECONDS) / float(Constants.TICKS_BETWEEN_LOG)))
	pedpy_log_file.store_line("# id frame x/m y/m z/m")

## Episode counter
func _on_notify_end_episode():
	end_episode_count += 1
	check_end_level()

## Check if episode count reached the number of episode
func check_end_level():
	if end_episode_count >= number_of_episode:
		finish()

## Function called to finish the testing batch
func finish():
	var all_agents = get_tree().get_nodes_in_group(Constants.AGENT_GROUP)
	for agent in all_agents:
		agent.remove_from_group(Constants.AGENT_GROUP)
	get_parent().set_current_level()
		
## Close file when the node is removed from the scene
func _exit_tree():
	if pedpy_log_file:
		pedpy_log_file.close()
