extends Node

# Pedestrian
const MAX_SPEED_MEAN: float = 1.5
const MAX_SPEED_DEVIATION: float = 0.2
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

# Group simulation constants
const GROUP_DISTANCE: float = 5.0  # Distance for group detection and maximum allowed distance between members

# Pedestrian controller
const TICKS_BETWEEN_LOG: int = 2

# Rewards
const FINAL_TARGET_REW: float = 6.0
const INTERMEDIATE_TARGET_FIRST_TIME_REW: float = 0.5
const INTERMEDIATE_TARGET_ALREADY_REACHED_REW: float = -1.0
const NO_TARGET_VISIBLE_REW: float = -0.5
const WALL_COLLISION_REW: float = -0.5
const AGENT_COLLISION_SMALL_REW: float = -0.5
const AGENT_COLLISION_MEDIUM_REW: float = -0.005    # -0.0 for high density
const AGENT_COLLISION_LARGE_REW: float = -0.001     # -0.0 for high density
const TIMESTEP_REW: float = -0.0001
const END_OF_TIMESTEPS_REW: float = -6.0

# Group simulation rewards
const FINAL_TARGET_GROUP_REW: float = 2.0 # (was 1.0)
const INTERMEDIATE_TARGET: float = 1.2 # (was 1.0)
const FINAL_TARGET_GROUP_FAR_REW: float = -10.0 # (unchanged)
const TARGET_ALREADY_COLLECTED: float = -2.0 # (unchanged)
const AGENT_COLLISION_GROUP_REW: float = -1.0 # (unchanged)
const WALL_COLLISION_GROUP_REW: float = -1.6 # (unchanged)
const NO_TARGET_VISIBLE_GROUP_REW: float = -1.8 # (was -1.6)
const GROUP_DISTANCE_REW: float = -0.7 # (was -0.5)
const TIMESTEP_GROUP_REW: float = -0.0008 # (was -0.0005)
const END_OF_TIMESTEPS_GROUP_REW: float = -4.0 # (was -2.0)

# AI Controller
const TICKS_PER_STEP: int = 20

# RayCast Sensor
const RAY_LENGTH: float = 35.0
const RAY_LENGTH_OBS: float = 10.0 
const RAY_LENGTH_OBS_GROUP: float = 30.0  # Increased observation distance for group simulation
const MAX_VISION_DEGREES: float = 90.0
const RAYS_ANGLE_DELTA: float = 1.0  # Modified from 1.5 to 1.0 for group simulation
const INITIAL_RAY_POS: float = 0.0
const RAYS_GRAY_COLOR: String = "#787c82"
# For better performance set SHOW_RAYS to remove the computation necessary to 
# draw the rays lines
const SHOW_RAYS: bool = false

# Groups
const TARGETS_GROUP: String = "TARGET"
const WALLS_GROUP: String = "WALL"
const AGENT_GROUP: String = "AGENT"
const PEDESTRIAN_GROUP: String = "PEDESTRIAN"
const PEDESTRIAN_GROUP_1: String = "pedestrian_group_1"  # Collision layer 3
const PEDESTRIAN_GROUP_2: String = "pedestrian_group_2"  # Collision layer 4
const PEDESTRIAN_GROUP_3: String = "pedestrian_group_3"  # Collision layer 7
const PEDESTRIAN_GROUP_4: String = "pedestrian_group_4"  # Collision layer 8

# Levels
const DEFAULT_MAX_TIMESTEPS: int = 500

# Random area 
const SPAWN_OFFSET: float = 0.5
const TARGET_OFFSET: float = 1.5
const ROTATION_STEPS: int = 8

# Training phase
const LEVELS_BATCH_OFFSET: float = 100.0
const LEVELS_RETRAINING_OFFSET: float = 40.0
const RETRAINING_INSTANCES_PER_LEVEL: int = 3
const TRAINING_BATCH_SIZE: int = 10

# Test scene
const DEFAULT_NUMBER_OF_EPISODE: int = 1
const PATH_PEDPY_LOGS = "res://../output/pedpy/"
const TESTING_BATCH_SIZE: int = 1

# Engine/Sync
const PHYSICS_TICKS_PER_SECONDS: int = 60
const TIME_SCALE: float = 1.0
const SPEED_UP: float = 2.0
