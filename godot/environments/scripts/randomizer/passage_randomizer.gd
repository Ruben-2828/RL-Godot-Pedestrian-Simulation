extends SpatialRandomizer
class_name PassageRandomizer

@onready var passage = $Passage
@onready var areas = find_children("CollisionShapePassage*")

func _ready():
	randomize_passage()

func randomize_passage():
	var area = areas[randi_range(0, areas.size() - 1)]
	randomize_entity_position(passage, area)
	if randomize_rotation:
		randomize_entity_rotation(passage)

func get_end_episode():
	randomize_passage()
