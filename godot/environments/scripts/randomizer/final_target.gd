extends Randomizer

@onready var final_target = $FinalTarget

# Override the entity with the specific node
func _ready():
	entity = final_target
	offset = Constants.TARGET_OFFSET  # Specific offset for FinalTarget
	areas = find_children("CollisionShapeTarget*")
	set_random()
