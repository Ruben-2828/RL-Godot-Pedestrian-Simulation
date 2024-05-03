extends Node

class_name CurriculumPhase

var levels_path: Array[PackedScene]

var current_level: LevelNode = null 
var current_level_idx: int = 0
var level_progress: int = 0

const level_manager_scene: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: int = Constants.LEVELS_OFFSET

@onready var sync = $Sync

## Signal to notify the end of the training phase
signal end_phase

func _ready():
	spawn_level_managers()
	#await get_tree().ready()
	set_current_level()
	
## Spawns all the level managers
func spawn_level_managers() -> void:
	assert(false, "the spawn_level_managers method is not implemented when extending from CurriculumPhase")

## Set current level for every level manager
func set_current_level() -> void:
	assert(false, "the set_current_level method is not implemented when extending from CurriculumPhase")

## Change current level if success condition is reached
func check_level_progress(reward: float) -> void:
	assert(false, "the check_level_progress method is not implemented when extending from CurriculumPhase")

## Handle the ending of the current phase
func finish() -> void:
	
	# Remove all level managers to avoid conflicts with the next phase
	for lm in level_managers:
		lm.free()
		
	end_phase.emit()
