extends Node
class_name LevelNode

## Max time steps allowed
@export var max_steps: int = Constants.DEFAULT_MAX_TIMESTEPS

## Set if the pedestrian can move
@export var can_move: bool = true

## Set if the pedestrian spawn with a random rotation
@export var agent_rotate: bool = false  
