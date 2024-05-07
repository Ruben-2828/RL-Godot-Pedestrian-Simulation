@tool

extends Node3D

## List of levels used in curriculum
@export var levels_path: Array[PackedScene]
## Number of levels executed in parallel
@export_range(1, 16) var batch_size: int = Constants.TRAINING_BATCH_SIZE

var current_level: LevelNode = null 
var current_level_idx: int = 0
var level_progress: int = 0

const level_manager_scene: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: int = Constants.LEVELS_OFFSET

@onready var sync = $Sync

func _ready():
	spawn_level_managers()
	set_current_level()

## Spawns the level managers according to batch size
func spawn_level_managers() -> void:
	
	# Generating batch of level managers
	for i in range(batch_size):
		var level_manager_instance := level_manager_scene.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		level_manager_instance.notify_end_episode.connect(check_level_progress)
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)

## Set current level for every level manager
func set_current_level() -> void:
	
	if current_level != null:
		current_level.queue_free()
		
	current_level = levels_path[current_level_idx].instantiate()
	
	for lm in level_managers:
		lm.set_current_level(levels_path[current_level_idx])
		

## Change current level if success condition is reached
func check_level_progress(reward: float) -> void:
	
	if reward >= current_level.min_reward:
		level_progress += 1
	else:
		level_progress = 0
		
	if level_progress >= current_level.success:
		current_level_idx += 1
		if current_level_idx < levels_path.size():
			level_progress = 0
			set_current_level()
		else:
			print("End")


