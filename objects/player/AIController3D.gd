extends AIController3D

func _ready():
	add_to_group("AGENT")
	
func _physics_process(_delta):
	n_steps += 1
	if n_steps >= reset_after:
		needs_reset = true
		_player.finished = true
	
	#print(n_steps)
	
	if needs_reset:
		reset()

## reset_after parameter setter
func set_reset_after(steps: int):
	reset_after = steps

## Returns dictionary containing the observations made
func get_obs() -> Dictionary:
	var obs := []
	var raycast_obs = _player.raycast_sensor.get_observation()
	var speed_norm = 0 if _player.speed_max == 0 else (_player.speed - _player.speed_min) / (_player.speed_max - _player.speed_min)
	
	obs.append(speed_norm)
	obs.append_array(raycast_obs)
	
	#print(obs)
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
	_player._action_0 = clamp(action["move"][0], -1.0, 1.0)
	_player._action_1 = clamp(action["rotate"][0], -1.0, 1.0)

## Reset ai controller state
func reset():
	n_steps = 0
	needs_reset = false
