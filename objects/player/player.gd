extends CharacterBody3D
class_name Player

@export var level_manager: LevelManager

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
var count: int = 0
var final_target_reached: bool = false
var wall_near: bool = false
var finished: bool = false

func _ready():
	reset()
	
	speed = speed_min
	_action_0 = 0.0
	_action_1 = 0.0
	
	ai_controller_3d.init(self)

func reset():
	global_position = level_manager.get_spawn_position(current_level)
	rotation = level_manager.get_spawn_rotation(current_level)
	
func _physics_process(delta):
	
	_set_speed(delta)
	_set_direction(delta)
	
	animation_tree.set("parameters/conditions/idle", velocity == Vector3.ZERO)
	animation_tree.set("parameters/conditions/walk", velocity != Vector3.ZERO)
	
	_compute_rewards()
	
	move_and_slide()

func _set_speed(delta) -> void:
	speed = clamp(_action_0 * speed_max, speed_min, speed_max)
	var move_vec = Vector3(0, 0, 1)
	move_vec = move_vec.rotated(Vector3(0,1,0), rotation.y)
	move_vec *= speed
	set_velocity(move_vec)
	
	#var move_vec = Vector3(_action_0, 0, _action_1)
	#move_vec *= 2.0
	#set_velocity(move_vec)
	
func _set_direction(delta) -> void:
	rotation.y += deg_to_rad(_action_1 * 1.0)
	
func _compute_rewards() -> void:
	var tot_reward: float = 0
	
	if finished:
		# Reward for reaching final target
		if final_target_reached:
			
			tot_reward += 6
			
			print("oh yeah!")
			count += 1
			final_target_reached = false
			
			# TODO: impostare la transizione di scenario tramite delle condizioni globali
			if count > 50:
				count = 0
				next_level = (current_level + 1) % level_manager.levels.size()
				current_level = next_level	
				cumulated_reward = 0
			
			ai_controller_3d.reset()
		else:
			# Reward loss for finishing time steps
			tot_reward -= 6
			print("finiti timesteps")
			
		finished = false
		reset()

	# Reward loss when detecting no targets
	var obs = raycast_sensor.get_observation()
	obs = obs['hit_objects']
	var no_target = true
	for i in range(0, obs.size(), 2):
		if obs[i+1] == 1:
			no_target = false
			#print("i can see it")
	if no_target:
		tot_reward -= 0.5
		#print("no target loss")
	
	# Reward loss when wall is too near to player
	if wall_near:
		wall_near = false
		tot_reward -= 0.5
		#print("wall near loss")
	
	# Reward loss for timestep
	tot_reward -= 0.0001
	
	ai_controller_3d.reward += tot_reward
	cumulated_reward += tot_reward
	level_manager.set_reward_label_text(cumulated_reward, current_level)

func _on_final_target_entered(body):
	
	if body == self:
		#print("target finale")
		finished = true
		final_target_reached = true
		
func _on_target_entered(body):
	
	if body == self:
		#print("target intemedio")
		pass

func _on_arco_1_body_entered(body):
	if body.is_class("StaticBody3D"):
		wall_near = true
