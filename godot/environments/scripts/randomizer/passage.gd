extends Randomizer

@onready var passage = $Passage

# Override the entity with the specific node
func _ready():
	entity = passage
	offset = 0  # Specific offset for Passage
	areas = find_children("CollisionShapePassage*")
	set_random()
