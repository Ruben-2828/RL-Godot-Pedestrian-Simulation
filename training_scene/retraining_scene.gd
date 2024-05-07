@tool

extends Node3D

## Number of instances used for each level
@export var instances_per_level: int = Constants.RETRAINING_INSTANCES_PER_LEVEL
## List of levels used in curriculum
@export var levels_path: Array[PackedScene]

const level_manager_scene: PackedScene = preload("res://environment/level_manager.tscn")
var level_managers: Array = []
const level_position_offset: int = Constants.LEVELS_OFFSET

@onready var sync = $Sync

func _ready():
	spawn_level_managers()

## Spawns all the level managers
func spawn_level_managers() -> void:
	
	# Generating three level managers for each level in the curriculum
	for i in range(levels_path.size()):
		for j in range(instances_per_level):
			var level_manager_instance := level_manager_scene.instantiate()
			level_manager_instance.set_name("LevelManager" + str(i) + str(j))
			level_manager_instance.position.x = i * level_position_offset
			level_manager_instance.position.z = j * level_position_offset
			level_managers.append(level_manager_instance)
			add_child(level_manager_instance)
			level_manager_instance.set_current_level(levels_path[i])
