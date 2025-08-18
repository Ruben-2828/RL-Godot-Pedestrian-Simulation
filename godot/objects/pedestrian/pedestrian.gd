extends CharacterBody3D
class_name Pedestrian

## Pedestrian minimum speed
var speed_min: float = Constants.MIN_SPEED
## Pedestrian maximum speed 
var speed_max: float

@onready var raycast_sensor = $RayCastSensor3D
@onready var ai_controller_3d = $AIController3D
@onready var animation_tree = $AnimationTree
@onready var pedestrian_controller = $".."

@onready var proxemic_arc_small = $ProxemicArcSmall
@onready var proxemic_arc_medium = $ProxemicArcMedium
@onready var proxemic_arc_large = $ProxemicArcLarge

var can_move: bool = true
var final_target_reached: bool = false
var target_reached: bool = false
var disable: bool = false
var finished: bool = false

var rotation_sens: int = Constants.ROTATION_SENS
var cumulated_reward: float = 0.0
var speed: float

var reached_targets := []
var last_target_reached: Area3D = null

## Called when the node enters the scene tree for the first time
func _ready():
	speed = speed_min
	ai_controller_3d.init(self)
	add_to_group(Constants.PEDESTRIAN_GROUP)
	
	if not Constants.SHOW_RAYS:
		proxemic_arc_small.hide()
		proxemic_arc_medium.hide()
		proxemic_arc_large.hide()

## Reset the pedestrian state
func reset():
	rotation = pedestrian_controller.get_spawn_rotation(self)
	global_position = pedestrian_controller.get_spawn_position(self)
	velocity = Vector3.ZERO
	
	set_speed_max()
	
	cumulated_reward = 0
	finished = false
	target_reached = false
	final_target_reached = false
	reached_targets = []
	
## Set value of speed_max extracting it from a gaussian distribution
func set_speed_max():
	if can_move:
		var random = RandomNumberGenerator.new()
		random.randomize()
		speed_max = random.randfn(Constants.MAX_SPEED_MEAN, Constants.MAX_SPEED_DEVIATION)
	else:
		speed_max = 0.0
	
# Called every frame
func _physics_process(_delta):
		
	animation_tree.set("parameters/conditions/idle", velocity == Vector3.ZERO)
	animation_tree.set("parameters/conditions/walk", velocity != Vector3.ZERO)
	
	move_and_slide()

## Set pedestrian current speed
func set_speed(action_0) -> void:
	speed = clampf(speed + action_0 * speed_max / 2, speed_min, speed_max)
	var move_vec = Vector3(0, 0, 1)
	move_vec = move_vec.rotated(Vector3(0, 1, 0), rotation.y)
	move_vec *= speed
	set_velocity(move_vec)

## Set pedestrian direction 
func set_direction(action_1) -> void:
	# Modified rotation sensitivity for group simulation (35° instead of 25°)
	rotation.y += deg_to_rad(action_1 * 35)

## Get group observations for the AI controller
func get_group_observations() -> Array:
	"""
	Get observations related to group behavior
	Returns 8 observations: [own_speed, group_near, group_relative_x, group_relative_z, 
							group_speed_x, group_speed_z, group_size, group_avg_distance]
	"""
	var observations = []
	
	# 1. Own speed (normalized)
	observations.append(get_speed_norm())
	
	# 2. Group proximity indicator (boolean as float)
	var group_near = 0.0
	var group_members = get_group_members()
	
	# Check if any group member is within 5 meters (for proximity observation)
	for member in group_members:
		var distance = global_position.distance_to(member.global_position)
		if distance < Constants.GROUP_DISTANCE:
			group_near = 1.0
			break
	
	observations.append(group_near)
	
	# 3-4. Average relative position of group members (X, Z) - ALL group members
	var avg_relative_x = 0.0
	var avg_relative_z = 0.0
	
	if group_members.size() > 0:
		for member in group_members:
			var relative_pos = member.global_position - global_position
			avg_relative_x += relative_pos.x
			avg_relative_z += relative_pos.z
		
		avg_relative_x /= group_members.size()
		avg_relative_z /= group_members.size()
		
		# Normalize to [-1, 1] range (assuming max distance is 10m)
		avg_relative_x = clamp(avg_relative_x / 10.0, -1.0, 1.0)
		avg_relative_z = clamp(avg_relative_z / 10.0, -1.0, 1.0)
	
	observations.append(avg_relative_x)
	observations.append(avg_relative_z)
	
	# 5-6. Average velocity of group members (X, Z)
	var avg_velocity_x = 0.0
	var avg_velocity_z = 0.0
	
	if group_members.size() > 0:
		for member in group_members:
			var velocity = member.velocity
			avg_velocity_x += velocity.x
			avg_velocity_z += velocity.z
		
		avg_velocity_x /= group_members.size()
		avg_velocity_z /= group_members.size()
		
		# Normalize to [-1, 1] range
		avg_velocity_x = clamp(avg_velocity_x / speed_max, -1.0, 1.0)
		avg_velocity_z = clamp(avg_velocity_z / speed_max, -1.0, 1.0)
	
	observations.append(avg_velocity_x)
	observations.append(avg_velocity_z)
	
	# 7. Group size (normalized)
	observations.append(float(group_members.size()) / 4.0)  
	
	# 8. Average distance to group members
	var avg_distance = 0.0
	if group_members.size() > 0:
		for member in group_members:
			avg_distance += global_position.distance_to(member.global_position)
		avg_distance /= group_members.size()
		avg_distance = clamp(avg_distance / Constants.GROUP_DISTANCE, 0.0, 1.0)
	
	observations.append(avg_distance)
	
	return observations

## Get group members
func get_group_members() -> Array:
	"""
	Get all members of the same group
	"""
	var group_members = []
	
	# Determine which group this pedestrian belongs to based on collision layer
	var my_group = get_my_group()
	if my_group == "":
		print("WARNING: Pedestrian ", name, " is not assigned to any specific group!")
		return group_members
	
	# Get all pedestrians in the scene
	var pedestrians = get_tree().get_nodes_in_group(Constants.PEDESTRIAN_GROUP)
	
	for ped in pedestrians:
		if ped != self and not ped.disable:
			# Check if pedestrian is in the same environment (not from another batch)
			var env_bounds = 20.0
			var relative_pos = ped.global_position - global_position
			
			if abs(relative_pos.x) < env_bounds and abs(relative_pos.z) < env_bounds:
				# Check if this pedestrian belongs to the same group
				if ped.get_my_group() == my_group:
					group_members.append(ped)
	return group_members

## Determine which group this pedestrian belongs to based on collision layer
func get_my_group() -> String:
	"""
	Determine which group this pedestrian belongs to based on collision layer
	Returns: "pedestrian_group_1", "pedestrian_group_2", "pedestrian_group_3", "pedestrian_group_4", or "" if not assigned
	"""
	# Layer 3 (bit 2)
	if collision_layer & (1 << 2):
		return Constants.PEDESTRIAN_GROUP_1
	# Layer 4 (bit 3)
	if collision_layer & (1 << 3):
		return Constants.PEDESTRIAN_GROUP_2
	# Layer 7 (bit 6)
	if collision_layer & (1 << 6):
		return Constants.PEDESTRIAN_GROUP_3
	# Layer 8 (bit 7)
	if collision_layer & (1 << 7):
		return Constants.PEDESTRIAN_GROUP_4
	return ""

# Return group id of pedestrian
func get_my_group_id() -> int:
	if collision_layer & (1 << 2):
		return 1
	if collision_layer & (1 << 3):
		return 2
	if collision_layer & (1 << 6):
		return 3
	if collision_layer & (1 << 7):
		return 4
	return 0

## Check if nearby pedestrians are close
func _is_group_close() -> bool:
	# Get group members
	var group_members = get_group_members()
	
	# Check if group member is within 5 meters (for proximity)
	for member in group_members:
		var distance = global_position.distance_to(member.global_position)
		if distance < Constants.GROUP_DISTANCE:
			return true
	
	return false  # No nearby group members

## Get relative coordinates of nearby pedestrians
func _get_group_members_relative_coordinates() -> Array:
	var coords := []
	var max_members = 3 
	
	# Get group members
	var group_members = get_group_members()
	
	# Sort by distance and take the closest ones
	group_members.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	
	# Add coordinates for up to max_members
	for i in range(max_members):
		if i < group_members.size():
			var member = group_members[i]
			var relative_pos = _get_relative_position(member.global_position)
			coords.append(relative_pos.x)
			coords.append(relative_pos.z)
		else:
			# Fill with zeros if no more members
			coords.append(0.0)
			coords.append(0.0)
	
	return coords

## Get relative position of another pedestrian in local coordinates
func _get_relative_position(other_pos: Vector3) -> Vector3:
	# Transform global position to local coordinates
	var local_pos = global_transform.inverse() * other_pos
	# Normalize to [-1, 1] range based on group detection distance
	var normalized_pos = Vector3(
		clamp(local_pos.x / (Constants.GROUP_DISTANCE * 2), -1.0, 1.0),
		0.0,
		clamp(local_pos.z / (Constants.GROUP_DISTANCE * 2), -1.0, 1.0)
	)
	return normalized_pos

## Calculates total reward per time step
func compute_rewards() -> void:
	var tot_reward: float = 0
	
	# Small penalty per timestep
	tot_reward += Constants.TIMESTEP_GROUP_REW
	
	if not finished:
		# Reward/Penalty for intermediate targets
		if target_reached:
			if last_target_reached in reached_targets:
				tot_reward += Constants.TARGET_ALREADY_COLLECTED
			else:
				reached_targets.append(last_target_reached)
				tot_reward += Constants.INTERMEDIATE_TARGET
			target_reached = false
			last_target_reached = null

		# Raycast observations
		var obs = raycast_sensor.get_observation()
		var walls_and_targets = obs[0]
		var agents_and_walls = obs[1]
		
		# Penalty when wall is too close
		var wall_near = false
		for i in range(0, walls_and_targets.size(), 5):
			if walls_and_targets[i+1] == 1 and walls_and_targets[i] < Constants.WALL_COLLISION_DISTANCE / Constants.RAY_LENGTH_OBS_GROUP:
				wall_near = true
				break
		if wall_near:
			tot_reward += Constants.WALL_COLLISION_GROUP_REW
			
		# Penalty when an agent outside the group is too close
		var agent_near = false
		for i in range(0, agents_and_walls.size(), 4):
			if agents_and_walls[i+1] == 1 and agents_and_walls[i] < 1.2 / Constants.RAY_LENGTH_OBS_GROUP:
				agent_near = true
				break
		if agent_near:
			tot_reward += Constants.AGENT_COLLISION_GROUP_REW
		
		# Penalty when no targets are visible
		var no_target = true
		for i in range(0, walls_and_targets.size(), 5):
			if walls_and_targets[i+2] == 1 or walls_and_targets[i+3] == 1 or walls_and_targets[i+4] == 1:
				no_target = false
		if no_target:
			tot_reward += Constants.NO_TARGET_VISIBLE_GROUP_REW
		
		# Penalty when the group is too far away
		if not _is_group_close():
			tot_reward += Constants.GROUP_DISTANCE_REW
			
	cumulated_reward += tot_reward
	ai_controller_3d.reward += tot_reward
	pedestrian_controller.set_reward_label_text(tot_reward)


## Called when the pedestrian enters the final target
func _on_final_target_entered(body):
	if body == self:
		finished = true
		final_target_reached = true
		
		# final target rewards/penalties are applied
		if _is_group_close():
			cumulated_reward += Constants.FINAL_TARGET_GROUP_REW
			ai_controller_3d.reward += Constants.FINAL_TARGET_GROUP_REW
		else:
			cumulated_reward += Constants.FINAL_TARGET_GROUP_FAR_REW
			ai_controller_3d.reward += Constants.FINAL_TARGET_GROUP_FAR_REW

		
## Function executed when the pedestrian enters an intermediate target
func _on_target_entered(area, body):
	
	if body == self:
		target_reached = true
		last_target_reached = area
		
## Disable the objective when the pedestrian enters it
func _on_objective_entered(area, body):
	
	if body == self and area.active:
		area.active = false
		area.monitoring = false
		area.monitorable = false
		area.visible = false
		var collision = area.find_child("CollisionShape3D")
		collision.disabled = true

func get_speed_norm() -> float:
	if speed_max == 0.0:
		return 0.0
		
	return (speed - speed_min) / (speed_max - speed_min)

## Disable pedestrian when enter final target
func disable_pedestrian():
	disable = true
	speed_max = 0.0
	rotation_sens = 0
	global_position.y = 1000


## Enable pedestrian when end episode
func enable_pedestrian():
	disable = false
	rotation_sens = Constants.ROTATION_SENS
