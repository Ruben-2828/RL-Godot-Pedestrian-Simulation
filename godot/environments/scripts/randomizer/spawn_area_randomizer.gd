extends SpatialRandomizer
class_name SpawnAreaRandomizer

@export var group_areas: Dictionary = {}

func _ready():
	randomize_spawn()

func randomize_spawn():
	var all_pedestrians = get_tree().get_nodes_in_group(Constants.PEDESTRIAN_GROUP)
	for ped in all_pedestrians:
		var group_id = ped.get_my_group_id() 
		if group_areas.has(group_id):
			var areas = group_areas[group_id]
			var area = areas[randi_range(0, areas.size() - 1)]
			randomize_entity_position(ped, area)
			if randomize_rotation:
				randomize_entity_rotation(ped)

func get_end_episode():
	randomize_spawn()
