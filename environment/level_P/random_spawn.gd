extends Node3D

@onready var spawn = $Spawn
 
# list of areas to place the spawn
var areas: Array = []

# offset to position the spawner within the area
var offset = 0.5

@export_category("Spawn Settings")
## randomize the position of the spawn inside the area
@export var randomize_position = false
## randomize the rotation of the spawn
@export var randomize_rotation = false

# Called when the node enters the scene tree for the first time.
func _ready():
	areas = find_children("CollisionShapeSpawn*")
	set_random()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## perform randomization of spawn position
func randomize_pos(area):
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset),
	)
	spawn.position = random_pos

## perform randomization of spawn rotation
func randomize_rot():
	var random_rot = randi_range(-4, 4) * 45
	spawn.rotation_degrees = Vector3(0.0, random_rot, 0)

## handle the randomization
func set_random():
	# randomize which area to place the spawner
	var selected_area = areas[randi_range(0, areas.size() -1)]
	spawn.global_position = selected_area.global_position
	
	# randomize position inside the selected area
	if randomize_position:
		randomize_pos(selected_area)
		
	# randomize rotation
	if randomize_rotation:
		randomize_rot()
		
func get_end_episode(_passed, _reward):
	set_random()	
