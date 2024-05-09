extends Node3D

@onready var pedestrian = $"../PedestrianController/Pedestrian"


# list of areas to place the spawn
var areas: Array = []

# offset to position the spawner within the area
var offset = Constants.SPAWN_OFFSET

@export_category("Spawn Settings")
## randomize the position of the pedestrian inside the area
@export var randomize_position = true
## randomize the rotation of the spawn
@export var randomize_rotation = true

# Called when the node enters the scene tree for the first time.
func _ready():
	areas = find_children("CollisionShapeSpawn*")
	set_random()


## perform randomization of pedestrian position
func randomize_pos(area):
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset),
	)
	pedestrian.position += random_pos

## perform randomization of pedestrian rotation
func randomize_rot():
	var random_rot = randi_range(0, Constants.ROTATION_STEPS - 1) * (360 / Constants.ROTATION_STEPS)
	pedestrian.rotation_degrees = Vector3(0.0, random_rot, 0)

## handle the randomization
func set_random():
	
	if randomize_position:
		# randomize which area to place the pedestrian
		var selected_area = areas[randi_range(0, areas.size() -1)]
		pedestrian.global_position = selected_area.global_position
		# randomize position inside the selected area
		randomize_pos(selected_area)
		
	# randomize rotation
	if randomize_rotation:
		randomize_rot()
		
## Called on episode ending to reset pedestrian position
func get_end_episode(_reward):
	set_random()
