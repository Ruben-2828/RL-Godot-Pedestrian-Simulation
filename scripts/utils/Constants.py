
# Base project path constants
BASE_PATH: str = "scripts/"
DEFAULT_CONFIG_PATH: str = BASE_PATH + "configs/"
DEFAULT_CURRICULUM_CONFIG_FILE: str = DEFAULT_CONFIG_PATH + "curriculum/curriculum_config.yaml"
DEFAULT_MODEL_CONFIG_FILE: str = DEFAULT_CONFIG_PATH + "base_config.yaml"
DEFAULT_TMP_MODEL_FILE: str = BASE_PATH + "model.tmp.zip"

# Output path constants
OUTPUT_PATH: str = "output/"
DEFAULT_ONNX_EXPORT_PATH: str = "model/model.onnx"
DEFAULT_LOGS_PATH: str = OUTPUT_PATH + "logs/"
DEFAULT_TENSORBOARD_LOGS_PATH: str = OUTPUT_PATH + "runs/"
DEFAULT_TENSORBOARD_LOGS_FILE: str = "PPO"
