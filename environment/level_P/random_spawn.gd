extends Area3D

@onready var spawn = $Spawn
@onready var area = $Area

var offset = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize_position()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func randomize_position():
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset),
	)
	spawn.transform.origin = random_pos
	
	var random_rot = randi_range(-4, 4) * 45
	spawn.rotation_degrees = Vector3(0.0, random_rot, 0)

func _on_final_target_body_entered(body):
	if body.is_class("CharacterBody3D"):
		randomize_position()
