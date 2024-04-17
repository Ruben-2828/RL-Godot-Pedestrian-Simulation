@tool

extends Node3D

@export_category("Curriculum")
@export_range(1, 16) var batch_size: int = 10
@export_group("Scenes")
@export var levels_path: Array[PackedScene]

var current_scene: int = 0
var scene_progress: int = 0
const LEVEL_MANAGER: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: int = 50

func _ready():
	assert(levels_path.size() > 0, "No scenes set for training")
	assert(check_levels(), "null levels not allowed for training")
	
	spawn_level_managers()
	
	set_current_scene(current_scene)

func _process(delta):
	pass

func check_levels() -> bool:
	for l in levels_path:
		if l == null:
			return false
	return true

func spawn_level_managers() -> void:
	
	# Generating batch of level managers
	for i in range(batch_size):
		print("level manager numero " + str(i))
		var level_manager_instance := LEVEL_MANAGER.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		level_manager_instance.notify_end_episode.connect(check_scene_progress)
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)

func set_current_scene(scene: int) -> void:
	
	print("changing to scene: "+ str(scene))
	
	for lm in level_managers:
		lm.set_current_level(levels_path[scene])
		
func check_scene_progress(passed: bool, reward: float) -> void:
	
	var level = levels_path[current_scene].instantiate()
	print(reward)
	
	if passed and reward >= level.min_reward:
		scene_progress += 1
	else:
		scene_progress = 0
		
	#print(scene_progress)
		
	if scene_progress >= level.success:
		current_scene += 1
		current_scene %= levels_path.size()
		scene_progress = 0
		set_current_scene(current_scene)
		
	level.queue_free()
	
