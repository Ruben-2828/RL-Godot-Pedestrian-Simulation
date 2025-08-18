extends Node3D
class_name TrainingScene

## List of levels used in curriculum
@export var levels_path: Array[PackedScene]
@onready var sync = $Sync
@onready var camera = $Camera3D

var level_manager_scene: PackedScene = preload("res://environments/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: float = Constants.LEVELS_BATCH_OFFSET

var current_level
var current_level_idx: int = 0

func _ready():
	spawn_level_managers()
	set_current_level()

## Set current active level
func set_current_level() -> void:
	
	sync.set_physics_process(false)
	
	if current_level != null:
		current_level.disable_pedestrians()
	
	if current_level_idx < levels_path.size():
		camera.position.x = current_level_idx * level_position_offset
		
		current_level = level_managers[current_level_idx]
		current_level.enable_pedestrians()
		current_level.reset_pedestrians()
		
		current_level_idx += 1
	else:
		get_tree().quit()
		
	sync.set_physics_process(true)

## Generating the levels		
func spawn_level_managers() -> void:
	
	var i = 0
	for level in levels_path:
		var level_manager_instance := level_manager_scene.instantiate()
		level_manager_instance.set_name("LevelManager" + str(i))
		level_manager_instance.position.x = i * level_position_offset
		
		level_managers.append(level_manager_instance)
		add_child(level_manager_instance)
		level_manager_instance.set_level(level, null)
		level_manager_instance.disable_pedestrians()
		i += 1

