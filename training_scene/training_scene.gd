@tool

extends Node3D

@export_category("Curriculum")
## Number of levels executed in parallel
@export_range(1, 16) var batch_size: int = 10
@export_group("Levels")
## List of levels used in curriculum
@export var levels_path: Array[PackedScene]

var current_level: LevelNode = null
var current_level_idx: int = 0
var level_progress: int = 0

const level_manager_scene: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: int = 50

func _ready():
	assert(levels_path.size() > 0, "No scenes set for training")
	assert(check_levels(), "null levels not allowed for training")
	
	spawn_level_managers()
	
	set_current_level(current_level_idx)

## Checks the levels list in input
func check_levels() -> bool:
	for l in levels_path:
		if l == null:
			return false
	return true

## Spawns the level managers according to batch size
func spawn_level_managers() -> void:
	
	# Generating batch of level managers
	for i in range(batch_size):
		#print("level manager numero " + str(i))
		var level_manager_instance := level_manager_scene.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		level_manager_instance.notify_end_episode.connect(check_level_progress)
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)

## Set current level for every level manager
func set_current_level(level: int) -> void:
	
	if current_level != null:
		current_level.queue_free()
		
	current_level = levels_path[level].instantiate()
	
	#print("changing to level: "+ str(level))
	
	for lm in level_managers:
		lm.set_current_level(levels_path[level])

## Change current level if success condition is reached
func check_level_progress(passed: bool, reward: float) -> void:
	
	if passed and reward >= current_level.min_reward:
		level_progress += 1
	else:
		level_progress = 0
		
	if level_progress >= current_level.success:
		current_level_idx += 1
		current_level_idx %= levels_path.size()
		level_progress = 0
		set_current_level(current_level_idx)
