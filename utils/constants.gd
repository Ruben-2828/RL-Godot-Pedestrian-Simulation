extends Node

# Pedestrian
const MAX_SPEED: float = 1.7
const MIN_SPEED: float = 0.0
const ROTATION_SENS: int = 25
const WALL_COLLISION_DISTANCE: float = 0.6
const AGENT_COLLISION_SMALL_DISTANCE: float = 0.6
const AGENT_COLLISION_MEDIUM_DISTANCE: float = 1.0
const AGENT_COLLISION_LARGE_DISTANCE: float = 1.4
const WALL_COLLISION_RAYS: int = 17
const AGENT_COLLISION_SMALL_RAYS: int = 17
const AGENT_COLLISION_MEDIUM_RAYS: int = 11
const AGENT_COLLISION_LARGE_RAYS: int = 9
const POSITION_DISABLED: Vector3 = Vector3(-1000, -1000, -1000)



# Rewards
const FINAL_TARGET_REW: float = 6.0
const INTERMEDIATE_TARGET_FIRST_TIME_REW: float = 0.5
const INTERMEDIATE_TARGET_ALREADY_REACHED_REW: float = -1.0
const NO_TARGET_VISIBLE_REW: float = -0.5
const WALL_COLLISION_REW: float = -0.5
const AGENT_COLLISION_SMALL_REW: float = -1.0 # changed from 0.5
const AGENT_COLLISION_MEDIUM_REW: float = -0.01 # changed from 0.005
const AGENT_COLLISION_LARGE_REW: float = -0.005 # changed from 0.001
const TIMESTEP_REW: float = -0.0001
const END_OF_TIMESTEPS_REW: float = -6.0

# AI Controller
const TICKS_PER_STEP: int = 20

# RayCast Sensor
const RAY_LENGTH: float = 35.0
const RAY_LENGTH_OBS: float = 10.0 
const MAX_VISION_DEGREES: float = 90.0
const RAYS_ANGLE_DELTA: float = 1.5
const INITIAL_RAY_POS: float = 0.0
const RAYS_GRAY_COLOR: String = "#787c82"


# Groups
const TARGETS_GROUP: String = "TARGET"
const WALLS_GROUP: String = "WALL"
const AGENT_GROUP: String = "AGENT"
const PEDESTRIAN_GROUP: String = "PEDESTRIAN"

# Levels
const DEFAULT_MAX_TIMESTEPS: int = 1000

# Random area (spawn, target, objective)
const SPAWN_OFFSET: float = 0.5
const TARGET_OFFSET: float = 1.5
const ROTATION_STEPS: int = 8

# Training phase
const LEVELS_BATCH_OFFSET: float = 100.0
const LEVELS_RETRAINING_OFFSET: float = 30.0
const RETRAINING_INSTANCES_PER_LEVEL: int = 3
const TRAINING_BATCH_SIZE: int = 10

# Test scene
const LEVEL_TIMESTEP: int = 100

# Engine/Sync
const PHYSICS_TICKS_PER_SECONDS: int = 60
const TIME_SCALE: float = 1.0
const SPEED_UP: float = 10.0
