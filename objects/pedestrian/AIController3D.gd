extends AIController3D

## Ticks for each step
@export var ticks_per_step: int = Constants.TICKS_PER_STEP
var tick_counter: int = 0

func _ready():
	add_to_group(Constants.AGENT_GROUP)
	
func _physics_process(_delta):
	
	tick_counter += 1
	tick_counter %= Engine.physics_ticks_per_second
	
	if tick_counter % ticks_per_step == 0:
	
		n_steps += 1
		if n_steps >= reset_after:
			needs_reset = true
			_player.finished = true
		
		_player.compute_rewards()
		
		if needs_reset or _player.final_target_reached:
			done = true
			_player.reset()
			reset()

## reset_after parameter setter
func set_reset_after(steps: int):
	reset_after = steps

## Returns dictionary containing the observations made
func get_obs() -> Dictionary:
	var obs := []
	var raycast_obs = _player.raycast_sensor.get_observation()
	var speed_norm = (_player.speed - _player.speed_min) / (_player.speed_max - _player.speed_min) if _player.speed_max != 0 else 0
	
	obs.append(speed_norm)
	obs.append_array(raycast_obs[0])
	obs.append_array(raycast_obs[1])
	
	#print(obs.size())
	return {'obs': obs}

## Returns current reward
func get_reward() -> float:	
	var current_reward = reward
	reward = 0
	return current_reward

## Returns dictionary representing the action space
func get_action_space() -> Dictionary:
	return {
			"rotate" : {"size": 1, "action_type": "continuous" },
			"move" : {"size": 1, "action_type": "continuous" },
			}

## Set player's actions
func set_action(action) -> void:	
	_player.set_direction(clampf(action["rotate"][0], -1.0, 1.0))
	_player.set_speed(clampf(action["move"][0], -1.0, 1.0))

## Reset ai controller state
func reset():
	n_steps = 0
	needs_reset = false
