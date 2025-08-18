extends Node3D
class_name SpatialRandomizer

@export var randomize_position := true
@export var randomize_rotation := false
@export var offset := 1.5

func randomize_entity_position(entity: Node3D, area: CollisionShape3D):
	var shape = area.shape as BoxShape3D
	var extents = shape.extents
	var random_pos = Vector3(
		randf_range(-extents.x + offset, extents.x - offset),
		0.0,
		randf_range(-extents.z + offset, extents.z - offset)
	)
	entity.global_position = area.global_position + random_pos

func randomize_entity_rotation(entity: Node3D):
	var random_rot = randi_range(0, 359)
	entity.rotation_degrees = Vector3(0.0, random_rot, 0.0)
