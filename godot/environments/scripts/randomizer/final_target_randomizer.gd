extends SpatialRandomizer
class_name FinalTargetRandomizer

@onready var final_target = $FinalTarget
@onready var areas = find_children("CollisionShapeTarget*")

func _ready():
	randomize_final_target()

func randomize_final_target():
	var area = areas[randi_range(0, areas.size() - 1)]
	randomize_entity_position(final_target, area)
	if randomize_rotation:
		randomize_entity_rotation(final_target)

func get_end_episode():
	randomize_final_target()
