@tool

extends Node3D
class_name LevelManager

@export_category("Curriculum")
@export var player: Player
@export_group("scenes")
@export var levels_path: Array[PackedScene]


var level_start_area: Array
var level_goal: Array
var levels: Array[Node3D]

func _ready():
	var pos_count = 0 
	for l in levels_path:
		var level = l.instantiate()
		level.position = Vector3(pos_count * 50, 0, 0)
		add_child(level)
		levels.append(level)
		pos_count += 1
	
	level_start_area.resize(levels.size())
	level_goal.resize(levels.size())

	for level_id in range(0, levels.size()):
		var spawn = levels[level_id].find_child("Spawn")
		level_start_area[level_id] = spawn
		
		var final_target = levels[level_id].find_child("FinalTarget")
		final_target.body_entered.connect(player._on_final_target_entered)
		level_goal[level_id] = final_target
		
		var targets := []
		targets.append_array(levels[level_id].find_children("Target*", "Area3D"))
		targets.append_array(levels[level_id].find_children("ObliqueTarget*", "Area3D"))
		print(targets)
		for t in targets:
			t.custom_body_entered.connect(player._on_target_entered)

#func randomize_goal(level_id: int):
	#var active_goal_id = randi_range(0, level_goal[level_id].size() - 1)
	#for goal_id in range(0, level_goal[level_id].size()):
		#var goal = level_goal[level_id][goal_id]
		#if goal_id == active_goal_id:
			#goal.visible = true
			#goal.process_mode = Node.PROCESS_MODE_INHERIT
		#else:
			#goal.visible = false
			#goal.process_mode = Node.PROCESS_MODE_DISABLED
	#return level_goal[level_id][active_goal_id].global_transform

func get_spawn_position(level: int) -> Vector3:
	var area = level_start_area[level]
	#TODO: randomize the spawn position inside a Area 
	return area.global_position
	
func get_spawn_rotation(level: int) -> Vector3:
	var area = level_start_area[level]
	return area.rotation
	
func set_reward_label_text(reward: float, level: int) -> void:
	var label = levels[level].find_child('Label3D')
	label.set_text('reward: ' + str(reward))
