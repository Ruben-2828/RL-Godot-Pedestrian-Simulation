extends CharacterBody3D
class_name Player

@onready var level_manager = $".."

var current_level: int
var next_level

var max_level_reached: int = 0

@export var speed_min: float = 0.0
@export var speed_max: float = 1.7
var speed: float
var _action_0: float
var _action_1: float

@onready var raycast_sensor = $RayCastSensor3D
@onready var ai_controller_3d = $AIController3D
@onready var animation_tree = $AnimationTree

var cumulated_reward: float = 0.0
var final_target_reached: bool = false
var target_reached: bool = false
var last_target_reached: Area3D = null
var finished: bool = false

var reached_targets := []

func _ready():
	#reset()
	
	speed = speed_min
	_action_0 = 0.0
	_action_1 = 0.0
	
	ai_controller_3d.init(self)

func reset():
	rotation = level_manager.get_spawn_rotation()
	global_position = level_manager.get_spawn_position()
	
	cumulated_reward = 0
	target_reached = false
	final_target_reached = false
	reached_targets = []
	
func _physics_process(delta):
	
	_set_speed(delta)
	_set_direction(delta)
	
	animation_tree.set("parameters/conditions/idle", velocity == Vector3.ZERO)
	animation_tree.set("parameters/conditions/walk", velocity != Vector3.ZERO)
	
	_compute_rewards()
	level_manager.set_reward_label_text(cumulated_reward)
	
	finish()
	move_and_slide()

func _set_speed(delta) -> void:
	speed = clamp(speed + _action_0 * speed_max / 2, speed_min, speed_max)
	var move_vec = Vector3(0, 0, 1)
	move_vec = move_vec.rotated(Vector3(0,1,0), rotation.y)
	move_vec *= speed
	set_velocity(move_vec)
	
func _set_direction(delta) -> void:
	rotation.y += deg_to_rad(_action_1 * 1.25)

func finish() -> void:
	if finished:
		if final_target_reached:
			ai_controller_3d.reset()
			level_manager._notify_end_episode(true, cumulated_reward)
		else:
			level_manager._notify_end_episode(false, cumulated_reward)
			
		finished = false
		final_target_reached = false
		reset()

func _compute_rewards() -> void:
	var tot_reward: float = 0
	
	# Reward loss for timestep
	tot_reward -= 0.0001
	
	if finished:
		if final_target_reached:
			# Reward for reaching final target
			tot_reward += 6
			#print("oh yeah!")
		else:
			# Reward loss for finishing time steps
			tot_reward -= 6.0
			#print("finiti timesteps")
	else:
		# Reward for reaching an intermediate target
		if target_reached:
			if last_target_reached in reached_targets:
				tot_reward -= 1.0
			else:
				reached_targets.append(last_target_reached)
				tot_reward += 0.5
			target_reached = false
			last_target_reached = null

		# Get observation for proxemity rewards
		var obs = raycast_sensor.get_observation()
		obs = obs['hit_objects']
		
		# Reward loss when wall is too near to player
		var wall_near = false
		for i in range(0, obs.size(), 4):
			if obs[i+1] == 1 and obs[i] < 0.6 / raycast_sensor.ray_length:
				wall_near = true
				break
		if wall_near:
			tot_reward -= 0.5
			#print("wall too near")
		
		## Reward loss when detecting no targets
		##print(obs)
		#var no_target = true
		#for i in range(0, obs.size(), 4):
			#if obs[i+2] == 1 or obs[i+3] == 1:
				#no_target = false
				##print("i can see it")
		#if no_target:
			#tot_reward -= 0.5
			##print("no target loss")
			
	cumulated_reward += tot_reward
	ai_controller_3d.reward += tot_reward

func _on_final_target_entered(body):
	
	if body == self:
		#print("target finale")
		finished = true
		final_target_reached = true
		
func _on_target_entered(area, body):
	
	if body == self:
		#print("target intemedio")
		target_reached = true
		last_target_reached = area
