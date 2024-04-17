extends AIController3D

func _ready():
	add_to_group("AGENT")
	
func set_reset_after(steps: int):
	reset_after = steps
	
func _physics_process(_delta):
	n_steps += 1
	if n_steps >= reset_after:
		needs_reset = true
		_player.finished = true
	
	#print(n_steps)
	
	if needs_reset:
		reset()

func get_obs() -> Dictionary:
	var obs := []
	var raycast_obs = _player.raycast_sensor.get_observation()
	var speed_norm = (_player.speed - _player.speed_min) / (_player.speed_max - _player.speed_min)
	
	obs.append(speed_norm)
	obs.append_array(raycast_obs['hit_objects'])
	
	#print(obs)
	return {'obs': obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"rotate" : {
			"size": 1,
			"action_type": "continuous"
		},
		"move" : {
			"size": 1,
			"action_type": "continuous"
		},
	}
	
func set_action(action) -> void:	
	_player._action_0 = clamp(action["move"][0], -1.0, 1.0)
	_player._action_1 = clamp(action["rotate"][0], -1.0, 1.0)

func reset():
	n_steps = 0
	needs_reset = false

#func get_obs_space() -> Dictionary:
# May need overriding if the obs space is complex
	#var obs = get_obs()
	#var obs_space: Dictionary
	#
	#for k in obs:
		#var v = obs[k]
		#var space: Dictionary
		#space['size'] = [v.size(), v[0].size()] if k == 'hit_objects' else [v.size()]
		#space['space'] = 'box'
		#obs_space[k] = space
	#
	##print(obs_space)
	#return obs_space
	
