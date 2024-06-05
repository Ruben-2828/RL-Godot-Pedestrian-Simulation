extends Node3D
class_name TrainingScene

## List of levels used in curriculum
@export var levels_path: Array[PackedScene]

var current_level
var current_level_idx: int = 0

## Called when the node enters the scene tree for the first time
func _ready():
	set_current_level()

## Set current level for every level manager
func set_current_level() -> void:
	
	if current_level != null:
		current_level.find_child("Sync").set_physics_process(false)
		current_level.queue_free()
	
	if current_level_idx < levels_path.size():
		current_level = levels_path[current_level_idx].instantiate()
		add_child(current_level)
		current_level_idx += 1
	else:
		get_tree().quit()
	
