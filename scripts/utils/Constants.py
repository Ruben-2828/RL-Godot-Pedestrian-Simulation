
# Base project path constants
BASE_PATH: str = "scripts/"
DEFAULT_CONFIG_PATH: str = BASE_PATH + "configs/"
DEFAULT_CONFIG_FILE: str = DEFAULT_CONFIG_PATH + "config.yaml"
DEFAULT_TMP_MODEL_FILE: str = BASE_PATH + "model.tmp.zip"

# Output path constants
OUTPUT_PATH: str = "output/"
DEFAULT_ONNX_EXPORT_PATH: str = OUTPUT_PATH + "models/model.onnx"
DEFAULT_LOGS_PATH: str = OUTPUT_PATH + "logs/"
DEFAULT_TENSORBOARD_LOGS_PATH: str = OUTPUT_PATH + "tensorboard/run/"

# Default timesteps to train the model for
DEFAULT_TIMESTEPS: int = 1_000_000_000
DEFAULT_RETRAINING_TIMESTEPS: int = 200_000

# True to show godot env window, False to hide window
SHOW_WINDOW: bool = True
