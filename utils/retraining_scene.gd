
extends Node3D

## Number of instances used for each level
@export var instances_per_level: int = Constants.RETRAINING_INSTANCES_PER_LEVEL
## List of levels used in curriculum
@export var levels_path: Array[PackedScene]

const level_manager_scene: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: float = Constants.LEVELS_RETRAINING_OFFSET
const level_batch_offset: float = Constants.LEVELS_BATCH_OFFSET

@onready var sync = $Sync

## Called when the node enters the scene tree for the first time
func _ready():
	spawn_level_managers()

## Spawns all the level managers
func spawn_level_managers() -> void:
	
	# divide levels_path into two groups
	var first_row_levels = levels_path.slice(0, levels_path.size() / 2)
	var second_row_levels = levels_path.slice(levels_path.size() / 2, levels_path.size())
	
	# calculate the number of columns per row 
	var columns_per_row = int(ceil(first_row_levels.size() / 4))

	for k in range(instances_per_level):
		# first row
		for i in range(first_row_levels.size()):
			for j in range(columns_per_row):
				var level_manager_instance = level_manager_scene.instantiate()
				var name = "LevelManager" + str(i) + str(j)
				level_manager_instance.set_name(name)
				level_manager_instance.position.x = i * level_position_offset + k * level_batch_offset * instances_per_level
				level_manager_instance.position.z = j * level_position_offset
				level_managers.append(level_manager_instance)
				add_child(level_manager_instance)
				level_manager_instance.set_level(first_row_levels[i], null)
		
		# second row
		for i in range(second_row_levels.size()):
			for j in range(columns_per_row):
				var level_manager_instance = level_manager_scene.instantiate()
				var name = "LevelManager" + str(i) + str(j + columns_per_row)
				level_manager_instance.set_name(name)
				level_manager_instance.position.x = i * level_position_offset + k * level_batch_offset * instances_per_level
				level_manager_instance.position.z = j * level_position_offset + columns_per_row * level_position_offset
				level_managers.append(level_manager_instance)
				add_child(level_manager_instance)
				level_manager_instance.set_level(second_row_levels[i], null)

## Finish the retraining scene
func finish():
	get_parent().set_current_level()
