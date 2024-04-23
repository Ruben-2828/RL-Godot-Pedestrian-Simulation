extends Node
class_name LevelNode

## Reward to reach every episode
@export var min_reward: float = 0

## Max time steps allowed
@export var max_steps: int = 10000

## Number of times to succeed before stepping to next level
@export var success: int = 30

## Set if the agent can move
@export var can_move: bool = true 
