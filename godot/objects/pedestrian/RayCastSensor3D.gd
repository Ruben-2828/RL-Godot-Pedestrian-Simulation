extends ISensor3D

## Max distance at which a raycast can hit
var ray_length := Constants.RAY_LENGTH:
	get:
		return ray_length
	set(value):
		ray_length = value
		_update()

## Max angle of vision (in deg)
var max_vision_degrees := Constants.MAX_VISION_DEGREES:
	get:
		return max_vision_degrees
	set(value):
		max_vision_degrees = value
		_update()

## Interval between rays	
var rays_angle_delta := Constants.RAYS_ANGLE_DELTA:
	get:
		return rays_angle_delta
	set(value):
		rays_angle_delta = value
		_update()

## Position of initial ray
var initial_ray_pos := Constants.INITIAL_RAY_POS:
	get:
		return initial_ray_pos
	set(value):
		initial_ray_pos = value
		_update()

## If true rays will collide with Area3D, if false it wont
var collide_with_areas := true:
	get:
		return collide_with_areas
	set(value):
		collide_with_areas = value
		_update()

## If true rays will collide with bodies, if false it wont
var collide_with_bodies := true:
	get:
		return collide_with_bodies
	set(value):
		collide_with_bodies = value
		_update()
		
@onready var pedestrian = $".."
var lines_walls_targets: Array[MeshInstance3D] = []
var lines_agents_walls: Array[MeshInstance3D] = []

var rays_walls_targets := []
var rays_agents_walls := []

func _update() -> void:
	_spawn_nodes()

func _ready() -> void:
	_spawn_nodes()

func _process(_delta):
	if not pedestrian.disable and Constants.SHOW_RAYS:
		_create_debug_lines()
	
func _create_debug_lines(): 
		
	for i in range(rays_agents_walls.size()):
		if rays_walls_targets[i].is_colliding():
			var point = rays_walls_targets[i].get_collision_point() - global_position
			
			var material = ORMMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			if rays_walls_targets[i].get_collider().is_in_group(Constants.TARGETS_GROUP):
				if rays_walls_targets[i].get_collider().name.begins_with("FinalTarget"):
					material.albedo_color = "#43A047"
				else:
					material.albedo_color = "#26C6DA"
			else:
				material.albedo_color = "#232323"
				
			var immediate_mesh = ImmediateMesh.new()
			immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
			immediate_mesh.surface_add_vertex(position)
			immediate_mesh.surface_add_vertex(point)
			immediate_mesh.surface_end()
				
			lines_walls_targets[i].mesh = immediate_mesh
			lines_walls_targets[i].global_rotation = Vector3.ZERO
				
		if rays_agents_walls[i].is_colliding():
			if rays_agents_walls[i].get_collider().is_in_group(Constants.PEDESTRIAN_GROUP):
				var point = rays_agents_walls[i].get_collision_point() - global_position
				
				var material = ORMMaterial3D.new()
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				material.albedo_color = "#FDD835"
				
				var immediate_mesh = ImmediateMesh.new()
				immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
				immediate_mesh.surface_add_vertex(position + Vector3(0, 1, 0))
				immediate_mesh.surface_add_vertex(point + Vector3(0, 1, 0))
				immediate_mesh.surface_end()
				
				lines_agents_walls[i].mesh = immediate_mesh
				lines_agents_walls[i].global_rotation = Vector3.ZERO
			else:
				lines_agents_walls[i].mesh = null
				
## Spawns all raycast nodes
func _spawn_nodes():
	#print("spawning nodes")
	for ray in get_children():
		ray.queue_free()
	rays_walls_targets = []
	rays_agents_walls = []

	# Spawn two types of raycasts: one for walls and targets and one for agents and walls
	var angle = initial_ray_pos
	var i = 0
	while angle < max_vision_degrees:
		_create_ray(angle, i, true)
		_create_ray(angle, i, false)
		if angle != 0:
			_create_ray(-angle, -i, true)
			_create_ray(-angle, -i, false)
		
		i += 1
		angle = angle + rays_angle_delta * i
		
	# Need to create rays at max_vision_degrees angle too
	_create_ray(max_vision_degrees, i,  true)
	_create_ray(-max_vision_degrees, -i,  true)
	_create_ray(max_vision_degrees, i, false)
	_create_ray(-max_vision_degrees, -i, false)
	
	for r in rays_walls_targets:	
		var line = MeshInstance3D.new()
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lines_walls_targets.append(line)
		add_child(line)
		
	for r in rays_agents_walls:	
		var line = MeshInstance3D.new()
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lines_agents_walls.append(line)
		add_child(line)

## Create raycast node
## Mode = true for walls and targets, false for agents and walls
func _create_ray(angle: float, idx: int, mode: bool):
	var ray = RayCast3D.new()
	var cast_to = to_spherical_coords(ray_length, angle, 0)
	ray.set_target_position(cast_to)
	
	if mode:
		ray.set_name("wall_target ray " + str(idx))
		ray.show()
		var collision_mask = pedestrian.collision_mask
		# Remove second bit to deactivate pedestrian detection
		collision_mask -= 2
		ray.collision_mask = collision_mask
	else:
		ray.set_name("agent_wall ray " + str(idx))
		ray.hide()
		# first two layers for walls and agents
		# first two bit equals 1 ==> collision mask = 3
		ray.collision_mask = 3
	ray.enabled = true
	ray.collide_with_bodies = collide_with_bodies
	ray.collide_with_areas = collide_with_areas
	ray.debug_shape_custom_color = Constants.RAYS_GRAY_COLOR
	ray.exclude_parent = true
	ray.hit_from_inside = false
	
	add_child(ray)
	if mode:
		rays_walls_targets.append(ray)
	else:
		rays_agents_walls.append(ray)
	

func to_spherical_coords(r, inc, azimuth) -> Vector3:
	return Vector3(
		r * sin(deg_to_rad(inc)) * cos(deg_to_rad(azimuth)),
		r * sin(deg_to_rad(azimuth)),
		r * cos(deg_to_rad(inc)) * cos(deg_to_rad(azimuth))
	)

## Returns raycast sensor observations
func get_observation() -> Array:
	return self.calculate_raycasts()

## Returns a list of all hit objects and their distance
func calculate_raycasts() -> Array:
	return [calculate_walls_targets(), calculate_agents_walls()]
	
func calculate_walls_targets() -> Array:
	var hit_objects := []
	
	# Walls and targets observations
	for ray in rays_walls_targets:
		var norm_distance = _get_raycast_distance(ray)
		hit_objects.append(norm_distance)
		
		# hit object type is a one hot encoding
		# 1,0,0: wall; 0,1,0: new target; 0,0,1: already visited target
		var hit_object_type := [0, 0, 0]
		if ray.get_collider():
			if ray.get_collider().is_in_group(Constants.TARGETS_GROUP):
				if ray.get_collider() in pedestrian.reached_targets:
					hit_object_type[2] = 1
				else:
					hit_object_type[1] = 1
				
			elif ray.get_collider().is_in_group(Constants.WALLS_GROUP):
				hit_object_type[0] = 1

		hit_objects.append_array(hit_object_type)
		
	return hit_objects
	
func calculate_agents_walls() -> Array:
	var hit_objects := []
	
	# Agents and walls observations
	for ray in rays_agents_walls:
		var norm_distance = _get_raycast_distance(ray)
		var type: int = 0
		var direction: float = 0.0
		var speed: float = 0.0
		
		var collider = ray.get_collider()
		if collider:
			if collider.is_in_group(Constants.PEDESTRIAN_GROUP):
				type = 1
				var diffAng = clamp0360(
					clamp0360(rad_to_deg(collider.rotation.y)) - clamp0360(rad_to_deg(rotation.y))
					)
				direction = clamp((diffAng / 180) - 1, -1, 1)
				speed = collider.get_speed_norm()
		
		hit_objects.append(norm_distance)	
		hit_objects.append(type)
		hit_objects.append(direction)
		hit_objects.append(speed)
	
	return hit_objects
	
func clamp0360(eulerAngles: int) -> float:
	var result = eulerAngles % 360
	if result < 0: result += 360
	return result;


## Return distance between the start of the ray and the hit object
func _get_raycast_distance(ray: RayCast3D) -> float:
	if !ray.is_colliding():
		return 0.0

	var origin = ray.global_transform.origin
	var collision_point = ray.get_collision_point()
	var distance = origin.distance_to(collision_point)
	if distance > Constants.RAY_LENGTH_OBS:
		return 1
	return  distance / Constants.RAY_LENGTH_OBS
