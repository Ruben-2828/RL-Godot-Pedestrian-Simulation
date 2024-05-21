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
	rotation.y += deg_to_rad(action_1 * rotation_sens)

## Calculates total reward per time step
func compute_rewards() -> void:
	var tot_reward: float = 0
	
	# Reward loss for timestep
	tot_reward += Constants.TIMESTEP_REW
	
	if not finished:
		# Reward for reaching an intermediate target
		if target_reached:
			if last_target_reached in reached_targets:
				tot_reward += Constants.INTERMEDIATE_TARGET_ALREADY_REACHED_REW
				#print("INTERMEDIATE_TARGET_ALREADY_REACHED_REW")
			else:
				reached_targets.append(last_target_reached)
				tot_reward += Constants.INTERMEDIATE_TARGET_FIRST_TIME_REW
				#print("INTERMEDIATE_TARGET_FIRST_TIME_REW")
			target_reached = false
			last_target_reached = null

		# Get observation for proxemity rewards
		var obs = raycast_sensor.get_observation()
		var walls_and_targets = obs[0]
		var agents_and_walls = obs[1]
		
		# Reward loss when wall is too near
		var wall_near = false
		for i in range(0, Constants.WALL_COLLISION_RAYS * 4, 4):
			if walls_and_targets[i+1] == 1 and walls_and_targets[i] < Constants.WALL_COLLISION_DISTANCE / Constants.RAY_LENGTH_OBS:
				wall_near = true
				break
		if wall_near:
			tot_reward += Constants.WALL_COLLISION_REW
			#print("WALL_COLLISION_REW")
			
		# Reward loss when agent is too near
		var agent_near = false
		for i in range(0, Constants.AGENT_COLLISION_SMALL_RAYS * 4, 4):
			if agents_and_walls[i+1] == 1 and agents_and_walls[i] < Constants.AGENT_COLLISION_SMALL_DISTANCE / Constants.RAY_LENGTH_OBS:
				agent_near = true
				break
		#print(agent_near)
		if agent_near:
			tot_reward += Constants.AGENT_COLLISION_SMALL_REW
			#print("AGENT_COLLISION_SMALL_REW")
			
		if not agent_near:
			for i in range(0, Constants.AGENT_COLLISION_MEDIUM_RAYS * 4, 4):
				if agents_and_walls[i+1] == 1 and agents_and_walls[i] < Constants.AGENT_COLLISION_MEDIUM_DISTANCE / Constants.RAY_LENGTH_OBS:
					agent_near = true
					break
			if agent_near:
				tot_reward += Constants.AGENT_COLLISION_MEDIUM_REW
				#print("AGENT_COLLISION_MEDIUM_REW")
				
		if not agent_near:
			for i in range(0, Constants.AGENT_COLLISION_LARGE_RAYS * 4, 4):
				if agents_and_walls[i+1] == 1 and agents_and_walls[i] < Constants.AGENT_COLLISION_LARGE_DISTANCE / Constants.RAY_LENGTH_OBS:
					agent_near = true
					break
			if agent_near:
				tot_reward += Constants.AGENT_COLLISION_LARGE_REW
				#print("AGENT_COLLISION_LARGE_REW")
		
		# Reward loss when detecting no targets
		var no_target = true
		for i in range(0, walls_and_targets.size(), 4):
			if walls_and_targets[i+2] == 1 or walls_and_targets[i+3] == 1:
				no_target = false
		if no_target:
			tot_reward += Constants.NO_TARGET_VISIBLE_REW
			#print("NO_TARGET_VISIBLE_REW")
			
	cumulated_reward += tot_reward
	ai_controller_3d.reward += tot_reward
	pedestrian_controller.set_reward_label_text(tot_reward)

## Function executed when the pedestrian enters the final target
func _on_final_target_entered(body):
	
	if body == self:
		finished = true
		final_target_reached = true
		
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
