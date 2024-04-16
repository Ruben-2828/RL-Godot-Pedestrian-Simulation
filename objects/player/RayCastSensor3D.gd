@tool
extends ISensor3D

@export_flags_3d_physics var collision_mask = 1:
	get:
		return collision_mask
	set(value):
		collision_mask = value
		_update()
@export_flags_3d_physics var boolean_class_mask = 1:
	get:
		return boolean_class_mask
	set(value):
		boolean_class_mask = value
		_update()

@export var ray_length := 10.0:
	get:
		return ray_length
	set(value):
		ray_length = value
		_update()
		
@export var max_vision := 90:
	get:
		return max_vision
	set(value):
		max_vision = value
		_update()
		
@export var delta := 1.5:
	get:
		return delta
	set(value):
		delta = value
		_update()
		
@export var alfa_init := 0:
	get:
		return alfa_init
	set(value):
		alfa_init = value
		_update()

@export var collide_with_areas := true:
	get:
		return collide_with_areas
	set(value):
		collide_with_areas = value
		_update()

@export var collide_with_bodies := true:
	get:
		return collide_with_bodies
	set(value):
		collide_with_bodies = value
		_update()
		
@onready var character = $".."

var rays := []

func _update():
		_spawn_nodes()

func _ready() -> void:
		_spawn_nodes()

func _spawn_nodes():
	print("spawning nodes")
	for ray in get_children():
		ray.queue_free()
	rays = []

	var angle = 0
	var i = 0
	while angle < max_vision:
		_create_ray(angle, i)
		if angle != 0:
			_create_ray(-angle, -i)
		
		i += 1
		angle = angle + delta * i
		
	# Need to create rays at max_vision angle too
	_create_ray(max_vision, i)
	_create_ray(-max_vision, -i)


func _create_ray(angle: float, i: int):
	var ray = RayCast3D.new()
	var cast_to = to_spherical_coords(ray_length, angle, 0)
	ray.set_target_position(cast_to)

	ray.set_name("ray " + str(i))
	ray.enabled = true
	ray.collide_with_bodies = collide_with_bodies
	ray.collide_with_areas = collide_with_areas
	ray.collision_mask = collision_mask
	ray.debug_shape_custom_color = "#787c82"
	ray.exclude_parent = true
	ray.hit_from_inside = false
	add_child(ray)
	ray.set_owner(get_tree().edited_scene_root)
	rays.append(ray)
	#ray.force_raycast_update()


func to_spherical_coords(r, inc, azimuth) -> Vector3:
	return Vector3(
		r * sin(deg_to_rad(inc)) * cos(deg_to_rad(azimuth)),
		r * sin(deg_to_rad(azimuth)),
		r * cos(deg_to_rad(inc)) * cos(deg_to_rad(azimuth))
	)


func get_observation() -> Dictionary:
	return self.calculate_raycasts()


func calculate_raycasts() -> Dictionary:
	var hit_objects := []
	for ray in rays:
		#ray.force_raycast_update()
		var object := []
		
		var norm_distance = _get_raycast_distance(ray) / ray_length
		hit_objects.append(norm_distance)

		var hit_object_type := [0, 0, 0]
		if ray.get_collider():
			if ray.get_collider().is_in_group("targets"):
				if ray.get_collider() in character.reached_targets:
					hit_object_type[2] = 1
					#print("hittatto target gia visto")
				else:
					hit_object_type[1] = 1
					#print("hittatto target nuovo")
				
			elif ray.get_collider().is_in_group("walls"):
				hit_object_type[0] = 1
				#print("hittatto wall")

		hit_objects.append_array(hit_object_type)
	#print(hit_objects)
	return {
		"hit_objects": hit_objects
	}


func _get_raycast_distance(ray: RayCast3D) -> float:
	if !ray.is_colliding():
		return 0.0

	var origin = ray.global_transform.origin
	var collision_point = ray.get_collision_point()
	return origin.distance_to(collision_point)
