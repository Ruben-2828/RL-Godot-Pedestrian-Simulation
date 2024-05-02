extends Node3D

@onready var objective = $Objective

# list of areas to place the objective
var areas: Array = []

# offset to place the objective within the area
var offset = 1.5

@export_category("Objective Settings")
@export var randomize_position = false

# Called when the node enters the scene tree for the first time.
func _ready():
	areas = find_children("CollisionShapeObjective*")
	set_random_pos()


## perform randomization of objective position
func randomize_pos(area):
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset),
	)
	objective.position += random_pos
	
## handle the randomization
func set_random_pos():
	# randomize which area to place the objective
	var selected_area = areas[randi_range(0, areas.size() -1)]
	objective.global_position = selected_area.global_position
	
	#randomize position inside the selected area
	if randomize_position:
		randomize_pos(selected_area)

# set the object visible
func set_objective():
	objective.active = true
	objective.visible = true
	objective.monitoring = true
	objective.monitorable = true
	var collision = objective.find_child("CollisionShape3D")
	collision.disabled = false
	print("Obiettivo resetatto, area attiva: ", objective.active)

## Called on episode ending to reset objective position
func get_end_episode(_reward):
	set_random_pos()
	set_objective()
