extends Node
class_name LevelNode

## Reward to reach every episode
@export var min_reward: float = Constants.DEFAULT_MIN_REWARD

## Max time steps allowed
@export var max_steps: int = Constants.DEFAULT_MAX_TIMESTEPS

## Number of times to succeed before stepping to next level
@export var success: int = Constants.DEFAULT_SUCCESS

## Set if the agent can move
@export var can_move: bool = true
