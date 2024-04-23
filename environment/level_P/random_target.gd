extends Node3D

@onready var final_target = $FinalTarget

# list of areas to place the target
var areas: Array = []

# offset to place the target within the area
var offset = 1.5

@export_category("Target Settings")
@export var randomize_position = false

# Called when the node enters the scene tree for the first time.
func _ready():
	areas = find_children("CollisionShapeTarget*")
	set_random_pos()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## perform randomization of target position
func randomize_pos(area):
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset),
	)
	final_target.position += random_pos
	
## handle the randomization
func set_random_pos():
	# randomize which area to place the target
	var selected_area = areas[randi_range(0, areas.size() -1)]
	final_target.global_position = selected_area.global_position
	
	#randomize position inside the selected area
	if randomize_position:
		randomize_pos(selected_area)

## set the target to a new position when the agent reach the final target
func _on_final_target_body_entered(body):
	if body.is_class("CharacterBody3D"):
		set_random_pos()

func get_end_episode(_passed, _reward):
	set_random_pos()
