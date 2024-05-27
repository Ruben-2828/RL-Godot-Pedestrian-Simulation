extends Node3D
class_name Randomizer

@export_category("Random Settings")
@export var randomize_position = true
@export var randomize_rotation = false

# Offset to place the entity within the area
var offset = 1.5

# List of areas to place the entity
var areas: Array = []

# Reference to the entity to randomize
@onready var entity

# Called when the node enters the scene tree for the first time.
func _ready():
	areas = find_children("CollisionShape*")
	set_random()

# Perform randomization of entity position
func randomize_pos(area):
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset),
	)
	entity.position += random_pos

# Perform randomization of entity rotation
func randomize_rot():
	var random_rot = randi_range(0, Constants.ROTATION_STEPS - 1) * (360 / Constants.ROTATION_STEPS)
	entity.rotation_degrees = Vector3(0.0, random_rot, 0)

# Handle the randomization
func set_random():
	# Randomize which area to place the entity
	var selected_area = areas[randi_range(0, areas.size() - 1)]
	entity.global_position = selected_area.global_position
	
	# Randomize position inside the selected area
	if randomize_position:
		randomize_pos(selected_area)
		
	# Randomize rotation if applicable
	if randomize_rotation:
		randomize_rot()

# Called on episode ending to reset entity position
func get_end_episode():
	set_random()
