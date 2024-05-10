extends Node

@export var level: PackedScene
var batch_size: int = Constants.TRAINING_BATCH_SIZE

var level_manager_scene: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: int = Constants.LEVELS_BATCH_OFFSET

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_level_managers()

## Spawns the level managers according to batch size
func spawn_level_managers() -> void:
	
	# Generating batch of level managers
	for i in range(batch_size):
		var level_manager_instance := level_manager_scene.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		#level_manager_instance.notify_end_episode.connect(check_level_progress)
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)
		level_manager_instance.set_level(level)

func finish():
	for lm in level_managers:
		lm.free()	
	get_parent().set_current_level()
