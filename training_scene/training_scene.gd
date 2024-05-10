@tool

extends Node3D

## List of levels used in curriculum
@export var levels_path: Array[PackedScene]

var current_level
var current_level_idx: int = 0

func _ready():
	set_current_level()

## Set current level for every level manager
func set_current_level() -> void:
	
	if current_level != null:
		current_level.queue_free()
	
	
	current_level = levels_path[current_level_idx].instantiate()
	current_level.set_name("CurrentLevel")
	add_child(current_level)
	current_level_idx += 1
	
